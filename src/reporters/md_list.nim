# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import sequtils
import strformat
import strutils
import system/io
import tables
from ../tools import round
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
      let severityStr = fmt"{issue.severity}"
      fmt("\n  - {severityStr.toUpper()}{msgFmt(issue.msg)}")
    )
    .join("")
  strm.writeLine(fmt"- [{passedStr}] (success: {round(res.calcSuccess())}) {check.name()}{msg}")

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
  strm.writeLine(fmt"  * Success (Sum / Average): {round(stats.checks.successSum)} / {round(stats.checks.successSum / float(stats.checks.run))}")
  strm.writeLine(fmt"  * Weights (Sum / Average): {round(stats.checks.weightsSum)} / {round(stats.checks.weightsSum / float(stats.checks.run))}")
  strm.writeLine(fmt"* Issues:")
  for imp in stats.issues.keys:
    strm.writeLine(fmt"  * {imp}: {stats.issues[imp]}")
  strm.writeLine(fmt"* Success: {stats.ratings.success.percent}% - ![Badge - Success]({stats.ratings.success.badgeUrl})")
  strm.writeLine(fmt"* Openness: {stats.ratings.openness.percent}% - ![Badge - Success]({stats.ratings.openness.badgeUrl})")
  strm.writeLine(fmt"* is hardware (factor): {stats.ratings.hardware.factor}")
  strm.writeLine(fmt"* Quality: {stats.ratings.quality.percent}% - ![Badge - OSH Quality]({stats.ratings.quality.badgeUrl})")
  strm.writeLine(fmt"* Machine-Readability: {stats.ratings.machineReadability.percent}% - ![Badge - OSH Machine-Readability]({stats.ratings.machineReadability.badgeUrl})")
  # See NOTE in CheckFmt.finalize
  self.repStream.close()
