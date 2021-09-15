# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

from strutils import count, join
import random
import re
import options
from os import nil
import ../tools
import ../check
import ../state

const SOURCE_EXT_URL = "https://raw.githubusercontent.com/hoijui/file-extension-list/master/data/code"
const SOURCE_EXT_FILE = "source-extensions.txt" # TODO USe some fancy scheme to come up with this name; in ~/.cache/osh-tool/source-extension.txt on Linux, for example
var SOURCE_EXTENSIONS = none(seq[string])
var SOURCE_EXTENSIONS_MAX_PARTS = none(int)

randomize()

proc prepare(state: var State): CheckResult =
  if SOURCE_EXTENSIONS.isNone:
    if not os.fileExists(SOURCE_EXT_FILE):
      if state.config.offline:
        return CheckResult(error: some("List of source file extensions is not available locally, and offline mode prevents downloading it"))
      else:
        let tempExtsFile = os.joinPath(os.getTempDir(), "source_code_extensions_" & $rand(1000) & ".txt")
        download(tempExtsFile, SOURCE_EXT_URL)
        os.moveFile(tempExtsFile, SOURCE_EXT_FILE)
    var tempSourceExts: seq[string] = @[]
    var maxParts = 0
    for line in lines SOURCE_EXT_FILE:
      let ext = line.replace(re"\s+%$", "")
      maxParts = max(maxParts, ext.count('.') + 1)
      tempSourceExts.add(ext)
    SOURCE_EXTENSIONS = some(tempSourceExts)
    SOURCE_EXTENSIONS_MAX_PARTS = some(maxParts)

type NoSourceFilesInRootCheck = ref object of Check

method name*(this: NoSourceFilesInRootCheck): string =
  return "No sources in the root directory"

method run*(this: NoSourceFilesInRootCheck, state: var State): CheckResult =
  let prep_state = prepare(state)
  if prep_state.error.isSome():
    return prep_state
  let rootSourceFiles = filterByExtensions(state.listFilesL1(), SOURCE_EXTENSIONS.get(), SOURCE_EXTENSIONS_MAX_PARTS.get())
  # TODO Only fail if more then 2 files with the same extension are found
  let error = (if rootSourceFiles.len == 0:
    none(string)
  else:
    some("Source files found in root. Please consider moving them into a sub directory:\n\t" &
        rootSourceFiles.join("\n\t"))
  )
  return CheckResult(error: error)

proc createDefault*(): Check =
  NoSourceFilesInRootCheck()
