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
import std/logging
import system/io
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
  let strm = self.repStream
  strm.writeLine("{")
  strm.writeLine("""  "checks": """)
  strm.writeLine("  [")

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
  let strm = self.getStream(res)
  strm.writeLine("    {")
  strm.writeLine(fmt"""      "name": "{check.name()}",""")
  let passed = isGood(res)
  strm.writeLine(fmt"""      "passed": "{passed}",""")
  strm.write(fmt"""      "state": "{res.kind}" """)
  let numIssues = len(res.issues)
  if numIssues > 0:
    strm.writeLine("  ,")
    strm.writeLine(fmt"""      "issues": [""")
    var indIssue = 0
    var potComma = ","
    for issue in res.issues:
      strm.writeLine("        {")
      strm.writeLine(fmt"""          "importance": "{issue.importance}",""")
      if issue.msg.isSome:
        strm.writeLine(fmt"""          "msg": "{issue.msg.get().replace("\n", "\\n")}" """)
      indIssue += 1
      if indIssue == numIssues:
        potComma = ""
      strm.writeLine(fmt"        }}{potComma}") # Add comma if not last
    strm.write("      ]")
  strm.writeLine("")

  let potComma = if indexAll + 1 < total: "," else: ""
  strm.writeLine(fmt"    }}{potComma}") # Add comma if not last

method finalize(self: CheckFmt)  {.base, locks: "unknown".} =
  self.repStream.close()
  # NOTE This is not required,
  # because stderr does not need to be closed,
  # and if it is a file, it is the same like repStream,
  # which was already closed in the line above
  #repStreamErr.close()

method finalize(self: JsonCheckFmt) {.locks: "unknown".} =
  let strm = self.repStream
  strm.writeLine("  ],")
  strm.writeLine("}")
  # See NOTE in CheckFmt.finalize
  self.repStream.close()

proc initRepStreams(state: State): (File, File) =
  return
    if state.config.reportTarget.isSome():
      let reportFileName = state.config.reportTarget.get()
      if not state.config.force and fileExists(reportFileName):
        error fmt"Report file '{reportFileName}' exists, and --force was not specified; aborting."
        quit 1
      let file = io.open(reportFileName, fmWrite)
      (file, file)
    else:
      (stdout, stderr)

proc initCheckFmt(state: State, repStream, repStreamErr: File): CheckFmt =
  case state.config.outputFormat:
    of OutputFormat.Json:
      return JsonCheckFmt(repStream: repStream, repStreamErr: repStreamErr)
    of OutputFormat.MdTable:
      return MdTableCheckFmt(repStream: repStream, repStreamErr: repStreamErr)
    of OutputFormat.MdList:
      return MdListCheckFmt(repStream: repStream, repStreamErr: repStreamErr)

proc check*(registry: ChecksRegistry, state: var State) =
  let (repStream, repStreamErr) = initRepStreams(state)
  let checkFmt: CheckFmt = initCheckFmt(state, repStream, repStreamErr)
  let numChecks = len(registry.checks)
  # Disregarding skipped checks
  var idx = 0
  # including skipped checks
  var idxAll = 0
  checkFmt.init()
  for check in registry.checks:
    let res = check.run(state)
    if not isApplicable(res):
      debug fmt"Skip reporting check '{check.name()}', because it is inapplicable to this project (in its current state)"
      idxAll += 1
      continue
    checkFmt.report(check, res, idx, idxAll, numChecks)
    idx += 1
    idxAll += 1
  checkFmt.finalize()
