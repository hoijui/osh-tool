# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import os
import options
import sequtils
import strformat
import strutils
import std/json
import std/jsonutils
import std/logging
import system/io
import tables
import ./config
import ./check
import ./checks
import ./state

include ./version

type
  CheckFmt = ref object of RootObj
    repStream: File
    repStreamErr: File
  MdListCheckFmt = ref object of CheckFmt
  MdTableCheckFmt = ref object of CheckFmt
  JsonCheckFmt = ref object of CheckFmt
    checks: seq[tuple[
      name: string,
      passed: bool,
      state: string,
      issues: seq[tuple[
        importance: string,
        msg: string
      ]]
    ]]

method init(self: CheckFmt) {.base.} =
  quit "to override!"

method init(self: MdListCheckFmt) =
  discard

method init(self: MdTableCheckFmt) =
  let strm = self.repStream
  strm.writeLine(fmt"| Passed | Check | Message |")
  # NOTE In some renderers, number of dashes are used to determine relative column width
  strm.writeLine(fmt"| - | --- | ----- |")

method init(self: JsonCheckFmt) =
  discard

proc getStream(self: CheckFmt, res: CheckResult): File =
# method getStream(self: CheckFmt, res: CheckResult): File {.base.} =
  if isGood(res):
    self.repStream
  else:
    self.repStreamErr

proc msgFmt(msg: Option[string]): string =
  return (if msg.isSome:
      fmt(" - {msg.get()}").replace("\n", "\n    ")
    else:
      ""
  )

method report(self: CheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) {.base, locks: "unknown".} =
  quit "to override!"

method report(self: MdListCheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) =
  let strm = self.getStream(res)
  let passed = isGood(res)
  let passedStr = if passed: "x" else: " "
  let msg = res.issues
    .map(proc (issue: CheckIssue): string =
      let importanceStr = fmt"{issue.importance}"
      fmt("\n  - {importanceStr.toUpper()}{msgFmt(issue.msg)}")
    )
    .join("")
  strm.writeLine(fmt"- [{passedStr}] {check.name()}{msg}")

method report(self: MdTableCheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) {.locks: "unknown".} =
  let strm = self.getStream(res)
  let passed = isGood(res)
  let passedStr = if passed: "x" else: " "
  let msg = res.issues
    .map(proc (issue: CheckIssue): string =
      fmt"__{issue.importance}__{msgFmt(issue.msg)}"
    )
    .join("<br><hline/><br>")
    .replace("\n", " <br>&nbsp;")
  strm.writeLine(fmt"| [{passedStr}] | {check.name()} | {msg} |")

method report(self: JsonCheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) {.locks: "unknown".} =
  let passed = isGood(res)
  var issues = newSeq[tuple[importance: string, msg: string]]()
  for issue in res.issues:
    issues.add((
      importance: $issue.importance,
      msg: issue.msg.get().replace("\n", "\\n"),
      ))
  self.checks.add((
    name: check.name(),
    passed: passed,
    state: $res.kind,
    issues: issues,
    ))

method finalize(self: CheckFmt, stats: ReportStats)  {.base, locks: "unknown".} =
  self.repStream.close()
  # NOTE This is not required,
  # because stderr does not need to be closed,
  # and if it is a file, it is the same like repStream,
  # which was already closed in the line above
  #repStreamErr.close()

method finalize(self: MdListCheckFmt, stats: ReportStats) {.locks: "unknown".} =
  let strm = self.repStream
  strm.writeLine("")
  strm.writeLine("## Project Statistics")
  strm.writeLine("")
  strm.writeLine(fmt"* Checks:")
  strm.writeLine(fmt"  * Run: {stats.checks.run}")
  strm.writeLine(fmt"  * Skipped: {stats.checks.skipped}")
  strm.writeLine(fmt"  * Passed: {stats.checks.passed}")
  strm.writeLine(fmt"  * Failed: {stats.checks.failed}")
  strm.writeLine(fmt"  * Available: {stats.checks.available}")
  strm.writeLine(fmt"* Issues:")
  for imp in stats.issues.keys:
    strm.writeLine(fmt"  * {imp}: {stats.issues[imp]}")
  strm.writeLine(fmt"* Openness: {stats.openness}")
  # See NOTE in CheckFmt.finalize
  self.repStream.close()

method finalize(self: MdTableCheckFmt, stats: ReportStats) {.locks: "unknown".} =
  let strm = self.repStream
  strm.writeLine("")
  strm.writeLine("## Project Statistics")
  strm.writeLine("")
  strm.writeLine("| Property | Value |")
  # NOTE In some renderers, number of dashes are used to determine relative column width
  strm.writeLine("| --- | -- |")
  strm.writeLine(fmt"| Checks Run | {stats.checks.run} |")
  strm.writeLine(fmt"| Checks Skipped | {stats.checks.skipped} |")
  strm.writeLine(fmt"| Checks Passed | {stats.checks.passed} |")
  strm.writeLine(fmt"| Checks Failed | {stats.checks.failed} |")
  strm.writeLine(fmt"| Checks Available | {stats.checks.available} |")
  for imp in stats.issues.keys:
    strm.writeLine(fmt"| Issues {imp} | {stats.issues[imp]} |")
  strm.writeLine(fmt"| Openness | {stats.openness} |")
  # See NOTE in CheckFmt.finalize
  self.repStream.close()

method finalize(self: JsonCheckFmt, stats: ReportStats) {.locks: "unknown".} =
  let strm = self.repStream
  strm.writeLine((checks: self.checks, stats: stats).toJson)
  self.repStream.close()

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
    of OutputFormat.Json:
      return JsonCheckFmt(repStream: repStream, repStreamErr: repStreamErr)
    of OutputFormat.MdTable:
      return MdTableCheckFmt(repStream: repStream, repStreamErr: repStreamErr)
    of OutputFormat.MdList:
      return MdListCheckFmt(repStream: repStream, repStreamErr: repStreamErr)

proc calcOpenness*(res: CheckResult): float32 =
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
      error "Programmer error: Code should never try to calculate openness of an 'Inapplicable' check!"
      raise newException(Defect, "Code should never try to calculate openness of an 'Inapplicable' check!")
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

proc check*(registry: ChecksRegistry, state: var State) =
  var reports = newSeq[CheckFmt]()
  for report in state.config.reportTargets:
    reports.add(initCheckFmt(report, state))
  let numChecks = len(registry.checks)
  # Disregarding skipped checks
  var idx = 0
  # including skipped checks
  var idxAll = 0
  var passedChecks = 0
  var issues = initTable[string, int]()
  for imp in CheckIssueImportance:
    issues[$imp] = 0
  var opennessSum = 0.0
  for checkFmt in reports:
    checkFmt.init()
  for check in registry.checks:
    let res = check.run(state)
    if isGood(res):
      passedChecks += 1
    for issue in res.issues:
      issues[$issue.importance] += 1
    if not isApplicable(res):
      debug fmt"Skip reporting check '{check.name()}', because it is inapplicable to this project (in its current state)"
      idxAll += 1
      continue
    for checkFmt in reports:
      checkFmt.report(check, res, idx, idxAll, numChecks)
    opennessSum += calcOpenness(res)
    idx += 1
    idxAll += 1
  let openness = opennessSum / float32(idx)
  let stats = ReportStats(
    checks: (
      run: idx,
      skipped: idxAll - idx,
      passed: passedChecks,
      failed: idx - passedChecks,
      available: numChecks
      ),
    issues: issues,
    openness: openness
    )
  for checkFmt in reports:
    checkFmt.finalize(stats)
