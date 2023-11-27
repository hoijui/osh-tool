# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import sequtils
import strutils
import strformat
import shell
import os
import std/json
import std/logging
import std/sets
import std/streams
import std/strtabs
import std/tables
import std/tempfiles

const PROJVAR_CMD = "projvar"
const MLE_CMD = "mle"
const OSH_DIR_STD_TOOL_CMD* = "osh-dir-std"
const DIR_STD_NAME* = "unixish"
const POSSIBLE_PV_PROJ_PREFIX_KEYS = [
  # "BUILD_HOSTING_URL",
  "REPO_RAW_VERSIONED_PREFIX_URL",
  "REPO_VERSIONED_DIR_PREFIX_URL",
  # "REPO_VERSIONED_FILE_PREFIX_URL",
  "REPO_WEB_URL",
]

type
  LinkOcc* = object
    srcFile*: string
    srcLine*: int
    srcColumn*: int
    target*: string
      ## link-path/-url
  LinkOccsCont = seq[LinkOcc]

proc toolVersion*(binName: string, args: varargs[string]): string =
  var version = "-0.0.0"
  try:
    debug fmt"Trying to find version for tool '{binName}' ..."
    let parent_env = true # This is required for 'reuse', at least
    let env = if parent_env:
        nil # => Inherit from parent process
      else:
        newStringTable() # => Use an empty environment
    let process = osproc.startProcess(
      command = binName,
      workingDir = "",
      args = args.toSeq(),
      env = env,
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
  let debug = false
  try:
    var args = newSeq[string]()
    var options = {poUsePath};
    let outFilePath = genTempPath(fmt"osh-tool_{PROJVAR_CMD}_", ".json")
    args.add("--file-out=" & outFilePath)
    args.add("--none")
    args.add("--raw-panic")
    options.incl(poUsePath)
    if debug:
      args.add("--log-level=trace")
      args.add("--show-all-retrieved=/tmp/projvar_oshTool_showAllRetrieved.md")
      options.incl(poParentStreams)
      debug fmt"'{PROJVAR_CMD}' CWD: '{projRoot}'"
      let argsStr = args.join(" ")
      debug fmt"'{PROJVAR_CMD}' args: {argsStr}"
    debug fmt"Now running '{PROJVAR_CMD}' ..."
    let process = osproc.startProcess(
      command = PROJVAR_CMD,
      workingDir = projRoot,
      args = args,
      env = nil, # nil => inherit from parent process
      options = options)
    debug fmt"Waiting for '{PROJVAR_CMD}' run to end ..."
    if not debug:
      # NOTE **Essential** - These prevent hanging/freezing when reading stdout below
      process.inputStream.close()
      process.errorStream.close()
    let exCode = osproc.waitForExit(process)
    process.close()
    debug fmt"'{PROJVAR_CMD}' run done."
    if exCode == 0:
      debug fmt"'{PROJVAR_CMD}' ran successsfully."
      if debug:
        os.copyFileWithPermissions(outFilePath, "/tmp/projvar_out_oshTool_fixed_debugging.json")
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
    debug fmt"Now running '{OSH_DIR_STD_TOOL_CMD}' ..."
    let process = osproc.startProcess(
      command = OSH_DIR_STD_TOOL_CMD,
      workingDir = projRoot,
      args = args,
      env = nil,
      options = {poUsePath})
    debug fmt"Waiting for '{OSH_DIR_STD_TOOL_CMD}' run to end ..."
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

proc createProjectPrefixes*(projRoot: string, projVars: TableRef[string, string]): seq[string] =
  debug "Projvar fetched vars:"
  if getLogFilter() == lvlDebug or getLogFilter() == lvlAll:
    for k, v in projVars:
      debug fmt"  {k}: '{v}'"
  var projPrefixesSet = newSeq[string]()
  projPrefixesSet.add(if projRoot == "." or projRoot == "": "./" else: projRoot)
  projPrefixesSet.add(os.absolutePath(projRoot))
  for prefixVar in POSSIBLE_PV_PROJ_PREFIX_KEYS:
    if projVars.contains(prefixVar):
      projPrefixesSet.add(projVars[prefixVar])
  # Removes duplicates
  let projPrefixes = projPrefixesSet.toHashSet().toSeq()
  debug "Project prefixes:"
  debug projPrefixes.join("\n\t")
  return projPrefixes

proc extractMarkdownLinks*(projRoot: string, mdFiles: seq[string]) : LinkOccsCont =
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
      workingDir = projRoot,
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
