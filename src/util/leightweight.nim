# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import strutils
import options
import os
import macros

type
  YesNoAuto* = enum
    Yes
    No
    Auto

proc toOpt*(this: YesNoAuto): Option[bool] =
  return case this:
    of Yes:
      some(true)
    of No:
      some(false)
    of Auto:
      none[bool]()

proc fromOpt*(t: typedesc[YesNoAuto], this: Option[bool]): YesNoAuto =
  return if this.isSome():
      if this.get():
        Yes
      else:
        No
    else:
      Auto

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
  for x in walkDir("./src/" & dir, true): # TODO Sort this first, to get a predictable order -- or alternatively, implement sort-order for checks, and use an ordering data structure (i.e. TreeSet in Java)
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
                ident("createGenerator"),
              )
            )
          )
        )
  commands.add(
    newNimNode(nnkCall).add(
      newNimNode(nnkDotExpr).add(
        ident("this"),
        ident("sort"),
      )
    )
  )
  commands

# macro loadAll*(dir: static[string], container: static[string]): untyped =
#   var commands = newStmtList()
#   for x in walkDir("./src/" & dir, true): # TODO Sort this first, to get a predictable order -- or alternatively, implement sort-order for checks, and use an ordering data structure (i.e. TreeSet in Java)
#     if(x.kind == pcFile):
#       let split = x.path.splitFile()
#       if(split.ext == ".nim"):
#         commands.add(
#           newNimNode(nnkCall).add(
#             newNimNode(nnkDotExpr).add(
#               ident(container),
#               ident("add"),
#             ),
#             newNimNode(nnkCall).add(
#               newNimNode(nnkDotExpr).add(
#                 ident(split.name),
#                 ident("createDefault"),
#               )
#             )
#           )
#         )
#   # commands.add(
#   #   newNimNode(nnkCall).add(
#   #     newNimNode(nnkDotExpr).add(
#   #       ident("this"),
#   #       ident("sort"),
#   #     )
#   #   )
#   # )
#   commands

proc orr*[T](this: Option[T], other: Option[T]): Option[T] =
  return if this.isSome():
      this
    else:
      other

proc containsAny*(big: seq[string], small: seq[string]): bool =
  for sEnt in small:
    if big.contains(sEnt):
      return true
  return false

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
