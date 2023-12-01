# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import sequtils
import strformat
import strutils
import ../check
import ./api
import csvtools

type
  CsvCheck = object
      passed: string
      customPassed: string
      state: string
      compliance: float
      weight: float
      weightedCompliance: float
      name: string
      msg: string
  CsvCheckFmt* = ref object of CheckFmt
    checks: seq[CsvCheck]

method init(self: CsvCheckFmt, prelude: ReportPrelude) =
  let strm = self.repStream
  strm.writeLine("\"Passed\", \"Custom-Passed\", \"Status\", \"Compliance Factor\", \"Weight\", \"Weighted Comp. Fac.\", \"Check\", \"Severity - Issue\"")

method report(self: CsvCheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) =
  let passed = isGood(res)
  let passedStr = if passed: "true" else: "false"
  let customPassed = res.isCustomPassed()
  let customPassedStr = if customPassed.isSome():
      if customPassed.get():
        "true"
      else:
        "false"
    else:
      ""
  let compliance = res.calcCompliance()
  let weight = check.getSignificanceFactors().weight
  let msg = res.issues
    .map(proc (issue: CheckIssue): string =
      fmt"__{issue.severity}__{msgFmt(issue.msg)}"
    )
    .join("<br><hline/><br>")
    .replace("\n", " <br>&nbsp;")
  self.checks.add(CsvCheck(
    passed: passedStr,
    customPassed: customPassedStr,
    state: $res.kind,
    compliance: compliance,
    weight: weight,
    weightedCompliance: compliance * weight,
    name: check.name(),
    msg: msg))

method finalize(self: CsvCheckFmt, stats: ReportStats) =
  var strm = self.repStream
  self.checks.writeToCsv(strm)
  self.repStream.close()
