# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import regex
import strformat
import system
import ../check
import ../config
import ../state
import ../tools
import std/osproc

const REUSE_CMD = "reuse"

type ReuseLintCheck = ref object of Check

method name*(this: ReuseLintCheck): string =
  return "REUSE/SPDX Licensing info"

method description*(this: ReuseLintCheck): string =
  return """Checks that complete SPDX licensing info is given \
for all files in the project, \
using the Free Software Foundations REUSE tool.
Note that this is related to the License exists check."""

method sourcePath*(this: ReuseLintCheck): string =
  return tools.srcFileName()

method requirements*(this: ReuseLintCheck): CheckReqs =
  return {}

method getRatingFactors*(this: ReuseLintCheck): CheckRelevancy =
  return CheckRelevancy(
    weight: 0.5,
    openness: 1.0,
    hardware: 0.0,
    quality: 0.3,
    machineReadability: 1.0,
    )

method run*(this: ReuseLintCheck, state: var State): CheckResult =
  try:
    let process = osproc.startProcess(
      command = REUSE_CMD,
      workingDir = state.config.projRoot,
      args = ["lint"],
      env = nil,
      options = {poUsePath})
    let (lines, exCode) = process.readLines
    if exCode == 0:
      newCheckResult(CheckResultKind.Perfect)
    else:
      var msg_lines = ""
      var summary = false
      var m: RegexMatch
      for line in lines:
        if summary:
          if match(line, re"^[*] (.*: .+)$", m):
            msg_lines = fmt("{msg_lines}{m.group(0, line)[0]}\n")
        if not summary and line == "# SUMMARY":
          summary = true
      let msg = if len(msg_lines) > 0:
          some(msg_lines)
        else:
          none(string)
      newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.Middle, msg)
  except OSError as err:
    let msg = fmt("Failed to run '{REUSE_CMD}'; make sure it is in your PATH: {err.msg}")
    newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.High, some(msg))

proc createDefault*(): Check =
  ReuseLintCheck()
