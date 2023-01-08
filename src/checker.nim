# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import os
import options
import strformat
import strutils
import logging
import system/io
import tables
import ./config
import ./check
import ./checks
import ./state
import ./tools
import ./reporters/api
import ./reporters/csv
import ./reporters/md_list
import ./reporters/md_table
import ./reporters/json

include ./constants
include ./version

proc initStreams(report: Report, state: State): (File, File) =
  return
    if report.path.isSome():
      let reportFileName = report.path.get()
      if not state.config.force and fileExists(reportFileName):
        error fmt"Report file '{reportFileName}' exists, and --force was not specified; aborting."
        quit 1
      let file = io.open(reportFileName, fmWrite)
      (file, file)
    else:
      (stdout, stderr)

proc initCheckFmt(report: Report, state: State): CheckFmt =
  let (repStream, repStreamErr) = initStreams(report, state)
  case report.outputFormat:
    of OutputFormat.Csv:
      return CsvCheckFmt(repStream: repStream, repStreamErr: repStreamErr)
    of OutputFormat.Json:
      return JsonCheckFmt(repStream: repStream, repStreamErr: repStreamErr)
    of OutputFormat.MdTable:
      return MdTableCheckFmt(repStream: repStream, repStreamErr: repStreamErr)
    of OutputFormat.MdList:
      return MdListCheckFmt(repStream: repStream, repStreamErr: repStreamErr)

# Calculates the success factor of executing a check,
# Explained here (among other things):
# https://gitlab.com/OSEGermany/osh-tool/-/issues/27
proc calcSuccess*(res: CheckResult): float32 =
  let oKind = case res.kind:
    of Perfect:
      0.5
    of Ok:
      0.4
    of Acceptable:
      0.3
    of Bad:
      0.0
    of Inapplicable:
      error "Programmer error: Code should never try to calculate the success factor of an 'Inapplicable' check!"
      raise newException(Defect, "Code should never try to calculate the success factor of an 'Inapplicable' check!")
  var oIssues = 0.5
  for issue in res.issues:
    let severity = case issue.importance:
      of Light:
        0.02
      of Middle:
        0.05
      of Severe:
        0.1
      of DeveloperFailure:
        0.0
    oIssues -= severity
    if oIssues <= 0.0:
      oIssues = 0.0
      break
  return oKind + oIssues

proc list*(registry: ChecksRegistry) =
  echo(fmt"# Checks")
  echo(fmt"")
  echo(fmt"| Name | Description |")
  echo(fmt"| --- | --------- |")
  for check in registry.checks:
    let singleLineDesc = check.description().replace("\\\n", "").replace("\n", " ")
    echo(fmt"| {check.name()} | {singleLineDesc} |")

proc check*(registry: ChecksRegistry, state: var State) =
  var reports = newSeq[CheckFmt]()
  for report in state.config.reportTargets:
    reports.add(initCheckFmt(report, state))
  let numChecks = len(registry.checks)
  let tool_versions = (
      osh: VERSION,
      okh: toolVersion("okh-tool", "--version", "--quiet"),
      reuse: toolVersion("reuse", "--version"),
      projvar: toolVersion("projvar", "--version", "--quiet"),
      mle: toolVersion("mle", "--version", "--quiet"),
      osh_dir_std: toolVersion("osh-dir-std", "--version", "--quiet"),
  )
  let prelude = ReportPrelude(
    homepage: OSH_TOOL_REPO,
    projVars: state.projVars,
    tool_versions: tool_versions
    )
  for checkFmt in reports:
    checkFmt.init(prelude)
  # Disregarding skipped checks
  var idx = 0
  # including skipped checks
  var idxAll = 0
  var passedChecks = 0
  var issues = initTable[string, int]()
  for imp in CheckIssueImportance:
    issues[$imp] = 0
  var successSum = 0.0
  var checkRelevancySum = CheckRelevancy()
  var checkRelevancySumWeighted = CheckRelevancy()
  var checkRatingSum = CheckRelevancy()
  for check in registry.checks:
    let res = check.run(state)
    if isGood(res):
      passedChecks += 1
    for issue in res.issues:
      issues[$issue.importance] += 1
    if not isApplicable(res):
      let reason = if res.issues.len() > 0 and res.issues[0].msg.isSome(): fmt" because: {res.issues[0].msg.get()}" else: ""
      debug fmt"Skip reporting check '{check.name()}', because it is inapplicable to this project (in its current state){reason}"
      idxAll += 1
      continue
    for checkFmt in reports:
      checkFmt.report(check, res, idx, idxAll, numChecks)
    let success = calcSuccess(res)
    let checkRatingFactors = check.getRatingFactors()
    checkRelevancySum += checkRatingFactors
    checkRelevancySumWeighted += checkRatingFactors * checkRatingFactors.weight
    checkRatingSum += checkRatingFactors * (checkRatingFactors.weight * success)
    successSum += success
    idx += 1
    idxAll += 1
  checkRatingSum /= checkRelevancySumWeighted
  let stats = ReportStats(
    checks: (
      run: idx,
      skipped: idxAll - idx,
      passed: passedChecks,
      failed: idx - passedChecks,
      available: numChecks
      ),
    issues: issues,
    ratings: checkRatingSum.intoRatings()
    )
  for checkFmt in reports:
    checkFmt.finalize(stats)
