# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import re
import options
import strformat
import ../check
import ../state
import ../tools

let RS_README = "(?i)^.*README.*$"
let R_README = re(RS_README)

type ReadmeExistsCheck = ref object of Check

method name(this: ReadmeExistsCheck): string =
  return "README exists"

method description*(this: ReadmeExistsCheck): string =
  return fmt"""Checks that a README file exists in the projects root dir, \
using the regex `{RS_README}`."""

method sourcePath*(this: ReadmeExistsCheck): string =
  return tools.srcFileName()

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
  return (if filterPathsMatching(state.listFilesL1(), R_README).len > 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    newCheckResult(
      CheckResultKind.Bad,
      CheckIssueSeverity.Middle,
      some("""No README file found in the root directory.
 Please consider adding a 'README.md'.""")
    )
  )

proc createDefault*(): Check =
  ReadmeExistsCheck()
