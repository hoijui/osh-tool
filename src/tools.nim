# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# NOTE Comment these for shell script debugging
{.define(shellNoDebugOutput).}
{.define(shellNoDebugError).}
{.define(shellNoDebugCommand).}
{.define(shellNoDebugRuntime).}

import sequtils
import strutils
import strformat
import httpclient
import shell
import os
import re
import macros
import std/json
import std/logging
import std/streams
import std/strtabs
import std/tables
import std/tempfiles
import ./config

const PROJVAR_CMD = "projvar"
const MLE_CMD = "mle"
const OSH_DIR_STD_TOOL_CMD* = "osh-dir-std"
const DIR_STD_NAME* = "unixish"

type
  LinkOcc* = object
    srcFile*: string
    srcLine*: int
    srcColumn*: int
    target*: string
      ## link-path/-url
  LinkOccsCont = seq[LinkOcc]

macro importAll*(dir: static[string]): untyped =
  var bracket = newNimNode(nnkBracket)
  # let dir = "checks"
  for x in walkDir("./src/" & dir, true):
    if(x.kind == pcFile):
      let split = x.path.splitFile()
      if(split.ext == ".nim"):
        bracket.add ident(split.name)
  newStmtList(
    newNimNode(nnkImportStmt).add(
      newNimNode(nnkInfix).add(
        ident("/"),
        newNimNode(nnkPrefix).add(
          ident("/"),
          ident(dir)
    ),
    bracket
  )
    )
  )

macro registerAll*(dir: static[string]): untyped =
  var commands = newStmtList()
  for x in walkDir("./src/" & dir, true): # TODO Sort this first, to get a predictable order -- or altenratibvely, make the checks serf-order, and use an ordering data structure (i.e. TreeSet in Java)
    if(x.kind == pcFile):
      let split = x.path.splitFile()
      if(split.ext == ".nim"):
        commands.add(
          newNimNode(nnkCall).add(
            newNimNode(nnkDotExpr).add(
              ident("this"),
              ident("register"),
            ),
            newNimNode(nnkCall).add(
              newNimNode(nnkDotExpr).add(
                ident(split.name),
                ident("createDefault"),
              )
            )
          )
        )
  commands

proc download*(file: string, link: string, overwrite: bool = false) =
  if os.fileExists(file) and not overwrite:
    echo(fmt"WARN Not downloading '{link}'; File '{file}' already exists; leaving it as is. Use --force to overwrite.")
    return
  var client = newHttpClient()
  try:
    var file_h = open(file, fmWrite)
    defer: file_h.close()
    file_h.write(client.getContent(link))
    echo(fmt"INFO Compliance - downloaded '{link}' to '{file}'.")
  except IOError as err:
    echo(fmt"ERROR Failed to download '{link}' to '{file}': " & err.msg)

proc downloadTemplate*(config: RunConfig, file: string, link: string) =
  download(file, link, config.force)

proc matchFileName(filePath: string, regex: Regex): bool =
  let fileName = filePath.extractFilename()
  return match(fileName, regex)

proc filterPathsMatching*(filePaths: seq[string], regex: Regex): seq[string] =
  ## Returns a list of only the entries from ``filePaths``
  ## that match ``regex``.
  ## NOTE
  ## re"^.*README.*$"
  ## and
  ## re"README"
  ## are equal in function.
  return toSeq(filePaths.filterIt(match(it, regex)))

proc filterPathsMatchingFileName*(filePaths: seq[string], regex: Regex): seq[string] =
  ## Returns a list of only the entries from ``filePaths``
  ## of which the file name (last path segment) matches ``regex``.
  ## NOTE
  ## re"^.*README.*$"
  ## and
  ## re"README"
  ## are equal in function.
  return toSeq(filePaths.filterIt(matchFileName(it, regex)))

proc extractFileExts*(filePath: string, maxParts: int, toLower: bool = true) : seq[string] =
  let fileName = os.splitPath(filePath)[1]
  var exts: seq[string] = @[]
  var acum = ""
  var i = 0
  let parts = fileName.split('.')
  for pi in countdown(high(parts), 0):
    let part = parts[pi]
    if i >= maxParts:
      break;
    acum = part & acum
    if toLower:
      acum = acum.toLower()
    exts.add(acum)
    acum = '.' & acum
    i = i + 1
  exts

proc containsAny(big: seq[string], small: seq[string]): bool =
  for sEnt in small:
    if big.contains(sEnt):
      return true
  return false

proc filterByExtensions*(filePaths: seq[string], extensions: seq[string], maxParts: int = 1): seq[string] =
  ## Returns a list of only the entries from ``filePaths``
  ## of which the file extension ('.' separated) matches any in ``extensions``.
  ## ``maxParts`` should be set to the max number of parts of any of the file extensions in ``extensions``.
  ## "zip" is one part, "tar.gz" are two parts.
  return toSeq(filePaths.filterIt(containsAny(extensions, extractFileExts(it, maxParts))))

proc listFilesFS(dir: string): seq[string] =
  ## returns a recursive list of file names in ``dir``.
  return toSeq(os.walkDirRec(dir, relative = true))

proc canTreatAsGitRepo(dir: string): bool =
  ## Returns true if all of these are true:
  ## * the dir exists
  ## * the `git` executable is available
  ## * the dir is a git repo root
  let gitRepoDirOrFile = os.joinPath(dir, ".git")
  if not os.fileExists(gitRepoDirOrFile) and not os.dirExists(gitRepoDirOrFile):
    return false
  let res = shellVerbose:
    which git
  return res[1] == 0 # exit code

proc listFilesGit(dir: string): seq[string] =
  ## Returns a list of ((git tracked) + (untracked && un-git-ignored)) file names.
  ## which is the same as this BASH code:
  ## ( git -C "$dir" status --short | grep '^?' | cut -d\  -f2- && git -C "$dir" ls-files ) | sort -u
  var res = ""
  shellAssign:
    res = pipe:
      "(" git -C ($dir) status --short
      grep "^?"
      cut -d"\ " -f"2-" && git -C ($dir) "ls-files" ")"
      sort -u
  return toSeq(res.splitLines())

proc toolVersion*(binName: string, args: varargs[string]): string =
  var version = "-0.0.0"
  try:
    debug fmt"Trying to find version for tool '{binName}' run to end ..."
    let process = osproc.startProcess(
      command = binName,
      workingDir = "",
      args = args.toSeq(),
      env = newStringTable(), # nil => inherit from parent process
      options = {poUsePath}) # NOTE Add for debugging: poParentStreams
    process.inputStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    process.errorStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    let (lines, exCode) = process.readLines()
    process.close()
    debug fmt"'{binName}' version check done."
    if exCode == 0:
      let firstLine = lines[0]
      let words = firstLine.split(' ')
      version = if words.len() > 1:
        words[1]
      else:
        words[0]
      debug fmt"{binName} version: '{version}'"
    else:
      warn fmt"Failed to run '{binName}'; exit state was {exCode}"
  except OSError as err:
    warn fmt"Failed to run '{binName}'; make sure it is in your PATH: {err.msg}"
  return version

proc runProjvar*(projRoot: string) : TableRef[string, string] =
  try:
    var args = newSeq[string]()
    let outFilePath = genTempPath(fmt"osh-tool_{PROJVAR_CMD}_", ".json")
    args.add("--file-out=" & outFilePath)
    args.add("--raw-panic")
    args.add("--log-level=trace")
    debug fmt"Now running '{PROJVAR_CMD}' ..."
    let process = osproc.startProcess(
      command = PROJVAR_CMD,
      workingDir = projRoot,
      args = args,
      env = nil, # nil => inherit from parent process
      options = {poUsePath, poParentStreams}) # NOTE Add for debugging: poParentStreams
    debug "Waiting for 'projvar' run to end ..."
    process.inputStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    process.errorStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    let exCode = osproc.waitForExit(process)
    process.close()
    debug fmt"'{PROJVAR_CMD}' run done."
    if exCode == 0:
      let jsonRoot = parseJson(newFileStream(outFilePath), outFilePath)
      var vars = newTable[string, string]()
      echo jsonRoot.kind
      for (key, val) in jsonRoot.fields.pairs:
        vars[key] = val.getStr()
      return vars
    else:
      raise newException(IOError, fmt("""Failed to run '{PROJVAR_CMD}'; exit state was {exCode}"""))
  except OSError as err:
    raise newException(IOError, fmt("Failed to run '{PROJVAR_CMD}'; make sure it is in your PATH: {err.msg}"))

proc runOshDirStd*(projRoot: string, args: openArray[string], fileListing: seq[string]): string =
  debug fmt"Running {OSH_DIR_STD_TOOL_CMD} ..."
  try:
    let process = osproc.startProcess(
      command = OSH_DIR_STD_TOOL_CMD,
      workingDir = projRoot,
      args = args,
      env = nil,
      options = {poUsePath})
    let procStdin = process.inputStream()
    debug fmt"  {OSH_DIR_STD_TOOL_CMD}: Writing to stdin ..."
    for path in fileListing:
      procStdin.writeLine(path)
    debug fmt"  {OSH_DIR_STD_TOOL_CMD}: Close stdin (we supposedly should not do this manually, but apparently we have to!) ..."
    procStdin.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    debug fmt"  {OSH_DIR_STD_TOOL_CMD}: And in some cases, this is required to not hang (closing stderr) ... :/"
    process.errorStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    debug fmt"  {OSH_DIR_STD_TOOL_CMD}: Ask for exit code and stdout ..."
    let (lines, exCode) = process.readLines()
    process.close()
    debug fmt"  {OSH_DIR_STD_TOOL_CMD}: Run finnished; analyze results ..."
    if exCode == 0:
      debug fmt"  {OSH_DIR_STD_TOOL_CMD}: Process output ..."
      let jsonLines = lines.join("\n")
      debug fmt"  {OSH_DIR_STD_TOOL_CMD}: jsonLines:"
      debug jsonLines
      return jsonLines
    else:
      raise newException(IOError, fmt("""Failed to run '{OSH_DIR_STD_TOOL_CMD}'; exit state was {exCode}; output:\n{lines.join("\n")}"""))
  except OSError as err:
    raise newException(IOError, fmt("Failed to run '{OSH_DIR_STD_TOOL_CMD}'; make sure it is in your PATH: {err.msg}"))

proc extractMarkdownLinks*(config: RunConfig, mdFiles: seq[string]) : LinkOccsCont =
  try:
    var args = newSeq[string]()
    # let outFilePath = genTempPath(fmt"osh-tool_{MLE_CMD}_", ".json")
    # args.add("--result-file=" & outFilePath)
    args.add("--result-format=json")
    for mdFile in mdFiles:
      args.add(mdFile)
    debug fmt"Now running '{MLE_CMD}' ..."
    let process = osproc.startProcess(
      command = MLE_CMD,
      workingDir = config.projRoot,
      args = args,
      env = nil,
      options = {poUsePath}) # NOTE Add for debugging: poParentStreams
    process.inputStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    process.errorStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    let (lines, exCode) = process.readLines()
    process.close()
    debug fmt"'{MLE_CMD}' run done."
    if exCode == 0:
      var links = newSeq[LinkOcc]()
      if lines.len() > 0:
        let jsonRoot = parseJson(lines.join("\n"))
        # let jsonRoot = parseJson(newFileStream(outFilePath), $outFile)
        for linkNode in jsonRoot:
          let link = LinkOcc(
            srcFile: linkNode["src_file"].getStr(),
            srcLine: linkNode["src_line"].getInt(),
            srcColumn: linkNode["src_column"].getInt(),
            target: linkNode["trg_link"].getStr())
          links.add(link)
      return links
    else:
      raise newException(IOError, fmt("""Failed to run '{MLE_CMD}'; exit state was {exCode}; output:\n{lines.join("\n")}"""))
  except OSError as err:
    raise newException(IOError, fmt("Failed to run '{MLE_CMD}'; make sure it is in your PATH: {err.msg}"))

template srcFileName*: string =
  instantiationInfo(-1).filename

proc round*(factor: float32): string =
  ## Rounds a floating point number to exactly two digits,
  ## and returns it as a string,
  ## as this is the only way to ensure there are not more digits.
  formatFloat(factor, format=ffDecimal, precision=2)

proc toPercentStr*(factor: float32): string =
  ## Converts a factor (a float between `[0.0, 1.0]`)
  ## to a string representaiton of the same value as percentage,
  ## roudned to exactly 2 digits after the comma,
  ## and *excluding* the '%' sign.
  ## `assert_eq(toPercentStr(0.956), "95.60")`
  formatFloat(factor*100.0, format=ffDecimal, precision=2)

proc filterOutGenerated*(projRoot: string, unfiltered: seq[string]): seq[string] =
  try:
    let args = ["map", "--standard", DIR_STD_NAME]
    let jsonLines = runOshDirStd(projRoot, args, unfiltered)
    let jsonRoot = parseJson(jsonLines)
    for std in jsonRoot:
      if std["name"].getStr() == DIR_STD_NAME:
        let genLstJson = std["coverage"]["generated_content"]
        var genLst = newSeq[string]()
        for genJson in genLstJson:
          genLst.add(genJson.getStr())
        let filtered = unfiltered.filterIt(it notin genLst).toSeq
        return filtered
  except OSError as err:
    raise newException(IOError, fmt("Failed to filter out generated content: {err.msg}"))
  raise newException(IOError, fmt("Failed to filter out generated content obtained from '{OSH_DIR_STD_TOOL_CMD}'"))

proc listFiles*(dir: string): seq[string] =
  if canTreatAsGitRepo(dir):
    listFilesGit(dir)
  else:
    toSeq(listFilesFS(dir))

proc containsFilesWithSuffix*(dir: string, suffix: string,
    recursive: bool = true, ignore_case: bool = false): bool =
  ## Checks whether ``dir`` contains any files ending in ``suffix``,
  ## searchign recursively, and ignoring case.
  ## NOTE: Please supply a lower-case suffix!
  #when suffix != suffix.toLower():
  #  throw error
  if recursive:
    for file in os.walkDirRec(dir):
      let filePath = if ignore_case: file.toLower() else: file
      if filePath.endsWith(suffix):
        return true
  else:
    for file in os.walkDir(dir):
      let filePath = if ignore_case: file.path.toLower() else: file.path
      if filePath.endsWith(suffix):
        return true
  return false
