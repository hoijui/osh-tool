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

let R_UNWANTED_FILES = re"^(\.DS_Store|\.DS_Store.|\._*|\.Spotlight-V100|\.Trashes|ehthumbs\.db|Thumbs\.db|.*~|.*\.orig|.*\.swp|.*\.kate-swp|.*\.fcstd1)$"

type UnwantedFilesExistNotCheck = ref object of Check

method name*(this: UnwantedFilesExistNotCheck): string =
  return "No unwanted files"

method run*(this: UnwantedFilesExistNotCheck, state: var State): CheckResult =
  let unwantedFiles = filterPathsMatchingFileName(state.listFiles(), R_UNWANTED_FILES)
  return (if unwantedFiles.len == 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    newCheckResult(
      CheckResultKind.Bad,
      CheckIssueWeight.Middle,
      some("Unwanted files found. Please consider removing them:\n\t" & unwantedFiles.join("\n\t"))
    )
  )

proc createDefault*(): Check =
  UnwantedFilesExistNotCheck()
