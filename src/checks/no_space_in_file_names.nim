# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

from strutils import join
import re
import options
import ../check
import ../state
import ../tools

let R_SPACE = re".*\s.*"

type NoSpaceInFileNamesCheck = ref object of Check

method id*(this: NoSpaceInFileNamesCheck): seq[string] =
  return @["nsifn", "nospace", "no_space", "no_space_in_file_names"]

method name*(this: NoSpaceInFileNamesCheck): string =
  return "No space in file names"

method description*(this: NoSpaceInFileNamesCheck): string =
  return """Checks that no file-names in the project contain white-space."""

method why*(this: NoSpaceInFileNamesCheck): string =
  return """This makes automatic processing of all the projects files
much easier and less error-prone."""

method sourcePath*(this: NoSpaceInFileNamesCheck): string =
  return tools.srcFileName()

method requirements*(this: NoSpaceInFileNamesCheck): CheckReqs =
  return {
    CheckReq.FilesListRec,
  }

method getSignificanceFactors*(this: NoSpaceInFileNamesCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.4,
    openness: 0.6, # makes the repo easier to work wiht on hte command-line and with scripts
    hardware: 0.0,
    quality: 0.8,
    machineReadability: 1.0,
    )

method run*(this: NoSpaceInFileNamesCheck, state: var State): CheckResult =
  let spacedFiles = filterPathsMatching(state.listFiles(), R_SPACE)
  return (if spacedFiles.len == 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    newCheckResult(
      CheckResultKind.Bad,
      CheckIssueSeverity.Low,
      some("Files with spaces in their names (Please consider renaming them):\n\n- " &
        spacedFiles.join("\n- ")
      )
    )
  )

proc createDefault*(): Check =
  NoSpaceInFileNamesCheck()
