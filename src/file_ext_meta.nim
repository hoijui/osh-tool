# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import macros
import std/strscans
import std/tables
import strformat
import strutils
import system
import ./check
import ./state
import ./util/leightweight
import ./util/fs

type
  Duo* {.size: sizeof(cint).} = enum
    Good = 1
    Bad = 2
  DuoSet* = set[Duo]

proc toNum*(flags: DuoSet): int = #cast[cint](flags) # NOTE This is much shorter, but does not work at compile-time :/
  var num = 0
  for flag in flags:
    num = num + ord(flag)
  return num
proc toDuoSet*(bits: int): DuoSet = cast[DuoSet](bits)

template parseTriValue(value: string, name, goodVal: string, badVal: string, noneVal: string, bothVal: string, lineNum: int, column: int): int =
  if value == goodVal:
    toNum({Duo.Good})
  elif value == badVal:
    toNum({Duo.Bad})
  elif value == noneVal:
    toNum({})
  elif value == bothVal:
    toNum({Duo.Good, Duo.Bad})
  else:
    echo("Invalid tri-value: '" & name & "', possible values: [" & goodVal & ", " & badVal & ", " & noneVal & "], value: '" & value & "'")
    echo "line:"
    echo lineNum + 1 # + 1 because humans and text editors start counting at 1
    echo "column:"
    echo column
    quit 33 + 1 # + 1 because humans and text editors start counting at 1

macro parseInjectExtsAndMap*(extsCsvContent: static[string]): untyped =
  ## This macro takes the CSV content supplied as an argument at compile time,
  ## parses the file extensions into a list,
  ## and creates a mapping from each extension to the other entires in the table (hard-coded).
  ## The extensions list gets written into a const variable available at run-time
  ## under the name `FILE_EXTENSIONS`.
  ## The `const FILE_EXTENSIONS_MAX_PARTS` is an integer,
  ## indicating the max number of parts in the above list,
  ## when splitting each extension with '.'.
  ## Finally, `FILE_EXTENSIONS_MAP` contains the aforementioned mapping
  ## from "ext" to `(open, text, source)`.
  var exts: seq[(string, int, int, int, string)] = @[]
  var maxParts = 0

  var lineNum = 0
  for line in extsCsvContent.splitLines():
    if lineNum == 0:
      # skip the header-/title-row
      lineNum = lineNum + 1
      continue
    if line.isEmptyOrWhitespace():
      break
    var ext: string
    var openStr: string
    var textStr: string
    var sourceStr: string
    var name: string
    if not scanf(line, "$*,$*,$*,$*,$*", ext, openStr, textStr, sourceStr, name):
      # debugError "Invalid line format", lineNum, line # TODO FIXME Do not know how to raise an error at compile-time :/
      echo("Failed to scan extensions line, should be 'string,string,string,string,string', but is: '" & line & "', on line:")
      echo lineNum
      quit 66
    if not ((ext == "pdf") or (ext == "html")):
      let open = parseTriValue(openStr, "open?", "open", "proprietary", "unknown", "both", lineNum, 1)
      let text = parseTriValue(textStr, "text?", "text", "binary", "unknown", "both", lineNum, 2)
      let source = parseTriValue(sourceStr, "source?", "source", "export", "unknown", "both", lineNum, 3)
      maxParts = max(maxParts, ext.count('.') + 1)
      if not ext.isEmptyOrWhitespace():
        exts.add((ext.toLower(), open, text, source, name))
    # NOTE Use this to see how code can be created in AST (required below)
    # dumpAstGen:
      # const one5 = (1, 3, 4)
    lineNum = lineNum + 1

  result = newStmtList()
  let listStmt = newNimNode(nnkBracket)
  let tableStmt = newNimNode(nnkTableConstr)
  for (ext, open, text, source, name) in exts:
    listStmt.add(newStrLitNode(ext))

    tableStmt.add(
      nnkExprColonExpr.newTree(
        newStrLitNode(ext),
        nnkTupleConstr.newTree(
          newLit(open),
          newLit(text),
          newLit(source),
          newStrLitNode(name),
        )
      )
    )

  result.add(
    newNimNode(nnkConstSection).add(
      newNimNode(nnkConstDef).add(
        newIdentNode("FILE_EXTENSIONS"),
        newNimNode(nnkBracketExpr).add(
          ident("seq"),
          newIdentNode("string"),
        ),
        newNimNode(nnkPrefix).add(
          ident("@"),
          listStmt
        )
      )
    ),

    nnkConstSection.newTree(
      nnkConstDef.newTree(
        newIdentNode("FILE_EXTENSIONS_MAP"),
        newEmptyNode(),
        nnkDotExpr.newTree(
          tableStmt,
          newIdentNode("toTable")
        )
      )
    ),

    newNimNode(nnkConstSection).add(
      newNimNode(nnkConstDef).add(
        ident("FILE_EXTENSIONS_MAX_PARTS"),
        ident("int"),
        newIntLitNode(maxParts)
      )
    )
  )
  # Use this for debugging:
  #echo toStrLit(result)

proc extCheckRun*(state: var State, checkId: string, configVal: YesNoAuto, fileExts: seq[string], fileExtsMaxParts: int, fileExtsMap: Table[string, (int, int, int, string)]): CheckResult =
  let config = state.config.checks[checkId]
  if configVal == YesNoAuto.No:
    return newCheckResult(config, CheckResultKind.Inapplicable, CheckIssueSeverity.Low, some("Configured to always skip"))
  let matchingFiles = filterByExtensions(state.listFilesNonGenerated(), fileExts, fileExtsMaxParts)
  if configVal == YesNoAuto.Auto and matchingFiles.len() == 0:
    return newCheckResult(config, CheckResultKind.Inapplicable, CheckIssueSeverity.Low, some("No relevant files were found"))

  var issues: seq[CheckIssue] = @[]
  if matchingFiles.len() == 0:
    issues.add(
      CheckIssue(
        severity: CheckIssueSeverity.Middle,
        msg: some(fmt"No matching file types found")
      )
    )
  for mFile in matchingFiles:
    let exts = extractFileExts(mFile, fileExtsMaxParts)
    for ext in exts:
      if fileExtsMap.hasKey(ext):
        let (open, text, source, name) = fileExtsMap[ext]
        var fileIssues: seq[string] = @[]
        if not (Duo.Good in toDuoSet(open)):
          fileIssues.add("not Open")
        if not (Duo.Good in toDuoSet(text)):
          fileIssues.add("not text-based")
        if not (Duo.Good in toDuoSet(source)):
          fileIssues.add("generated/not source")
        if fileIssues.len() > 0:
          issues.add(
            CheckIssue(
              severity: CheckIssueSeverity.Low,
              msg: some(fmt"File-format issue(s) with '{mFile}' (assumed type: {name}): " & fileIssues.join(", "))
            )
          )

  return (if issues.len == 0:
    newCheckResult(config, CheckResultKind.Perfect)
  else:
    CheckResult(
        config: config,
        kind: CheckResultKind.Bad,
        issues: issues
      )
  )
