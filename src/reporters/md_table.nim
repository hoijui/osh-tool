# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
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

proc bool2str(val: bool): string =
  # let type_1 = true
  # if type_1:
  # See:
  # * <https://en.wikipedia.org/wiki/Check_mark>
  # * <https://en.wikipedia.org/wiki/X_mark>
  if val: "✅" else: "❌"
  # else:
  #   let passedName = if val: "🗹" else: "☐"
  #   let passedColor = res.getGoodColor()
  #   fmt"""<font color="{passedColor}">{passedName}</font>"""

proc tableHeader(debug: bool, fattened: bool = false): string =
  let tblOptHeader = if debug:
    " | Weight | Weighted Comp. Fac."
  else:
    ""
  var tblHeader = fmt"| Passed | Custom-Passed | Status | Compliance{tblOptHeader} | Check | Severity - Issue |"
  if fattened:
    tblHeader = tblHeader.replace("| ", "| **").replace(" |", "** |")
  tblHeader

proc tableHeaderDelims(debug: bool): string =
  let tblOptDelim = if debug:
    " | -: | -:"
  else:
    ""
  # NOTE In some renderers, number of dashes are used to determine relative column width
  fmt"| - | - | -- | -:{tblOptDelim} | ----- | ---------------- |"

method init(self: MdTableCheckFmt, prelude: ReportPrelude) =
  let strm = self.repStream
  self.prelude = prelude
  self.debug = false # TODO Make this configurable somehow
  mdPrelude(strm, prelude)
  strm.writeLine(tableHeader(self.debug))
  strm.writeLine(tableHeaderDelims(self.debug))

method report(self: MdTableCheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) =
  let strm = self.getStream(res)
  let passedStr = bool2str(res.isGood())
  let customPassed = res.isCustomPassed()
  let customPassedStr = if customPassed.isSome():
      bool2str(customPassed.get())
    else:
      " "
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
  strm.writeLine(fmt"| {passedStr} | {customPassedStr} | {kindStr} | {comp}%" & tblOptVals & fmt" | {check.name()} | {msg} |")

method finalize(self: MdTableCheckFmt, stats: ReportStats) =
  let strm = self.repStream
  let tblOptAvers = if self.debug:
    fmt" | __{toPercentStr(stats.checks.weightsSum / float(stats.checks.run))}%__" &
    fmt" | __{toPercentStr(stats.ratings.compliance.factor)}%__"
  else:
    ""
  strm.writeLine(fmt"| | | __{toPercentStr(stats.checks.complianceSum / float(stats.checks.run))}%__{tblOptAvers} | <- __Average__ | |")
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
  strm.writeLine(fmt"| Custom-Passed | {stats.checks.customCompliance.passed} |")
  strm.writeLine(fmt"| Custom-Failed | {stats.checks.customCompliance.failed} |")
  strm.writeLine(fmt"| Custom-Not-Configured | {stats.checks.customCompliance.notConfigured} |")
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
