# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import os
import std/tables
import system
import ../check
import ../check_config
import ../state
import ../util/fs
import ../file_ext_meta

const IDS = @["ccf", "ccadf", "clean_cad_files"]
const ID = IDS[0]
const EXT_FILE = "resources/osh-file-types/res/data/cad.csv"
const FROM_THIS_FILE_TO_PROJ_ROOT = "../.."
const EXT_FILE_REL = FROM_THIS_FILE_TO_PROJ_ROOT & "/" & EXT_FILE
const EXT_FILE_ABS = staticExec("pwd") & "/" & EXT_FILE_REL

static:
  if not fileExists(EXT_FILE_ABS):
    echo "\nError: Required file does not exist: " & EXT_FILE &
      "\n\tMaybe you forgot to checkout git submodules? (`git submodule update --init --recursive`)\n"
parseInjectExtsAndMap(staticRead(EXT_FILE_REL))

type CleanCadFilesCheck = ref object of Check
type CleanCadFilesCheckGenerator = ref object of CheckGenerator

method name*(this: CleanCadFilesCheck): string =
  return "Clean CAD files"

method description*(this: CleanCadFilesCheck): string =
  return """Checks that the Mechanical design files - \
Computer Aided Design (CAD) files - \
if any, \
use an open format, \
are text-based \
and are actual source files (vs generated)."""

method why*(this: CleanCadFilesCheck): string =
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

method sourcePath*(this: CleanCadFilesCheck): string =
  return fs.srcFileName()

method requirements*(this: CleanCadFilesCheck): CheckReqs =
  return {
    CheckReq.FilesListRecNonGen,
  }

method getSignificanceFactors*(this: CleanCadFilesCheck): CheckSignificance =
  return CheckSignificance(
    weight: 1.0,
    openness: 1.0,
    hardware: 1.0,
    quality: 0.5,
    machineReadability: 1.0,
    )

method run*(this: CleanCadFilesCheck, state: var State): CheckResult =
  extCheckRun(state, state.config.mechanics, FILE_EXTENSIONS, FILE_EXTENSIONS_MAX_PARTS, FILE_EXTENSIONS_MAP)

method id*(this: CleanCadFilesCheckGenerator): seq[string] =
  return IDS

method generate*(this: CleanCadFilesCheckGenerator, config: CheckConfig = CheckConfig(id: this.id()[0], json: none[string]())): Check =
  this.ensureNonConfig(config)
  CleanCadFilesCheck()

proc createGenerator*(): CheckGenerator =
  CleanCadFilesCheckGenerator()
