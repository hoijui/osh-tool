# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

import strutils
import strformat
import httpclient
import os
import re
import ./config

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

# TODO Optimize the next few procs with an answer from SO: https://stackoverflow.com/questions/67833490/how-to-modularize-abstract-away-os-walkdir-and-os-walkdirrec-nim/67838118#67838118
proc containsFiles*(dir: string, regex: Regex, recursive: bool = false) : bool =
  ## Checks whether ``dir`` contains any files matching ``regex``,
  if recursive:
    for file in os.walkDirRec(dir):
      if file.find(regex) != -1:
        return true
  else:
    for file in os.walkDir(dir):
      if file.path.find(regex) != -1:
        return true
  return false

iterator listFiles*(dir: string, regex: Regex, recursive: bool = false) : string =
  ## Iterates over files in ``dir`` that match a regex.
  if recursive:
    for file in os.walkDirRec(dir, relative = true):
      if file.find(regex) != -1:
        yield file
  else:
    for file in os.walkDir(dir, relative = true):
      if file.path.find(regex) != -1:
        yield file.path

proc containsFilesWithSuffix*(dir: string, suffix: string, recursive: bool = true, ignore_case: bool = false) : bool =
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
