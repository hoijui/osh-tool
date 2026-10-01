# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import json
import options
import strformat
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
  return fmt"""Checks whether an OSH directory standard is used \
for a sufficient amount of files and directories in the project, \
using the {OSH_DIR_STD_TOOL_CMD} CLI tool.
This standard is comprised of multiple sub-standards,
or say:
There is not just one accepted way to name your dirs and files,
but multiple,
and new ones may be added by the community."""

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
    let args = ["rate", "--all", "--include-coverage"]
    let jsonLines = runOshDirStd(state.config.projRoot, args, state.listFiles())
    let jsonRoot = parseJson(jsonLines)
    var prefixText = """The compliance factors for the different standards
(0.0 means the checked project does not coincide with the standard at all,
while 1.0 means the checked project follows the standard perfectly):\n"""

    # Find highest compliance factor
    var maxFactor = 0.0
    for std in jsonRoot:
      let compFactor = float32(std["rating"]["factor"].getFloat())
      if compFactor > maxFactor:
        maxFactor = compFactor

    # Find most fitting standards
    # (could be more then one, if they reached the same factor)
    # and report standard compliance factors
    var mostFittingStds: seq[JsonNode]
    if maxFactor == 0.0:
      prefixText &= "This project does not comply at all with any of the directory standards (all compliance factors are 0.0)\n"
    else:
      for std in jsonRoot:
        let name = std["rating"]["name"].getStr()
        let compFactor = float32(std["rating"]["factor"].getFloat())
        if compFactor == maxFactor:
          mostFittingStds.add(std)
          prefixText &= fmt"- {name}: *{compFactor}*\n"
        elif compFactor > 0.0:
          prefixText &= fmt"- {name}: {compFactor}\n"

      prefixText &= "\n"
      prefixText &= "There are {mostFittingStds.len()} standards\n"
      prefixText &= "that fit with a compliance factor of {maxFactor},\n"
      prefixText &= "which is the maximum obtained by this project.\n"
      prefixText &= "They are:\n"

      var issues: seq[CheckIssue] = @[]
      for std in mostFittingStds:
        let name = std["rating"]["name"].getStr()
        prefixText &= "\n"
        prefixText &= "##### {name}\n"
        prefixText &= "\n"
        prefixText &= "project files not covered by the standard:\n"
        prefixText &= "\n"
        for notInStdFile in std["coverage"]["out"]:
          issues.add(CheckIssue(
              severity: CheckIssueSeverity.Low,
              msg: some(notInStdFile.getStr())
            ))
      let maxFactorRounded = round(maxFactor)
      # let numFiles = state.listFiles()
      # let kind = if issues.len() / mostFittingStds.len() > OK_NUM_FACTOR_OF_UNCOVERED_FILES * numFiles:
      #     CheckResultKind.Ok
      #   else:
      #     CheckResultKind.Acceptable

      let kind = if maxFactor == 1.0:
        CheckResultKind.Perfect
      elif maxFactor >= HIGH_COMPLIANCE:
        issues.add(CheckIssue(
            severity: CheckIssueSeverity.Middle,
            msg: some(fmt"""Compliance factor {maxFactorRounded} is not perfect, but close, \
being above the high compliance margin of {HIGH_COMPLIANCE}; good! :-)"""))
          )
        CheckResultKind.Ok
      elif maxFactor >= MIN_COMPLIANCE:
        issues.add(CheckIssue(
            severity: CheckIssueSeverity.Middle,
            msg: some(fmt"""Compliance factor {maxFactorRounded} is above the minimum compliance margin \
of {MIN_COMPLIANCE}"""))
          )
        CheckResultKind.Acceptable
      else:
        issues.add(CheckIssue(
            severity: CheckIssueSeverity.Middle,
            msg: some(fmt"""Compliance factor {maxFactorRounded} is low; \
below the minimum compliance margin of {MIN_COMPLIANCE}"""))
          )
        CheckResultKind.Bad

      return CheckResult(
        config: config,
        kind: kind,
        issues: issues,
        complianceFractionOverride: some(float32(maxFactor))
      )
  except OSError as err:
    return newCheckResult(config, CheckResultKind.Bad, CheckIssueSeverity.High, some(err.msg))

method id*(this: UsesDirStdCheckGenerator): string =
  return ID

method generate*(this: UsesDirStdCheckGenerator, config: CheckConfig = this.defaultConfig()): Check =
  this.ensureNonConfig(config)
  UsesDirStdCheck(generator: this)

proc createGenerator*(): CheckGenerator =
  UsesDirStdCheckGenerator()
