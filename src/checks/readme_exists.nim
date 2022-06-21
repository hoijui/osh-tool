# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import re
import options
import ../tools
import ../check
import ../state

let R_README = re"^.*README.*$"

type ReadmeExistsCheck = ref object of Check

method name(this: ReadmeExistsCheck): string =
  return "README exists"

method requirements*(this: Check): CheckReqs =
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
