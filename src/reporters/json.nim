# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import strutils
import std/json
import std/jsonutils
import tables
import ../check
import ./api

type
  JsonCheckFmt* = ref object of CheckFmt
    prelude: ReportPrelude
    checks: seq[tuple[
      name: string,
      passed: bool,
      customPassed: Option[bool],
      compliance: float,
      state: string,
      issues: seq[tuple[
        severity: string,
        msg: string
      ]]
    ]]

method init(self: JsonCheckFmt, prelude: ReportPrelude) =
  self.prelude = prelude

method report(self: JsonCheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) =
  let passed = isGood(res)
  let customPassed = res.isCustomPassed()
  var issues = newSeq[tuple[severity: string, msg: string]]()
  for issue in res.issues:
    issues.add((
      severity: $issue.severity,
      msg: issue.msg.get().replace("\n", "\\n"),
      ))
  self.checks.add((
    name: check.name(),
    passed: passed,
    customPassed: customPassed,
    compliance: float(res.calcCompliance()),
    state: $res.kind,
    issues: issues,
    ))

method finalize(self: JsonCheckFmt, stats: ReportStats) =
  let strm = self.repStream
  strm.writeLine((prelude: self.prelude, checks: self.checks, stats: stats).toJson)
  self.repStream.close()
