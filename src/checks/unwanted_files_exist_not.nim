# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
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

method description*(this: UnwantedFilesExistNotCheck): string =
  return """Checks that no unwanted files are part of the project. \
These could be backups, caches, IDE/platform specific, and so on."""

method requirements*(this: UnwantedFilesExistNotCheck): CheckReqs =
  return {
    CheckReq.FilesListRec,
  }

method getRatingFactors*(this: UnwantedFilesExistNotCheck): CheckRelevancy =
  return CheckRelevancy(
    weight: 0.5,
    openness: 0.6, # because the repo could be less heavy and thus easier to host/share/exchange
    hardware: 0.0,
    quality: 0.5,
    machineReadability: 0.3,
    )

method run*(this: UnwantedFilesExistNotCheck, state: var State): CheckResult =
  let unwantedFiles = filterPathsMatchingFileName(state.listFiles(), R_UNWANTED_FILES)
  return (if unwantedFiles.len == 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    newCheckResult(
      CheckResultKind.Bad,
      CheckIssueImportance.Middle,
      some("Unwanted files found. Please consider removing them:\n\n- " & unwantedFiles.join("\n- "))
    )
  )

proc createDefault*(): Check =
  UnwantedFilesExistNotCheck()
