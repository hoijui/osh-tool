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
import ../check
import ./api

type
  MdTableCheckFmt* = ref object of CheckFmt
    prelude: ReportPrelude

method init(self: MdTableCheckFmt, prelude: ReportPrelude) =
  let strm = self.repStream
  self.prelude = prelude
  mdPrelude(strm, prelude)
  strm.writeLine(fmt"| Passed | Status | Compliance Factor | Weight | Weighted Comp. Fac. | Check | Severity - Issue |")
  # NOTE In some renderers, number of dashes are used to determine relative column width
  strm.writeLine(fmt"| - | -- | - | - | - | --- | ----- |")

method report(self: MdTableCheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) {.locks: "unknown".} =
  let strm = self.getStream(res)
  # See:
  # * <https://en.wikipedia.org/wiki/Check_mark>
  # * <https://en.wikipedia.org/wiki/X_mark>
  let type_1 = true
  let passedStr = if type_1:
    if res.isGood(): "✅" else: "❌"
  else:
    let passedName = if res.isGood(): "🗹" else: "☐"
    let passedColor = res.getGoodColor()
    fmt"""<font color="{passedColor}">{passedName}</font>"""
  let kindName = $res.kind
  let kindColor = res.getKindColor()
  let kindStr = fmt"""<font color="{kindColor}">{kindName}</font>"""
  let compFac = res.calcCompliance()
  let weight = check.getSignificanceFactors().weight
  let weightedComp = compFac * weight
  let msg = res.issues
    .map(proc (issue: CheckIssue): string =
      fmt"""<font color="{issue.severity.toColor()}">__{issue.severity}__</font>{msgFmt(issue.msg)}"""
    )
    .join("<br><hline/><br>")
    .replace("\n", " <br>&nbsp;")
  strm.writeLine(fmt"| {passedStr} | {kindStr} | {round(compFac)} | {round(weight)} | {round(weightedComp)} | {check.name()} | {msg} |")

method finalize(self: MdTableCheckFmt, stats: ReportStats) {.locks: "unknown".} =
  let strm = self.repStream
  strm.writeLine("| " &
    fmt"| {round(stats.checks.complianceSum)}/__{round(stats.checks.complianceSum / float(stats.checks.run))}__ " &
    fmt"| {round(stats.checks.weightsSum)}/__{round(stats.checks.weightsSum / float(stats.checks.run))}__ " &
    fmt"| {round(stats.ratings.compliance.factor * float(stats.checks.run))}/__{round(stats.ratings.compliance.factor)}__ " &
    "| Sum/__Average__ | |")
  strm.writeLine("")
  strm.writeLine("## Project Statistics")
  strm.writeLine("")
  strm.writeLine("| Property | Value |")
  # NOTE In some renderers, number of dashes are used to determine relative column width
  strm.writeLine("| --- | -- |")
  strm.writeLine(fmt"| Checks Run | {stats.checks.run} |")
  strm.writeLine(fmt"| Checks Skipped | {stats.checks.skipped} |")
  strm.writeLine(fmt"| Checks Passed | {stats.checks.passed} |")
  strm.writeLine(fmt"| Checks Failed | {stats.checks.failed} |")
  strm.writeLine(fmt"| Checks Available | {stats.checks.available} |")
  for imp in stats.issues.keys:
    strm.writeLine(fmt"| Issues {imp} | {stats.issues[imp]} |")
  strm.writeLine(fmt"| Compliance | {stats.ratings.compliance.percent}% - ![Badge - Compliance]({stats.ratings.compliance.badgeUrl}) |")
  strm.writeLine(fmt"| Openness | {stats.ratings.openness.percent}% - ![Badge - Compliance]({stats.ratings.openness.badgeUrl}) |")
  strm.writeLine(fmt"| is hardware (factor) | {stats.ratings.hardware.factor} |")
  strm.writeLine(fmt"| Quality | {stats.ratings.quality.percent}% - ![Badge - OSH Quality]({stats.ratings.quality.badgeUrl}) |")
  strm.writeLine(fmt"| Machine-Readability | {stats.ratings.machineReadability.percent}% - ![Badge - OSH Machine-Readability]({stats.ratings.machineReadability.badgeUrl}) |")
  mdOutro(strm, self.prelude, stats)
  # See NOTE in CheckFmt.finalize
  self.repStream.close()
