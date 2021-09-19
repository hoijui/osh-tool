# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

from strutils import join
import re
import options
import ../tools
import ../check
import ../state

## Check: Remove OS & Application generated backup and cache files
let R_SPACE = re".*\s.*"

type NoSpaceInFileNamesCheck = ref object of Check

method name*(this: NoSpaceInFileNamesCheck): string =
  return "No space in file names"

method run*(this: NoSpaceInFileNamesCheck, state: var State): CheckResult =
  let spacedFiles = filterPathsMatching(state.listFiles(), R_SPACE)
  let error = (if spacedFiles.len == 0:
    none(string)
  else:
    some("Files with spaces in their names (Please consider renaming them):\n\t" &
        spacedFiles.join("\n\t"))
  )
  return CheckResult(error: error)

proc createDefault*(): Check =
  NoSpaceInFileNamesCheck()
