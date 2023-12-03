# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# NOTE Comment these for shell script debugging
{.define(shellNoDebugOutput).}
{.define(shellNoDebugError).}
{.define(shellNoDebugCommand).}
{.define(shellNoDebugRuntime).}

import os
import shell
import sequtils
import std/json
import strutils
import strformat
import re
import ./leightweight
import ./run

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

template srcFileName*: string =
  ## Returns the whole file name (without the directory).
  instantiationInfo(-1).filename

template srcFileNameBase*: string =
  ## Returns the file name without the extension.
  instantiationInfo(-1).filename[0 .. ^5]

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
