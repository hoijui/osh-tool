# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import sequtils
import strformat
import strutils
import tables
from ../util/leightweight import round, toPercentStr
import ../check
import ./api

type
  MdTableCheckFmt* = ref object of CheckFmt
    prelude: ReportPrelude
    debug: bool

method init(self: MdTableCheckFmt, prelude: ReportPrelude) =
  let strm = self.repStream
  self.prelude = prelude
  self.debug = false # TODO Make this configurable somehow
  mdPrelude(strm, prelude)
  let tblOptHeader = if self.debug:
    " | Weight | Weighted Comp. Fac."
  else:
    ""
  let tblOptDelim = if self.debug:
    " | -: | -:"
  else:
    ""
  strm.writeLine(fmt"| Passed | Status | Compliance" & tblOptHeader & " | Check | Severity - Issue |")
  # NOTE In some renderers, number of dashes are used to determine relative column width
  strm.writeLine(fmt"| - | -- | -:" & tblOptDelim & " | ----- | ---------------- |")

method report(self: MdTableCheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) =
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
  let comp = toPercentStr(compFac)
  let weight = check.getSignificanceFactors().weight
  let weightedComp = compFac * weight
  let msg = res.issues
    .map(proc (issue: CheckIssue): string =
      fmt"""<font color="{issue.severity.toColor()}">__{issue.severity}__</font>{msgFmt(issue.msg)}"""
    )
    .join("<br><hline/><br>")
    .replace("\n", " <br>&nbsp;")
  let tblOptVals = if self.debug:
    fmt" | {round(weight)} | {round(weightedComp)}"
  else:
    ""
  strm.writeLine(fmt"| {passedStr} | {kindStr} | {comp}%" & tblOptVals & fmt" | {check.name()} | {msg} |")

method finalize(self: MdTableCheckFmt, stats: ReportStats) =
  let strm = self.repStream
  let tblOptAvers = if self.debug:
    fmt" | __{toPercentStr(stats.checks.weightsSum / float(stats.checks.run))}%__" &
    fmt" | __{toPercentStr(stats.ratings.compliance.factor)}%__"
  else:
    ""
  strm.writeLine("| | " &
    fmt"| __{toPercentStr(stats.checks.complianceSum / float(stats.checks.run))}%__" &
    tblOptAvers &
    " | __Average__ | |")
  strm.writeLine("")
  strm.writeLine("<details>")
  strm.writeLine("")
  strm.writeLine("<summary>Project Statistics</summary>")
  strm.writeLine("")
  strm.writeLine("| Property | Value |")
  # NOTE In some renderers, number of dashes are used to determine relative column width
  strm.writeLine("| --- | --: |")
  strm.writeLine(fmt"| Checks Run | {stats.checks.run} |")
  strm.writeLine(fmt"| Checks Skipped | {stats.checks.skipped} |")
  strm.writeLine(fmt"| Checks Passed | {stats.checks.passed} |")
  strm.writeLine(fmt"| Checks Failed | {stats.checks.failed} |")
  strm.writeLine(fmt"| Checks Available | {stats.checks.available} |")
  for imp in stats.issues.keys:
    strm.writeLine(fmt"| Issues {imp} | {stats.issues[imp]} |")
  strm.writeLine(fmt"| Compliance | {stats.ratings.compliance.percent}% |")
  strm.writeLine(fmt"| Openness | {stats.ratings.openness.percent}% |")
  strm.writeLine(fmt"| is hardware (factor) | {round(stats.ratings.hardware.factor)} |")
  strm.writeLine(fmt"| Quality | {stats.ratings.quality.percent}% |")
  strm.writeLine(fmt"| Machine-Readability | {stats.ratings.machineReadability.percent}% |")
  strm.writeLine("")
  strm.writeLine("</details>")
  mdOutro(strm, self.prelude, stats)
  # See NOTE in CheckFmt.finalize
  self.repStream.close()
