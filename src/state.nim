# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import os
import re
import sequtils
import strutils
import ./config_cmd_check
import ./util/fs as fs

type
  State* = object
    config*: ConfigCmdCheck
    configOpt*: ConfigCmdCheckOpt
    projFiles*: Option[seq[string]]
    projFilesL1*: Option[seq[string]]
    projFilesNonGenerated*: Option[seq[string]]

method listFiles*(this: var State): seq[string] {.base.} =
  ## Returns a list of all the project file names, recursively
  if this.projFiles.isNone:
    this.projFiles = some(fs.listFiles(this.config.projRoot))
  return this.projFiles.get

method listFilesNonGenerated*(this: var State): seq[string] {.base.} =
  ## Returns a list of all the project file names, recursively
  if this.projFilesNonGenerated.isNone:
    this.projFilesNonGenerated = some(filterOutGenerated(this.config.projRoot, this.listFiles()))
  return this.projFilesNonGenerated.get

method listFilesMatching*(this: var State, regex: Regex): seq[string] {.base.} =
  ## Returns a list of (recursive) project file names
  ## matching ``regex``
  return toSeq(this.listFiles().filterIt(it.match(regex)))

method listFilesContains*(this: var State, regex: Regex): seq[string] {.base.} =
  ## Returns a list of (recursive) project file names
  ## of which a part matches ``regex``
  return toSeq(this.listFiles().filterIt(it.contains(regex)))

const pathSeps = {DirSep, AltSep}

method listFilesL1*(this: var State): seq[string] {.base.} =
  ## Returns a list of the project file names in the root dir
  ## of the project ("level 1" -> L1)
  if this.projFilesL1.isNone:
    this.projFilesL1 = some(toSeq(this.listFiles().filterIt(not it.contains(pathSeps))))
  return this.projFilesL1.get

method listFilesL1Matching*(this: var State, regex: Regex): seq[string] {.base.} =
  ## Returns a list of (non-recursive) project file names
  ## matching ``regex``
  return toSeq(this.listFilesL1().filterIt(it.match(regex)))

method listFilesL1Contains*(this: var State, regex: Regex): seq[string] {.base.} =
  ## Returns a list of (non-recursive) project file names
  ## of which a part matches ``regex``
  return toSeq(this.listFilesL1().filterIt(it.contains(regex)))

proc newState*(configOpt: ConfigCmdCheckOpt, config: ConfigCmdCheck): State =
  return State(
    config: config,
    configOpt: configOpt,
    projFiles: none(seq[string])
    )
