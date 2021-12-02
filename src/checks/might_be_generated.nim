# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

from strutils import join
import re
import options
import ../tools
import ../check
import ../state

let R_GENERATABLE= re"^.*(jpg|jpeg|gif|png|bmp|pdf|stl)$" # TODO Add much more (PDF, STL, ...) and maybe make this list in a CSV as well

type MightBeGeneratedCheck = ref object of Check

method name*(this: MightBeGeneratedCheck): string =
  return "Might be generated" # TODO Rename this, to be something that is good if the tst passes, e.g. "No possibly generatable files"

method requirements*(this: Check): CheckReqs =
  return {
    CheckReq.FilesListRec,
  }

method run*(this: MightBeGeneratedCheck, state: var State): CheckResult =
  let foundFiles = filterPathsMatchingFileName(state.listFiles(), R_GENERATABLE)
  return (if foundFiles.len == 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    newCheckResult(
      CheckResultKind.Bad,
      CheckIssueWeight.Light,
      some(
        "Possibly generatable files found. Please consider removing them:\n\n* " &
        foundFiles.join("\n* ")
      )
    )
  )

proc createDefault*(): Check =
  MightBeGeneratedCheck()
