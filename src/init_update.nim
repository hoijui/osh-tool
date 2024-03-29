# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import std/logging
import ./state
import ./init_update_config

type
  ResultKind* = enum
    Compliance
    Note
    Warning
    Error
  InitResult* = object
    kind*: ResultKind
    msg*: Option[string]
  UpdateResult* = object
    kind*: ResultKind
    msg*: Option[string]

type
  InitUpdate* = ref object of RootObj

  InitUpdateGenerator* = ref object of RootObj

proc logLevel*(this: ResultKind): Level =
  case this:
    of Compliance:
      return lvlInfo
    of Note:
      return lvlNotice
    of Warning:
      return lvlWarn
    of Error:
      return lvlError

method id*(this: InitUpdateGenerator): seq[string] {.base.} =
  ## Returns a list of short, human&machine oriented, unique IDs/names
  ## of the init&update that this can generate.
  ## These IDs are used to reffer to the init&update in configuration.
  return @["TODO Override!"]

method configSchema*(this: InitUpdateGenerator): Option[string] {.base.} =
  ## Returns the JSON-Schema for the configuration
  ## of the type of init&update generated by this.
  return none[string]()

method generate*(this: InitUpdateGenerator, config: Option[InitUpdateConfig] = none[InitUpdateConfig]()): InitUpdate {.base.} =
  ## Generates a init&update instance,
  ## using either the default configuration if `none` is supplied,
  ## or configured by the JSON formatted configuration given.
  echo "TODO Override!"
  quit 97

proc applies*(this: InitUpdateGenerator, id: string): bool =
  ## Checks whether the given ID is a valid identifier
  ## for the init&update generated by this.
  ## This just means, it is in the list of our IDs.
  this.id.contains(id)

method name*(this: InitUpdate): string {.base.} =
  return "TODO Override!"

method init*(this: InitUpdate, state: var State): InitResult {.base.} =
  return InitResult(kind: Error, msg: some("Not implemented for specific init&update!"))

method update*(this: InitUpdate, state: var State): UpdateResult {.base.} =
  return UpdateResult(kind: Error, msg: some("Not implemented for specific init&update!"))
