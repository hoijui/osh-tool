# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import strformat
import strutils
import system/io
import ../check

type
  CheckFmt* = ref object of RootObj
    repStream*: File
    repStreamErr*: File

proc getStream*(self: CheckFmt, res: CheckResult): File =
# method getStream(self: CheckFmt, res: CheckResult): File {.base.} =
  if isGood(res):
    self.repStream
  else:
    self.repStreamErr

proc msgFmt*(msg: Option[string]): string =
  return if msg.isSome():
      fmt(" - {msg.get()}").replace("\n", "\n    ")
    else:
      ""

method init*(self: CheckFmt) {.base.} =
  quit "to override!"

method report*(self: CheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) {.base, locks: "unknown".} =
  quit "to override!"

method finalize*(self: CheckFmt, stats: ReportStats)  {.base, locks: "unknown".} =
  self.repStream.close()
  # NOTE This is not required,
  # because stderr does not need to be closed,
  # and if it is a file, it is the same like repStream,
  # which was already closed in the line above
  #repStreamErr.close()
