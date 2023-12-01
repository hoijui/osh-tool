# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

from strutils import join
import options
import re
import tables
import ../check
import ../check_config
import ../state
import ../util/fs

const IDS = @["nuf", "nounwanted", "no_unwanted", "no_unwanted_files"]
const ID = IDS[0]
let R_UNWANTED_FILES = re"^(\.DS_Store|\.DS_Store.|\._*|\.Spotlight-V100|\.Trashes|ehthumbs\.db|Thumbs\.db|.*~|.*\.orig|.*\.swp|.*\.kate-swp|.*\.fcstd1)$"

type UnwantedFilesExistNotCheck = ref object of Check
type UnwantedFilesExistNotCheckGenerator = ref object of CheckGenerator

method name*(this: UnwantedFilesExistNotCheck): string =
  return "No unwanted files"

method description*(this: UnwantedFilesExistNotCheck): string =
  return """Checks that no unwanted files are part of the project. \
These could be backups, caches, IDE/platform specific, and so on."""

method why*(this: UnwantedFilesExistNotCheck): string =
  return """These files, present in the repo, could cause these issues and inconvieniences:

- potentially inflating the repositories size
- mess up local settings (e.g. local cache paths of an IDE) by one designer
  on an other deginers machine
- make the project appear less clean
- make the project maintainers look like amateurs to seasoned Open Source people
- confuse people, as they are around, yet seem to have no usefulness"""

method sourcePath*(this: UnwantedFilesExistNotCheck): string =
  return fs.srcFileName()

method requirements*(this: UnwantedFilesExistNotCheck): CheckReqs =
  return {
    CheckReq.FilesListRec,
  }

method getSignificanceFactors*(this: UnwantedFilesExistNotCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.5,
    openness: 0.6, # because the repo could be less heavy and thus easier to host/share/exchange
    hardware: 0.0,
    quality: 0.5,
    machineReadability: 0.3,
    )

method run*(this: UnwantedFilesExistNotCheck, state: var State): CheckResult =
  let config = state.config.checks[ID]
  let unwantedFiles = filterPathsMatchingFileName(state.listFiles(), R_UNWANTED_FILES)
  return (if unwantedFiles.len == 0:
    newCheckResult(config, CheckResultKind.Perfect)
  else:
    newCheckResult(
      config,
      CheckResultKind.Bad,
      CheckIssueSeverity.Middle,
      some("Unwanted files found. Please consider removing them:\n\n- " & unwantedFiles.join("\n- "))
    )
  )

method id*(this: UnwantedFilesExistNotCheckGenerator): seq[string] =
  return IDS

method generate*(this: UnwantedFilesExistNotCheckGenerator, config: CheckConfig = newCheckConfig(ID)): Check =
  this.ensureNonConfig(config)
  UnwantedFilesExistNotCheck()

proc createGenerator*(): CheckGenerator =
  UnwantedFilesExistNotCheckGenerator()
