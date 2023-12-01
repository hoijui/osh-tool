# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import sequtils
import strutils
import options
import os
import macros
import system
import regex
import ../check
import ../check_config
import ../state
import ../util/fs

const IDS = @["nsfir", "no_sources_in_root", "no_source_files_in_root"]
const ID = IDS[0]
const EXT_FILE = "resources/file-extension-list/data/categories/code.csv"
const FROM_THIS_FILE_TO_PROJ_ROOT = "../.."
const EXT_FILE_REL = FROM_THIS_FILE_TO_PROJ_ROOT & "/" & EXT_FILE
const EXT_FILE_ABS = staticExec("pwd") & "/" & EXT_FILE_REL

macro parseInjectExts(): untyped =
  ## This macro reads the file SOURCE_EXT_FILE at compile time,
  ## and parses the list of file extensions into a list.
  ## That list the ngets written into a const variable availabel at run-time
  ## under the name `SOURCE_EXTENSIONS`.
  ## The `const SOURCE_EXTENSIONS_MAX_PARTS` is an integer,
  ## indicating the max number of parts in the above list,
  ## when splitting each extension with '.'.
  var sourceExts: seq[string] = @[]
  var maxParts = 0

  let sources_list = staticRead(EXT_FILE_REL)
  for line in sources_list.split('\n'):
    # retain only the first CSV column
    let ext = line.replace(re2",.*$", "")
    maxParts = max(maxParts, ext.count('.') + 1)
    if not ext.isEmptyOrWhitespace():
      sourceExts.add(ext)

  result = newStmtList()
  let listStmt = newNimNode(nnkBracket)
  for ext in sourceExts:
    listStmt.add(newStrLitNode(ext))
  result.add(
    newNimNode(nnkConstSection).add(
      newNimNode(nnkConstDef).add(
        ident("SOURCE_EXTENSIONS"),
        newNimNode(nnkBracketExpr).add(
          ident("seq"),
          ident("string")
        ),
        newNimNode(nnkPrefix).add(
          ident("@"),
          listStmt
        )
      )
    ),
    newNimNode(nnkConstSection).add(
      newNimNode(nnkConstDef).add(
        ident("SOURCE_EXTENSIONS_MAX_PARTS"),
        ident("int"),
        newIntLitNode(maxParts)
      )
    )
  )
  # echo toStrLit(result)

static:
  if not fileExists(EXT_FILE_ABS):
    echo "\nError: Required file does not exist: " & EXT_FILE &
      "\n\tMaybe you forgot to checkout git submodules? (`git submodule update --init --recursive`)\n"
parseInjectExts()

type NoSourceFilesInRootCheck = ref object of Check
type NoSourceFilesInRootCheckGenerator = ref object of CheckGenerator

method name*(this: NoSourceFilesInRootCheck): string =
  return "No sources in root"

method description*(this: NoSourceFilesInRootCheck): string =
  return """Checks that no source files appear in the root dir of the project. \
Make sure to put them all into sub-directories, for example `src/`."""

method why*(this: NoSourceFilesInRootCheck): string =
  return """Makes the Repo look more clean and more friendly,
especially for non-coding people
that might just wnat to browse or edit the documentation."""

method sourcePath*(this: NoSourceFilesInRootCheck): string =
  return fs.srcFileName()

method requirements*(this: NoSourceFilesInRootCheck): CheckReqs =
  return {
    CheckReq.FilesListL1,
  }

method getSignificanceFactors*(this: NoSourceFilesInRootCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.1,
    # makes the repo look less cluttered,
    # and thus more friendly and less scarry
    # -> beter for collaboration/openness
    openness: 0.6,
    hardware: 0.0,
    quality: 0.8,
    machineReadability: 0.0,
    )

method run*(this: NoSourceFilesInRootCheck, state: var State): CheckResult =
  let rootSourceFiles = filterByExtensions(
    state.listFilesL1(),
    SOURCE_EXTENSIONS,
    SOURCE_EXTENSIONS_MAX_PARTS).filter(
      proc(item: string): bool =
        # This removes DOT-files from the list,
        # which usually have a fixed location and file-name
        # under which they have to be available,
        # so the repo maintainer does not have the option to move them.
        not item.startsWith('.')
    )
  # TODO Only fail if more then 2 files with the same extension are found
  return (if rootSourceFiles.len == 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    newCheckResult(
      CheckResultKind.Bad,
      CheckIssueSeverity.Low,
      some(
        "Source files found in root. Please consider moving them into a sub directory:\n\n- " &
        rootSourceFiles.join("\n- ")
        # TODO Rather make one issue per each rootSourceFiles instead
      )
    )
  )

method id*(this: NoSourceFilesInRootCheckGenerator): seq[string] =
  return IDS

method generate*(this: NoSourceFilesInRootCheckGenerator, config: CheckConfig = CheckConfig(id: this.id()[0], json: none[string]())): Check =
  this.ensureNonConfig(config)
  NoSourceFilesInRootCheck()

proc createGenerator*(): CheckGenerator =
  NoSourceFilesInRootCheckGenerator()
