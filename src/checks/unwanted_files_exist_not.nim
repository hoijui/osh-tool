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

let R_UNWANTED_FILES = re"^(\.DS_Store|\.DS_Store.|\._*|\.Spotlight-V100|\.Trashes|ehthumbs\.db|Thumbs\.db|.*~|.*\.orig|.*\.swp|.*\.kate-swp|.*\.fcstd1)$"

type UnwantedFilesExistNotCheck = ref object of Check

method name*(this: UnwantedFilesExistNotCheck): string =
  return "Unwanted (generated, backup, cache, ...) files do not exist"

method run*(this: UnwantedFilesExistNotCheck, state: var State): CheckResult =
  let unwantedFiles = filterPathsMatchingFileName(state.listFiles(), R_UNWANTED_FILES)
  let error = (if unwantedFiles.len == 0:
    none(string)
  else:
    some("Unwanted files found. Please consider removing them:\n\t" &
        unwantedFiles.join("\n\t"))
  )
  return CheckResult(error: error)

proc createDefault*(): Check =
  UnwantedFilesExistNotCheck()
