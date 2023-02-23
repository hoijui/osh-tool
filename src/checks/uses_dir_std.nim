# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import json
import options
import strformat
import strutils
import system
import ../check
import ../config
import ../state
import ../tools
import std/logging
import std/osproc
import std/streams

include ../constants

const OSH_DIR_STD_TOOL_CMD = "osh-dir-std"
const DIR_STD_NAME = "unixish"
const HIGH_COMPLIANCE = 0.9
const MIN_COMPLIANCE = 0.6

type UsesDirStdCheck = ref object of Check

method name*(this: UsesDirStdCheck): string =
  return "Uses dir standard"

method description*(this: UsesDirStdCheck): string =
  return fmt"""Checks whether the {DIR_STD_NAME} OSH directory standard is used \
for a sufficient amount of files and directories in the project, \
using the {OSH_DIR_STD_TOOL_CMD} CLI tool."""

method sourcePath*(this: UsesDirStdCheck): string =
  return tools.srcFileName()

method requirements*(this: UsesDirStdCheck): CheckReqs =
  return {
    CheckReq.FilesListRec,
  }

method getSignificanceFactors*(this: UsesDirStdCheck): CheckSignificance =
  return CheckSignificance(
    weight: 1.0,
    openness: 1.0,
    hardware: 0.3,
    quality: 1.0,
    machineReadability: 1.0,
    )

method run*(this: UsesDirStdCheck, state: var State): CheckResult =
  debug "Running osh-dir-std ..."
  try:
    let process = osproc.startProcess(
      command = OSH_DIR_STD_TOOL_CMD,
      workingDir = state.config.projRoot,
      args = ["rate", "--standard", DIR_STD_NAME],
      env = nil,
      options = {poUsePath})
    let procStdin = process.inputStream()
    debug fmt"  {OSH_DIR_STD_TOOL_CMD}: Writing to stdin ..."
    for path in state.listFiles():
      procStdin.writeLine(path)
    debug fmt"  {OSH_DIR_STD_TOOL_CMD}: Close stdin (we supposedly should not do this manually, but apparently we have to!) ..."
    procStdin.close()
    debug fmt"  {OSH_DIR_STD_TOOL_CMD}: Ask for exit code and stdout ..."
    let (lines, exCode) = process.readLines
    debug fmt"  {OSH_DIR_STD_TOOL_CMD}: Run finnished; analyze results ..."
    if exCode == 0:
      debug fmt"  {OSH_DIR_STD_TOOL_CMD}: Process output ..."
      let jsonLines = lines.join("\n")
      debug fmt"  {OSH_DIR_STD_TOOL_CMD}: jsonLines:"
      debug jsonLines
      let jsonRoot = parseJson(jsonLines)
      for std in jsonRoot:
        if std["name"].getStr() == DIR_STD_NAME:
          let compFactor = float32(std["factor"].getFloat())
          let compFactorRounded = round(compFactor)
          if compFactor == 1.0:
            return newCheckResult(CheckResultKind.Perfect)
          elif compFactor >= HIGH_COMPLIANCE:
            return newCheckResult(CheckResultKind.Ok, CheckIssueSeverity.Middle,
                some(fmt"Compliance factor {compFactorRounded} is not perfect, but close, being above the upper expected factor of {HIGH_COMPLIANCE}"))
          elif compFactor >= MIN_COMPLIANCE:
            return newCheckResult(CheckResultKind.Ok, CheckIssueSeverity.Middle,
                some(fmt"Compliance factor {compFactorRounded} is above the minimum expected factor of {MIN_COMPLIANCE}; good! :-)"))
          else:
            return newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.Middle,
                some(fmt"Compliance factor {compFactorRounded} is low; below the minimum expected factor of {MIN_COMPLIANCE}"))
      return newCheckResult(CheckResultKind.Ok, CheckIssueSeverity.DeveloperFailure,
          some(fmt"Compliance factor for the '{DIR_STD_NAME}' directory standard name not found; please report to the developers of this tool here: <{OSH_TOOL_ISSUES_URL}>"))
    else:
      let msg = fmt("""Failed to run '{OSH_DIR_STD_TOOL_CMD}'; exit state was {exCode}; output:\n{lines.join("\n")}""")
      return newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.High, some(msg))
  except OSError as err:
    let msg = fmt("Failed to run '{OSH_DIR_STD_TOOL_CMD}'; make sure it is in your PATH: {err.msg}")
    return newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.High, some(msg))

proc createDefault*(): Check =
  UsesDirStdCheck()
