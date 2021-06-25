# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

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
import ./config

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
  for x in walkDir("./src/" & dir, true):
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
                ident("createDefault")
              )
            )
          )
        )
  commands

proc downloadTemplate*(config: RunConfig, file: string, link: string) =
  if os.fileExists(file) and not config.force:
    stderr.writeLine("File '{file}' already exists, leaving it as is. Use --force to overwrite.")
    return
  var client = newHttpClient()
  try:
    var file_h = open(file, fmWrite)
    defer: file_h.close()
    file_h.write(client.getContent(link))
    echo(fmt"Success - downloaded template to '{file}'.")
  except IOError as err:
    stderr.writeLine("Failed to download template to '{file}': " & err.msg)

proc matchFileName(filePath: string, regex: Regex): bool =
  let fileName = filePath.extractFilename()
  return match(fileName, regex)

proc filterPathsMatching*(filePaths: seq[string], regex: Regex): seq[string] =
  ## Returns a list of of only the entries from ``filePaths``
  ## that match ``regex``.
  ## NOTE
  ## re"^.*README.*$"
  ## and
  ## re"README"
  ## are equal in function.
  return toSeq(filePaths.filterIt(match(it, regex)))

proc filterPathsMatchingFileName*(filePaths: seq[string], regex: Regex): seq[string] =
  ## Returns a list of of only the entries from ``filePaths``
  ## of which the file name (last path segment) matches ``regex``.
  ## NOTE
  ## re"^.*README.*$"
  ## and
  ## re"README"
  ## are equal in function.
  return toSeq(filePaths.filterIt(matchFileName(it, regex)))

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
  ## ( git status --short| grep '^?' | cut -d\  -f2- && git ls-files ) | sort -u
  var res = ""
  shellAssign:
    res = pipe:
      cd ($dir)
      "("git status --short
      grep "^?"
      cut -d"\ " -f"2-" && git "ls-files"")"
      sort -u
  return toSeq(res.splitLines())

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
