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
  info "Checking OSH project directory ..."

method init(self: MdTableCheckFmt) =
  self.repStream.writeLine(fmt"| Passed | Check | Message |")
  # NOTE In some renderers, number of dashes are used to determine relative column width
  self.repStream.writeLine(fmt"| - | --- | ----- |")

method init(self: JsonCheckFmt) =
  self.repStream.writeLine("[")

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

method report(self: CheckFmt, check: Check, res: CheckResult, index: int, total: int) {.base, locks: "unknown".} =
  quit "to override!"

method report(self: MdListCheckFmt, check: Check, res: CheckResult, index: int, total: int) =
  let passed = isGood(res)
  let passedStr = if passed: "x" else: " "
  let msg = res.issues
    .map(proc (issue: CheckIssue): string =
      let weightStr = fmt"{issue.weight}"
      fmt("\n  - {weightStr.toUpper()}{msgFmt(issue.msg)}")
    )
    .join("")
  self.getStream(res).writeLine(fmt"- [{passedStr}] {check.name()}{msg}")

method report(self: MdTableCheckFmt, check: Check, res: CheckResult, index: int, total: int) {.locks: "unknown".} =
  let passed = isGood(res)
  let passedStr = if passed: "x" else: " "
  let msg = res.issues
    .map(proc (issue: CheckIssue): string =
      fmt"\[{issue.weight}{msgFmt(issue.msg)}\]"
    )
    .join(", <br>")
    .replace("\n", " <br>-- ")
  self.getStream(res).writeLine(fmt"| [{passedStr}] | {check.name()} | {msg} |")

method report(self: JsonCheckFmt, check: Check, res: CheckResult, index: int, total: int) {.locks: "unknown".} =
  self.repStream.writeLine("  {")
  self.repStream.writeLine(fmt"""    "name": "{check.name()}",""")
  let passed = isGood(res)
  self.repStream.writeLine(fmt"""    "passed": "{passed}",""")
  self.repStream.write(fmt"""    "state": "{res.kind}" """)
  let numIssues = len(res.issues)
  if numIssues > 0:
    self.repStream.writeLine(",")
    self.repStream.writeLine(fmt"""    "issues": [""")
    var indIssue = 0
    var potComma = ","
    for issue in res.issues:
      self.repStream.writeLine("      {")
      self.repStream.writeLine(fmt"""        "weight": "{issue.weight}",""")
      if issue.msg.isSome:
        self.repStream.writeLine(fmt"""        "msg": "{issue.msg.get().replace('\n', ' ')}" """)
      indIssue += 1
      if indIssue == numIssues:
        potComma = ""
      self.repStream.writeLine(fmt"      }}{potComma}") # Add comma if not last
    self.repStream.write("    ]")
  self.repStream.writeLine("")

  self.repStream.write("  }")
  if index + 1 < total:
    self.repStream.write(",") # Add comma if not last
  self.repStream.writeLine("")

method finalize(self: CheckFmt)  {.base, locks: "unknown".} =
  self.repStream.close()
  # This is not required,
  # because stderr does not need to be closed,
  # and if it is a file, it is the same like repStream,
  # which was already closed in the line above
  #repStreamErr.close()

method finalize(self: JsonCheckFmt) {.locks: "unknown".} =
  self.repStream.writeLine("]")
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
  var idx = 0
  checkFmt.init()
  for check in registry.checks:
    let res = check.run(state)
    if not isApplicable(res):
      debug fmt"Skip reporting check '{check.name()}', because it is inapplicable to this project (in its current state)"
      continue
    checkFmt.report(check, res, idx, numChecks)
    idx += 1
  checkFmt.finalize()
