# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import system
import ../check
import ../config
import ../state
import ../file_ext_meta
import std/tables

const EXT_FILE = "resources/osh-file-types/file_extension_formats-pcb.csv"
const FROM_THIS_FILE_TO_PROJ_ROOT = "../.."

parseInjectExtsAndMap(staticRead(FROM_THIS_FILE_TO_PROJ_ROOT & "/" & EXT_FILE))

type CleanElectronicsFilesCheck = ref object of Check

method name*(this: CleanElectronicsFilesCheck): string =
  return "Clean electronics files"

method requirements*(this: CleanElectronicsFilesCheck): CheckReqs =
  return {
    CheckReq.FilesListRec,
  }

method run*(this: CleanElectronicsFilesCheck, state: var State): CheckResult =
  extCheckRun(state, state.config.electronics, FILE_EXTENSIONS, FILE_EXTENSIONS_MAX_PARTS, FILE_EXTENSIONS_MAP)

proc createDefault*(): Check =
  CleanElectronicsFilesCheck()
