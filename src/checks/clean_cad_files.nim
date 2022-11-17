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

const EXT_FILE = "resources/osh-file-types/file_extension_formats-cad.csv"
const FROM_THIS_FILE_TO_PROJ_ROOT = "../.."

parseInjectExtsAndMap(staticRead(FROM_THIS_FILE_TO_PROJ_ROOT & "/" & EXT_FILE))

type CleanCadFilesCheck = ref object of Check

method name*(this: CleanCadFilesCheck): string =
  return "Clean CAD files"

method description*(this: CleanCadFilesCheck): string =
  return """Checks that the Mechanical design files - \
Computer Aided Design (CAD) files - \
if any, \
use an open format (good for collaboration), \
are text-based (good for versioning with e.g. git) \
and are actual source files, instead of generated \
(which is required for being open *source*)."""

method requirements*(this: CleanCadFilesCheck): CheckReqs =
  return {
    CheckReq.FilesListRec,
  }

method run*(this: CleanCadFilesCheck, state: var State): CheckResult =
  extCheckRun(state, state.config.mechanics, FILE_EXTENSIONS, FILE_EXTENSIONS_MAX_PARTS, FILE_EXTENSIONS_MAP)

proc createDefault*(): Check =
  CleanCadFilesCheck()
