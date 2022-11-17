# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import strformat
import system
import ../check
import ../config
import ../state
import std/osproc
import std/strutils

const OKH_CMD = "okh-tool"

type OkhLintCheck = ref object of Check

method name*(this: OkhLintCheck): string =
  return "OKH manifest content"

method requirements*(this: OkhLintCheck): CheckReqs =
  return {}

method run*(this: OkhLintCheck, state: var State): CheckResult =
  try:
    let okhProc = osproc.startProcess(
      command = OKH_CMD,
      workingDir = state.config.projRoot,
      args = ["val", "--recursive", "--okh-version", "losh", "."],
      env = nil,
      options = {poUsePath})
    let (lines, exCode) = okhProc.readLines
    if exCode == 0:
      newCheckResult(CheckResultKind.Perfect)
    else:
      let msg = if len(lines) > 0:
          some(lines.join("\n"))
        else:
          none(string)
      newCheckResult(CheckResultKind.Bad, CheckIssueImportance.Middle, msg)
  except OSError as err:
    let msg = fmt("ERROR Failed to run '{OKH_CMD}'; make sure it is in your PATH: {err.msg}")
    newCheckResult(CheckResultKind.Bad, CheckIssueImportance.Severe, some(msg))

proc createDefault*(): Check =
  OkhLintCheck()
