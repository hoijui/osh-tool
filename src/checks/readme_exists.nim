# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import re
import strformat
import tables
import ../check
import ../check_config
import ../state
import ../util/fs

const IDS = @["re", "rdmex", "readme_exists"]
const ID = IDS[0]
let RS_README = "(?i)^.*README.*$"
let R_README = re(RS_README)

type ReadmeExistsCheck = ref object of Check
type ReadmeExistsCheckGenerator = ref object of CheckGenerator

method name(this: ReadmeExistsCheck): string =
  return "README exists"

method description*(this: ReadmeExistsCheck): string =
  return fmt"""Checks that a README file exists in the projects root dir, \
using the regex `{RS_README}`."""

method why*(this: ReadmeExistsCheck): string =
  return """A README file is the main entry point for a human that comes along the project,
and wants to figure out what it is about, and how to use it.

It is targeted at all potential stakeholders of the project,
be it designers, manufacturers, sellers, repairers or users.

We might think of it as the most essential,
basic part of the documentation of the project."""

method sourcePath*(this: ReadmeExistsCheck): string =
  return fs.srcFileName()

method requirements*(this: ReadmeExistsCheck): CheckReqs =
  return {
    CheckReq.FilesListL1,
  }

method getSignificanceFactors*(this: ReadmeExistsCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.2,
    openness: 1.0,
    hardware: 0.0,
    quality: 0.1,
    machineReadability: 0.5,
    )

method run(this: ReadmeExistsCheck, state: var State): CheckResult =
  let config = state.config.checks[ID]
  return (if filterPathsMatching(state.listFilesL1(), R_README).len > 0:
    newCheckResult(config, CheckResultKind.Perfect)
  else:
    newCheckResult(
      config,
      CheckResultKind.Bad,
      CheckIssueSeverity.Middle,
      some("""No README file found in the root directory.
 Please consider adding a 'README.md'.""")
    )
  )

method id*(this: ReadmeExistsCheckGenerator): seq[string] =
  return IDS

method generate*(this: ReadmeExistsCheckGenerator, config: CheckConfig = newCheckConfig(ID)): Check =
  this.ensureNonConfig(config)
  ReadmeExistsCheck()

proc createGenerator*(): CheckGenerator =
  ReadmeExistsCheckGenerator()
