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
const REUSE_TOOL_URL = "https://reuse.software/"

type ReuseLintCheck = ref object of Check

method name*(this: ReuseLintCheck): string =
  return "REUSE/SPDX Licensing info"

method description*(this: ReuseLintCheck): string =
  return """Checks that complete SPDX licensing info is given \
for all files in the project. \
We do this using the Free Software Foundations REUSE tool.

NOTE: This is related to the License exists check."""

method why*(this: ReuseLintCheck): string =
  return """Copyright and licensing is difficult,
especially when reusing software from different projects
that are released under various different licenses.
[REUSE](https://reuse.software/) was started by
the [Free Software Foundation Europe](https://fsfe.org/) (FSFE)
to provide a set of recommendations to make licensing your Free Software projects easier.
Not only do these recommendations make it easier for you
to declare the licenses under which your works are released,
but they also make it easier for a computer
to understand how your project is licensed.

Propper licensing information may prevent or help in potential legal disputes.
It also helps anyone using your source or derivates of it,
to understand their rights.
"""

method sourcePath*(this: ReuseLintCheck): string =
  return tools.srcFileName()

method requirements*(this: ReuseLintCheck): CheckReqs =
  return {}

method getSignificanceFactors*(this: ReuseLintCheck): CheckSignificance =
  return CheckSignificance(
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
      msg_lines &= "For more details then this list, and help with fixing these issues,\n"
      msg_lines &= "please use the REUSE tool, available in as Linux package `reuse`,\n"
      msg_lines &= fmt"or under <{REUSE_TOOL_URL}>." & "\n"
      msg_lines &= "\n"
      var summary = false
      var m: RegexMatch
      for line in lines:
        if summary:
          if match(line, re"^[*] (.*: .+)$", m):
            msg_lines = fmt("{msg_lines}{m.group(0, line)[0]}\n")
        if not summary and line == "# SUMMARY":
          summary = true
      let msg = some(msg_lines)
      newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.Middle, msg)
  except OSError as err:
    let msg = fmt("Failed to run '{REUSE_CMD}'; make sure it is in your PATH: {err.msg}")
    newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.High, some(msg))

proc createDefault*(): Check =
  ReuseLintCheck()
