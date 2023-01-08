# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import os
import strformat
import system
import ../check
import ../config
import ../state
import ../tools
import std/osproc
import std/strutils
import ./okh_file_exists

const OKH_CMD = "okh-tool"

type OkhLintCheck = ref object of Check

method name*(this: OkhLintCheck): string =
  return "OKH manifest content"

method description*(this: OkhLintCheck): string =
  return """Checks that the OKH manifest file - \
which contains project meta-data - \
contains at least the required properties, \
and that all properties use the correct format."""

method sourcePath*(this: OkhLintCheck): string =
  return tools.srcFileName()

method requirements*(this: OkhLintCheck): CheckReqs =
  return {}

method getRatingFactors*(this: OkhLintCheck): CheckRelevancy =
  return CheckRelevancy(
    weight: 0.7,
    openness: 1.0,
    hardware: 0.0,
    quality: 1.0,
    machineReadability: 1.0,
    )

method run*(this: OkhLintCheck, state: var State): CheckResult =
  if not os.fileExists(okhFile(state.config)):
    return newCheckResult(CheckResultKind.Inapplicable, CheckIssueImportance.Severe, some(fmt"Main OKH manifest file {OKH_FILE} not found"))
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
