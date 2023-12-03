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
import tables
import ../check
import ../check_config
import ../state
import ../util/leightweight
import ../util/fs
import ../util/run

include ../constants

#const IDS = @[srcFileNameBase(), "dss", "dirstd", "dir_std", "dir_std_used"]
const ID = srcFileNameBase()
const HIGH_COMPLIANCE = 0.9
const MIN_COMPLIANCE = 0.6

type UsesDirStdCheck = ref object of Check
type UsesDirStdCheckGenerator = ref object of CheckGenerator

method name*(this: UsesDirStdCheck): string =
  return "Uses dir standard"

method description*(this: UsesDirStdCheck): string =
  return fmt"""Checks whether the {DIR_STD_NAME} OSH directory standard is used \
for a sufficient amount of files and directories in the project, \
using the {OSH_DIR_STD_TOOL_CMD} CLI tool."""

method why*(this: UsesDirStdCheck): string =
  return """1. to be able to extract meta-data:
    1. easy indexing (and thus finding) of projects
    2. easy comparing of projects
    3. allows to write software tools that deal with project repos
2. find your way around quickly and easily in different projects"""

method sourcePath*(this: UsesDirStdCheck): string =
  return fs.srcFileName()

method requirements*(this: UsesDirStdCheck): CheckReqs =
  return {
    CheckReq.FilesListRec,
    CheckReq.ExternalTool,
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
  let config = state.config.checks[ID]
  try:
    let args = ["rate", "--standard", DIR_STD_NAME, "--include-coverage"]
    let jsonLines = runOshDirStd(state.config.projRoot, args, state.listFiles())
    let jsonRoot = parseJson(jsonLines)
    for std in jsonRoot:
      if std["rating"]["name"].getStr() == DIR_STD_NAME:
        let compFactor = float32(std["rating"]["factor"].getFloat())
        var notInStdFiles = newSeq[string]()
        for notInStdFile in std["coverage"]["out"]:
          notInStdFiles.add(notInStdFile.getStr())
        let notInStdFilesStr = """


files not covered by the standard:

- """ & notInStdFiles.join("\n- ")
        let compFactorRounded = round(compFactor)
        if compFactor == 1.0:
          return newCheckResult(config, CheckResultKind.Perfect)
        elif compFactor >= HIGH_COMPLIANCE:
          return newCheckResult(config, CheckResultKind.Ok, CheckIssueSeverity.Middle,
              some(fmt"""Compliance factor {compFactorRounded} is not perfect, but close, \
being above the high compliance margin of {HIGH_COMPLIANCE}""" & notInStdFilesStr))
        elif compFactor >= MIN_COMPLIANCE:
          return newCheckResult(config, CheckResultKind.Ok, CheckIssueSeverity.Middle,
              some(fmt"""Compliance factor {compFactorRounded} is above the minimum compliance margin \
of {MIN_COMPLIANCE}; good! :-)""" & notInStdFilesStr))
        else:
          return newCheckResult(config, CheckResultKind.Bad, CheckIssueSeverity.Middle,
              some(fmt"""Compliance factor {compFactorRounded} is low; \
below the minimum compliance margin of {MIN_COMPLIANCE}""" & notInStdFilesStr))
    return newCheckResult(config, CheckResultKind.Ok, CheckIssueSeverity.DeveloperFailure,
        some(fmt"""Compliance factor for the '{DIR_STD_NAME}' directory standard name not found; \
please report to the developers of this tool here: <{OSH_TOOL_ISSUES_URL}>"""))
  except OSError as err:
    return newCheckResult(config, CheckResultKind.Bad, CheckIssueSeverity.High, some(err.msg))

method id*(this: UsesDirStdCheckGenerator): string =
  return ID

method generate*(this: UsesDirStdCheckGenerator, config: CheckConfig = this.defaultConfig()): Check =
  this.ensureNonConfig(config)
  UsesDirStdCheck()

proc createGenerator*(): CheckGenerator =
  UsesDirStdCheckGenerator()
