# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import strutils
import options
import macros
import system
import regex
import ../tools
import ../check
import ../state

const SOURCE_EXT_FILE = "data/file-extension-list/data/categories/code.csv"
const FROM_THIS_FILE_TO_PROJ_ROOT = "../.."

# This macro reads the file SOURCE_EXT_FILE at compile time,
# and parses the list of file extensions into a list.
# That list the ngets written into a const variable availabel at run-time
# under the name `SOURCE_EXTENSIONS`.
# The `const SOURCE_EXTENSIONS_MAX_PARTS` is an integer,
# indicating the max number of parts in the above list,
# when splitting each extension with '.'.
macro parseInjectExts(): untyped =
  var sourceExts: seq[string] = @[]
  var maxParts = 0

  let sources_list = staticRead(FROM_THIS_FILE_TO_PROJ_ROOT & "/" & SOURCE_EXT_FILE)
  for line in sources_list.split('\n'):
    # retain only the first CSV column
    let ext = line.replace(re",.*$", "")
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

parseInjectExts()

type NoSourceFilesInRootCheck = ref object of Check

method name*(this: NoSourceFilesInRootCheck): string =
  return "No sources in root"

method requirements*(this: Check): CheckReqs =
  return {
    CheckReq.FilesListL1,
  }

method run*(this: NoSourceFilesInRootCheck, state: var State): CheckResult =
  let rootSourceFiles = filterByExtensions(state.listFilesL1(), SOURCE_EXTENSIONS, SOURCE_EXTENSIONS_MAX_PARTS)
  # TODO Only fail if more then 2 files with the same extension are found
  return (if rootSourceFiles.len == 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    newCheckResult(
      CheckResultKind.Bad,
      CheckIssueWeight.Light,
      some(
        "Source files found in root. Please consider moving them into a sub directory:\n\n* " &
        rootSourceFiles.join("\n* ")
      )
    )
  )

proc createDefault*(): Check =
  NoSourceFilesInRootCheck()
