# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import std/logging
import ./state

type
  ResultKind* = enum
    Success
    Note
    Warning
    Error
  InitResult* = object
    kind*: ResultKind
    msg*: Option[string]
  UpdateResult* = object
    kind*: ResultKind
    msg*: Option[string]

type InitUpdate* = ref object of RootObj

proc logLevel*(this: ResultKind): Level =
  case this:
    of Success:
      return lvlInfo
    of Note:
      return lvlNotice
    of Warning:
      return lvlWarn
    of Error:
      return lvlError

method name*(this: InitUpdate): string {.base.} =
  return "TODO Override!"

method init*(this: InitUpdate, state: var State): InitResult {.base, locks: "unknown".} =
  return InitResult(kind: Error, msg: some("Not implemented for specific check!"))

method update*(this: InitUpdate, state: var State): UpdateResult {.base.} =
  return UpdateResult(kind: Error, msg: some("Not implemented for specific check!"))
