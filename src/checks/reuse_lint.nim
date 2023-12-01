# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2022-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import regex
import strformat
import strutils
import system
import ../check
import ../check_config
import ../state
import ../util/leightweight
import ../util/fs
import std/logging
import std/osproc
import std/streams

const IDS = @["rl", "reusel", "reuse_lint"]
const ID = IDS[0]
const REUSE_CMD = "reuse"
const REUSE_TOOL_URL = "https://reuse.software/"
const HIGH_COMPLIANCE = 0.7
const MIN_COMPLIANCE = 0.2

type ReuseLintCheck = ref object of Check
type ReuseLintCheckGenerator = ref object of CheckGenerator

method name*(this: ReuseLintCheck): string =
  return "REUSE Licensing info"

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
  return fs.srcFileName()

method requirements*(this: ReuseLintCheck): CheckReqs =
  return {
    CheckReq.ExternalTool,
  }

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
    debug fmt"Now running '{REUSE_CMD}' ..."
    let process = osproc.startProcess(
      command = REUSE_CMD,
      workingDir = state.config.projRoot,
      args = ["lint"],
      env = nil,
      options = {poUsePath})
    process.inputStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    process.errorStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    let (lines, exCode) = process.readLines()
    process.close()
    debug fmt"'{REUSE_CMD}' run done."
    if exCode == 0:
      newCheckResult(CheckResultKind.Perfect)
    else:
      var msg_lines = newSeq[string]()
      msg_lines.add("For more details then this list, and help with fixing these issues,")
      msg_lines.add("please use the REUSE tool, available in as Linux package `reuse`,")
      msg_lines.add(fmt"or under <{REUSE_TOOL_URL}>.")
      msg_lines.add("")
      var secSummary = false
      var secMissingInfo = false
      var issues = newSeq[CheckIssue]()
      var m: RegexMatch2
      var coverage = 0.0
      var coverageDimensions = 0
      for line in lines:
        if secSummary:
          if match(line, re2"^[*] (.*: .+)$", m):
            let mainLinePart = line[m.group(0)];
            msg_lines.add(mainLinePart)
            # Samples for interesting instances of mainLinePart:
            # - "Files with copyright information: 30 / 31"
            # - "Files with license information: 30 / 31"
            if match(mainLinePart, re2"^Files with (copyright|license) information: (\d+) / (\d+)$", m):
              let haveInfo = parseInt(mainLinePart[m.group(1)]);
              let total = parseInt(mainLinePart[m.group(2)]);
              coverage += haveInfo.float / total.float
              coverageDimensions += 1
        elif secMissingInfo:
          if match(line, re2"^[*] (.+)$", m):
            let file = line[m.group(0)];
            issues.add(CheckIssue(
              severity: CheckIssueSeverity.Low,
              msg: some(fmt"File with missing copyright and/or license info: {file}")
            ))
        if match(line, re2"^# (.+)$", m):
          # Section header
          let name = line[m.group(0)];
          secSummary = false
          secMissingInfo = false
          if not secSummary and name == "SUMMARY":
            secSummary = true
          if not secMissingInfo and name == "MISSING COPYRIGHT AND LICENSING INFORMATION":
            secMissingInfo = true
      if coverageDimensions > 0:
        coverage = coverage / coverageDimensions.float
      msg_lines.add("")
      msg_lines.add(fmt"Total coverage (roughly): {toPercentStr(coverage)}%")
      msg_lines.add("")
      msg_lines.add("Please get to a perfect REUSE state by using the REUSE-tool locally")
      msg_lines.add(fmt"(after installing): `{REUSE_CMD} lint`")
      let msg = some(msg_lines.join("\n"))
      let kind = if coverage < MIN_COMPLIANCE:
          CheckResultKind.Bad
        elif coverage < HIGH_COMPLIANCE:
          CheckResultKind.Acceptable
        else:
          CheckResultKind.Ok
      issues.insert(CheckIssue(
        severity: CheckIssueSeverity.Middle,
        msg: msg
      ), 0)
      CheckResult(
        kind: kind,
        issues: issues
      )

  except OSError as err:
    let msg = fmt("Failed to run '{REUSE_CMD}'; make sure it is in your PATH: {err.msg}")
    newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.High, some(msg))

method id*(this: ReuseLintCheckGenerator): seq[string] =
  return IDS

method generate*(this: ReuseLintCheckGenerator, config: CheckConfig = newCheckConfig(ID)): Check =
  this.ensureNonConfig(config)
  ReuseLintCheck()

proc createGenerator*(): CheckGenerator =
  ReuseLintCheckGenerator()
