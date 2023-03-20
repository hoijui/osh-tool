# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import os
import system
import ../check
import ../config
import ../state
import ../tools
import ../file_ext_meta
import std/tables

const EXT_FILE = "resources/osh-file-types/file_extension_formats-pcb.csv"
const FROM_THIS_FILE_TO_PROJ_ROOT = "../.."
const EXT_FILE_REL = FROM_THIS_FILE_TO_PROJ_ROOT & "/" & EXT_FILE
const EXT_FILE_ABS = staticExec("pwd") & "/" & EXT_FILE_REL

static:
  if not fileExists(EXT_FILE_ABS):
    echo "\nError: Required file does not exist: " & EXT_FILE &
      "\n\tMaybe you forgot to checkout git submodules? (`git submodule update --init --recursive`)\n"
parseInjectExtsAndMap(staticRead(EXT_FILE_ABS))

type CleanElectronicsFilesCheck = ref object of Check

method name*(this: CleanElectronicsFilesCheck): string =
  return "Clean electronics files"

method description*(this: CleanElectronicsFilesCheck): string =
  return """Checks that the contained Electronics blueprint files - \
Schematics and PCB designs - \
if any, \
use an open format, \
are text-based \
and are actual source files (vs generated)."""

method why*(this: CleanElectronicsFilesCheck): string =
  return """- open format:
  This is good for collaboration:
  It is legal and technically easier to create viewers and editors,
  and it is much more likley that there already are or will be viewers and editors
  for such formats,
  which are free themselfs.
- text-based:
  This is good for versioning with a [version control system](https://en.wikipedia.org/wiki/Version_control),
  e.g. git,
  which makes collaborating and sharing of a design easier.
- source files:
  This is required for being Open **Source** in the first place."""

method sourcePath*(this: CleanElectronicsFilesCheck): string =
  return tools.srcFileName()

method requirements*(this: CleanElectronicsFilesCheck): CheckReqs =
  return {
    CheckReq.FilesListRecNonGen,
  }

method getSignificanceFactors*(this: CleanElectronicsFilesCheck): CheckSignificance =
  return CheckSignificance(
    weight: 1.0,
    openness: 1.0,
    hardware: 1.0,
    quality: 0.5,
    machineReadability: 1.0,
    )

method run*(this: CleanElectronicsFilesCheck, state: var State): CheckResult =
  extCheckRun(state, state.config.electronics, FILE_EXTENSIONS, FILE_EXTENSIONS_MAX_PARTS, FILE_EXTENSIONS_MAP)

proc createDefault*(): Check =
  CleanElectronicsFilesCheck()
