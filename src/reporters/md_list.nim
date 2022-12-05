# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import sequtils
import strformat
import strutils
import system/io
import tables
import ./api
import ../check

type
  MdListCheckFmt* = ref object of CheckFmt
    prelude: ReportPrelude

method init(self: MdListCheckFmt, prelude: ReportPrelude) =
  let strm = self.repStream
  self.prelude = prelude
  mdPrelude(strm, prelude)

method report(self: MdListCheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) =
  let strm = self.getStream(res)
  let passed = isGood(res)
  let passedStr = if passed: "x" else: " "
  let msg = res.issues
    .map(proc (issue: CheckIssue): string =
      let importanceStr = fmt"{issue.importance}"
      fmt("\n  - {importanceStr.toUpper()}{msgFmt(issue.msg)}")
    )
    .join("")
  strm.writeLine(fmt"- [{passedStr}] {check.name()}{msg}")

method finalize(self: MdListCheckFmt, stats: ReportStats) {.locks: "unknown".} =
  let strm = self.repStream
  strm.writeLine("")
  strm.writeLine("## Project Statistics")
  strm.writeLine("")
  strm.writeLine(fmt"* Checks:")
  strm.writeLine(fmt"  * Run: {stats.checks.run}")
  strm.writeLine(fmt"  * Skipped: {stats.checks.skipped}")
  strm.writeLine(fmt"  * Passed: {stats.checks.passed}")
  strm.writeLine(fmt"  * Failed: {stats.checks.failed}")
  strm.writeLine(fmt"  * Available: {stats.checks.available}")
  strm.writeLine(fmt"* Issues:")
  for imp in stats.issues.keys:
    strm.writeLine(fmt"  * {imp}: {stats.issues[imp]}")
  strm.writeLine(fmt"* Openness: {stats.openness}")
  # See NOTE in CheckFmt.finalize
  self.repStream.close()
