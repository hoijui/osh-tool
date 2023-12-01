# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2022-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import os
import strformat
import system
import ../check
import ../check_config
import ../state
import ../util/fs
import std/logging
import std/osproc
import std/streams
import std/strutils
import ./okh_file_exists

const IDS = @["ol", "okh_lint"]
const ID = IDS[0]
const OKH_CMD = "okh-tool"

type OkhLintCheck = ref object of Check
type OkhLintCheckGenerator = ref object of CheckGenerator

method name*(this: OkhLintCheck): string =
  return "OKH manifest content"

method description*(this: OkhLintCheck): string =
  return """Checks that the OKH manifest file - \
which contains project meta-data - \
contains at least the required properties, \
and that all properties use the correct format."""

method why*(this: OkhLintCheck): string =
  return """This makes the project much more easily comparable,
both for humans and machines/software.

This is useful when dealing with a lot of projects,
to not waste life- or processing-time,
trying to figure out a certain,
commonly useful set of properties about a project."""

method sourcePath*(this: OkhLintCheck): string =
  return fs.srcFileName()

method requirements*(this: OkhLintCheck): CheckReqs =
  return {
    CheckReq.FileContent,
    CheckReq.ExternalTool,
  }

method getSignificanceFactors*(this: OkhLintCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.7,
    openness: 1.0,
    hardware: 0.0,
    quality: 1.0,
    machineReadability: 1.0,
    )

method run*(this: OkhLintCheck, state: var State): CheckResult =
  if not os.fileExists(okhFile(state.config)):
    return newCheckResult(CheckResultKind.Inapplicable, CheckIssueSeverity.High, some(fmt"Main OKH manifest file {OKH_FILE} not found"))
  try:
    debug fmt"Now running '{OKH_CMD}' ..."
    let process = osproc.startProcess(
      command = OKH_CMD,
      workingDir = state.config.projRoot,
      args = ["val", "--recursive", "--okh-version", "losh", "."],
      env = nil,
      options = {poUsePath})
    process.inputStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    process.errorStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    let (lines, exCode) = process.readLines()
    process.close()
    debug fmt"'{OKH_CMD}' run done."
    if exCode == 0:
      newCheckResult(CheckResultKind.Perfect)
    else:
      let msg = if len(lines) > 0:
          some(lines.join("\n"))
        else:
          none(string)
      newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.Middle, msg)
  except OSError as err:
    let msg = fmt("ERROR Failed to run '{OKH_CMD}'; make sure it is in your PATH: {err.msg}")
    newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.High, some(msg))

method id*(this: OkhLintCheckGenerator): seq[string] =
  return IDS

method generate*(this: OkhLintCheckGenerator, config: CheckConfig = newCheckConfig(ID)): Check =
  this.ensureNonConfig(config)
  OkhLintCheck()

proc createGenerator*(): CheckGenerator =
  OkhLintCheckGenerator()
