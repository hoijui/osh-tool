# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import sequtils
import strformat
import strutils
import system/io
import ../check
import ./api
import csvtools

type
  CsvCheck = object
      passed: string
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
  strm.writeLine("\"Passed\", \"Status\", \"Compliance Factor\", \"Weight\", \"Weighted Comp. Fac.\", \"Check\", \"Severity - Issue\"")

method report(self: CsvCheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) {.locks: "unknown".} =
  let passed = isGood(res)
  let passedStr = if passed: "true" else: "false"
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
    state: $res.kind,
    compliance: compliance,
    weight: weight,
    weightedCompliance: compliance * weight,
    name: check.name(),
    msg: msg))

method finalize(self: CsvCheckFmt, stats: ReportStats) {.locks: "unknown".} =
  var strm = self.repStream
  self.checks.writeToCsv(strm)
  self.repStream.close()
