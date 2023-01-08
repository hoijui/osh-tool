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
import std/logging
import std/osproc
import std/streams

const OSH_DIR_STD_TOOL_CMD = "osh-dir-std"
const DIR_STD_NAME = "unixish"
const MIN_CONFORMANCE = 0.6

type UsesDirStdCheck = ref object of Check

method name*(this: UsesDirStdCheck): string =
  return "Uses dir standard"

method description*(this: UsesDirStdCheck): string =
  return fmt"""Checks whether the {DIR_STD_NAME} OSH directory standard is used \
for a sufficient ammount of files and direcotries in the project, \
using the {OSH_DIR_STD_TOOL_CMD} CLI tool."""

method requirements*(this: UsesDirStdCheck): CheckReqs =
  return {
    CheckReq.FilesListRec,
  }

method getRatingFactors*(this: UsesDirStdCheck): CheckRelevancy =
  return CheckRelevancy(
    weight: 1.0,
    openness: 1.0,
    hardware: 1.0,
    quality: 1.0,
    machineReadability: 1.0,
    )

method run*(this: UsesDirStdCheck, state: var State): CheckResult =
  debug "Running osh-dir-std ..."
  try:
    let process = osproc.startProcess(
      command = OSH_DIR_STD_TOOL_CMD,
      workingDir = state.config.projRoot,
      args = ["rate"],
      env = nil,
      options = {poUsePath})
    let procStdin = process.inputStream()
    debug "  osh-dir-std: Writing to stdin ..."
    for path in state.listFiles():
      procStdin.writeLine(path)
    debug "  osh-dir-std: Close stdin (we supposedly should not do this manually, but apparently we have to!) ..."
    procStdin.close()
    debug "  osh-dir-std: Ask for exit code and stdout ..."
    let (lines, exCode) = process.readLines
    debug "  osh-dir-std: Run finnished; analyze results ..."
    if exCode == 0:
      debug "  osh-dir-std: Process output ..."
      let jsonLines = lines.join("\n")
      debug "  osh-dir-std: jsonLines:"
      debug jsonLines
      let jsonRoot = parseJson(jsonLines)
      for std in jsonRoot:
        if std["name"].getStr() == DIR_STD_NAME:
          let confFactor = float32(std["factor"].getFloat())
          if confFactor == 1.0:
            return newCheckResult(CheckResultKind.Perfect)
          if confFactor >= MIN_CONFORMANCE:
            return newCheckResult(CheckResultKind.Ok, CheckIssueImportance.Middle,
                some(fmt"Not perfect, but above the minimum expected conformance factor of {MIN_CONFORMANCE}"))
          else:
            return newCheckResult(CheckResultKind.Ok, CheckIssueImportance.Middle,
                some(fmt"Conformance is not perfect, but above the minimum expected factor of {MIN_CONFORMANCE}"))
      return newCheckResult(CheckResultKind.Bad, CheckIssueImportance.Severe,
          some(fmt"Conformance is below the minimum expected factor of {MIN_CONFORMANCE}"))
    else:
      let msg = fmt("""Failed to run '{OSH_DIR_STD_TOOL_CMD}'; exit state was {exCode}; output:\n{lines.join("\n")}""")
      return newCheckResult(CheckResultKind.Bad, CheckIssueImportance.Severe, some(msg))
  except OSError as err:
    let msg = fmt("Failed to run '{OSH_DIR_STD_TOOL_CMD}'; make sure it is in your PATH: {err.msg}")
    return newCheckResult(CheckResultKind.Bad, CheckIssueImportance.Severe, some(msg))

proc createDefault*(): Check =
  UsesDirStdCheck()
