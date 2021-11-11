# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import os
import re
import sequtils
import strutils
import ./config
import ./tools as tools

type
  State* = object
    config*: RunConfig
    projFiles*: Option[seq[string]]
    projFilesL1*: Option[seq[string]]

method listFiles*(this: var State): seq[string] {.base.} =
  ## Returns a list of all the project file names, recursively
  if this.projFiles.isNone:
    this.projFiles = some(tools.listFiles(this.config.projRoot))
  return this.projFiles.get

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

proc newState*(config: RunConfig): State =
  return State(
    config: config,
    #projFiles: none[seq[string]],
    projFiles: none(seq[string])
    )
