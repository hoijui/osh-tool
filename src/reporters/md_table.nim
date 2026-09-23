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
    " <th>Weight</th> <th>Weighted Comp. Fac.</th>"
  else:
    ""
  var tblHeader = fmt"""<th>Passed</th> <th>Custom-Passed</th> <th>Status</th> <th style="text-align: right;">Compliance</th>{tblOptHeader} <th>Check</th> <th>Severity - Issue</th>"""
  if fattened:
    tblHeader = tblHeader.replace("<th>", "<th><b>").replace("</th>", "</b></th>")
  fmt"""<table>
<colgroup>
<col style="width: 3%">
<col style="width: 3%">
<col style="width: 7%">
<col style="width: 7%">
<col style="width: 18%">
<col style="width: 59%">
</colgroup>
<thead>
<tr>
{tblHeader}
</tr>
</thead>
<tbody>
"""

method init(self: MdTableCheckFmt, prelude: ReportPrelude) =
  let strm = self.repStream
  self.prelude = prelude
  self.debug = false # TODO Make this configurable somehow
  mdPrelude(strm, prelude)
  strm.writeLine(tableHeader(self.debug))

method report(self: MdTableCheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) =
  let id = check.generator().id()
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
  var issueStats = initOrderedTable[CheckIssueSeverity, int](5)
  issueStats[CheckIssueSeverity.DeveloperFailure] = 0
  issueStats[CheckIssueSeverity.High] = 0
  issueStats[CheckIssueSeverity.Middle] = 0
  issueStats[CheckIssueSeverity.Low] = 0
  issueStats[CheckIssueSeverity.Info] = 0
  for issue in res.issues:
    issueStats[issue.severity] += 1
  let msgSummary = issueStats.pairs()
      .toSeq()
      .filter(proc (iStats: tuple[severity: CheckIssueSeverity, ocurences: int]): bool = iStats.ocurences > 0)
      .map(proc (iStats: tuple[severity: CheckIssueSeverity, ocurences: int]): string =
        fmt"""<font color="{iStats.severity.toColor()}"><b>{iStats.severity}</b></font>: {iStats.ocurences}"""
      )
      .join(", ")
  let msgFull = res.issues
    .map(proc (issue: CheckIssue): string =
      fmt"""<font color="{issue.severity.toColor()}"><b>{issue.severity}</b></font>{msgFmt(issue.msg)}"""
    )
    .join("<br><hline/><br>")
    .replace("\n", " <br>&nbsp;")
  let msg = if msgFull == "":
      msgFull
    else:
      fmt"""<details><summary>{msgSummary}</summary><br><br>{msgFull}</details>"""
  let tblOptVals = if self.debug:
    fmt" <td>{round(weight)}</td> <td>{round(weightedComp)}</td>"
  else:
    ""
  strm.writeLine(fmt"""<tr> <td>{passedStr}</td> <td>{customPassedStr}</td> <td>{kindStr}</td> <td style="text-align: right;">{comp}%""" & tblOptVals & fmt"""</td> <td><a href="#check_{id}">{check.name()}</a> </td> <td>{msg}</td> </tr>""")

method finalize(self: MdTableCheckFmt, stats: ReportStats) =
  let strm = self.repStream
  let tblOptAvers = if self.debug:
    fmt" <th><b>{toPercentStr(stats.checks.weightsSum / float(stats.checks.run))}%</b></th>" &
    fmt" <th><b>{toPercentStr(stats.ratings.compliance.factor)}%</b></th>"
  else:
    ""
  let customPassedSummary = if stats.isNoneCustom():
      ""
    else:
      bool2str(stats.isNoneCustomFailed())
  strm.writeLine(tableHeader(self.debug, true))
  strm.writeLine(fmt"<tr> <th></th> <th>{customPassedSummary}</th> <th></th> <th><b>{toPercentStr(stats.checks.complianceSum / float(stats.checks.run))}%</b></th>{tblOptAvers} <th><- <b>Average</b></th> <th></th> </tr>")
  strm.writeLine("</tbody>")
  strm.writeLine("</table>")
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
