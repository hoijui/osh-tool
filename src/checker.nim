# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import chronicles
import os
import options
import sequtils
import strformat
import strutils
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

method init(self: CheckFmt) {.base.} =
  quit "to override!"

method init(self: MdListCheckFmt) =
  info "Checking OSH project directory ..."

method init(self: MdTableCheckFmt) =
  self.repStream.writeLine(fmt"| Passed | Check | Message |")
  # NOTE In some renderers, number of dashes are used to determine relative column width
  self.repStream.writeLine(fmt"| - | --- | ----- |")

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

method report(self: CheckFmt, check: Check, res: CheckResult) {.base, locks: "unknown".} =
  quit "to override!"

method report(self: MdListCheckFmt, check: Check, res: CheckResult) =
  let passed = isGood(res)
  let passedStr = if passed: "x" else: " "
  let msg = res.issues
    .map(proc (issue: CheckIssue): string =
      let weightStr = fmt"{issue.weight}"
      fmt("\n  - {weightStr.toUpper()}{msgFmt(issue.msg)}")
    )
    .join("")
  self.getStream(res).writeLine(fmt"- [{passedStr}] {check.name()}{msg}")

method report(self: MdTableCheckFmt, check: Check, res: CheckResult) {.locks: "unknown".} =
  let passed = isGood(res)
  let passedStr = if passed: "x" else: " "
  let msg = res.issues
    .map(proc (issue: CheckIssue): string =
      fmt"\[{issue.weight}{msgFmt(issue.msg)}\]"
    )
    .join(", <br>")
    .replace("\n", " <br>-- ")
  self.getStream(res).writeLine(fmt"| [{passedStr}] | {check.name()} | {msg} |")

method finalize(self: CheckFmt) {.base.} =
  self.repStream.close()
  # This isnot required,
  # because stderr does not need to be closed,
  # and if it is a file, it is the same like repStream,
  # which was already closed in the line above
  #repStreamErr.close()

proc initRepStreams(state: State): (File, File) =
  return
    if state.config.reportTarget.isSome():
      let reportFileName = state.config.reportTarget.get()
      if not state.config.force and fileExists(reportFileName):
        error "Report file exists, and --force was not specified; aborting.", reportFile = reportFileName
        quit 1
      let file = io.open(reportFileName, fmWrite)
      (file, file)
    else:
      (stdout, stderr)

proc initCheckFmt(state: State, repStream, repStreamErr: File): CheckFmt =
  if state.config.markdown:
    return MdTableCheckFmt(repStream: repStream, repStreamErr: repStreamErr)
  else:
    return MdListCheckFmt(repStream: repStream, repStreamErr: repStreamErr)

proc check*(registry: ChecksRegistry, state: var State) =
  let (repStream, repStreamErr) = initRepStreams(state)
  let checkFmt: CheckFmt = initCheckFmt(state, repStream, repStreamErr)
  for check in registry.checks:
    let res = check.run(state)
    if not isApplicable(res):
      debug "Skip reporting check because it is inapplicable to this project (in its current state)", checkName = check.name()
      continue
    checkFmt.report(check, res)
  checkFmt.finalize()
