# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import os
import options
import strformat
import strutils
import logging
import tables
import ./config_common
import ./config_cmd_check
import ./check
import ./checks_registry
import ./state
import ./util/leightweight
import ./util/run
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
      let file = open(reportFileName, fmWrite)
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

proc list*(registry: var ChecksRegistry) =
  echo(fmt"# Checks")
  echo(fmt"")
  echo(fmt"| IDs | Name | Weight | Openness | Hardware | Quality | Machine-Readability | Description | Why | Source Code |")
  echo(fmt"| --- | ----- | --- | --- | --- | --- | --- | ----------- | ----------- | ------ |")
  for id, config in registry.getAllChecksDefaultConfig():
    var check = registry.getCheck(config)
    let singleLineDesc = check.description().replace("\\\n", "<br/>").replace("\n", "<br/>").replace("|", "\\|")
    let singleLineWhy = check.why().replace("\\\n", "<br/>").replace("\n", "<br/>").replace("|", "\\|")
    let checkSign = check.getSignificanceFactors()
    let srcCodePath = check.sourcePath()
    let srcText = fmt"[`{srcCodePath}`]({OSH_TOOL_SRC_FILES_BASE_URL}/src/checks/{srcCodePath})"
    echo(fmt"| {id} | {check.name()} | {round(checkSign.weight)} | {round(checkSign.openness)} | {round(checkSign.hardware)} | {round(checkSign.quality)} | {round(checkSign.machineReadability)} | {singleLineDesc} | {singleLineWhy} | {srcText} |")

proc check*(registry: var ChecksRegistry, state: var State) =
  var reports = newSeq[CheckFmt]()
  for report in state.config.reportTargets:
    reports.add(initCheckFmt(report, state))
  let tool_versions = (
      osh: VERSION,
      okh: toolVersion("okh-tool", "--version", "--quiet"),
      reuse: toolVersion("reuse", "--version"),
      projvar: toolVersion("projvar", "--version", "--quiet"),
      mlc: toolVersion("mlc", "--version", "--quiet"),
      mle: toolVersion("mle", "--version", "--quiet"),
      osh_dir_std: toolVersion("osh-dir-std", "--version", "--quiet"),
  )
  let prelude = ReportPrelude(
    config: state.configOpt.toJson(),
    homepage: OSH_TOOL_REPO,
    projVars: state.config.projVars,
    tool_versions: tool_versions,
    )
  for checkFmt in reports:
    checkFmt.init(prelude)
  # Disregarding skipped checks
  var idx = 0
  # including skipped checks
  var idxAll = 0
  var passedChecks = 0
  var customCompliance = (passed: 0, failed: 0, notConfigured: 0)
  var issues = initTable[string, int]()
  for imp in CheckIssueSeverity:
    issues[$imp] = 0
  var complianceSum = 0.0
  var weightsSum = 0.0
  var weightedComplianceSum = 0.0
  var maxScoreSum = CheckSignificance()
  var scoreSum = CheckSignificance()
  let checksConfigs = state.config.checks
  let allChecks = registry.getChecks(checksConfigs)
  let numChecks = len(allChecks)
  for primaryId, check in allChecks:
    let res = check.run(state)
    if isGood(res):
      passedChecks += 1
    for issue in res.issues:
      issues[$issue.severity] += 1
    if not isApplicable(res):
      let reason = if res.issues.len() > 0 and res.issues[0].msg.isSome(): fmt" because: {res.issues[0].msg.get()}" else: ""
      debug fmt"Skip reporting check '{check.name()}', because it is inapplicable to this project (in its current state){reason}"
      idxAll += 1
      continue
    let compliance = res.calcCompliance()
    let customPassed = res.isCustomPassed()
    if customPassed.isSome():
      let passed = customPassed.get()
      if passed:
        customCompliance.passed += 1
      else:
        customCompliance.failed += 1
    else:
      customCompliance.notConfigured += 1
    for checkFmt in reports:
      checkFmt.report(check, res, idx, idxAll, numChecks)
    let checkSigFacs = check.getSignificanceFactors()
    # Scales all sub-ratings (openness, quality, ...) by the weight
    var weightedFactors = checkSigFacs * checkSigFacs.weight
    # ... except the weight itsself
    weightedFactors.weight = checkSigFacs.weight
    # Tracks the maximum achievable sum value of all sub-ratings,
    # if all checks would pass with 100% compliance
    maxScoreSum += weightedFactors
    # Tracks the actually achieved sum of compliance of all sub-ratings.
    scoreSum += weightedFactors * compliance
    complianceSum += compliance
    weightsSum += checkSigFacs.weight
    weightedComplianceSum += compliance * checkSigFacs.weight
    idx += 1
    idxAll += 1
  # Divides the actually achieved compliance rates of al lsub-ratings
  # by the maximum achievable value of each.
  # -> percentage
  let score = scoreSum / maxScoreSum
  let stats = ReportStats(
    checks: (
      run: idx,
      skipped: idxAll - idx,
      passed: passedChecks,
      failed: idx - passedChecks,
      available: numChecks,
      complianceSum: complianceSum,
      weightsSum: weightsSum,
      weightedComplianceSum: weightedComplianceSum,
      customCompliance: customCompliance,
      ),
    issues: issues,
    ratings: score.intoRatings()
    )
  for checkFmt in reports:
    checkFmt.finalize(stats)
