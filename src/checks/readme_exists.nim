# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import re
import options
import strformat
import ../tools
import ../check
import ../state

let RS_README = "^.*README.*$"
let R_README = re(RS_README)

type ReadmeExistsCheck = ref object of Check

method name(this: ReadmeExistsCheck): string =
  return "README exists"

method description*(this: ReadmeExistsCheck): string =
  return fmt"""Checks that a README file exists in the projects root dir, \
using the regex `{RS_README}`."""

method requirements*(this: ReadmeExistsCheck): CheckReqs =
  return {
    CheckReq.FilesListL1,
  }

method run(this: ReadmeExistsCheck, state: var State): CheckResult =
  return (if filterPathsMatching(state.listFilesL1(), R_README).len > 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    newCheckResult(
      CheckResultKind.Bad,
      CheckIssueImportance.Middle,
      some("No README file found in the root directory.\nPlease consider adding a 'README.md'.\nYou might want to generate a template by issuing `osh init --readme`,\nor manually reating it.")
    )
  )

proc createDefault*(): Check =
  ReadmeExistsCheck()
