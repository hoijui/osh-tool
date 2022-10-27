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
import ../check
import ./api

type
  MdTableCheckFmt* = ref object of CheckFmt

method init(self: MdTableCheckFmt) =
  let strm = self.repStream
  strm.writeLine(fmt"| Passed | Check | Message |")
  # NOTE In some renderers, number of dashes are used to determine relative column width
  strm.writeLine(fmt"| - | --- | ----- |")

method report(self: MdTableCheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) {.locks: "unknown".} =
  let strm = self.getStream(res)
  let passed = isGood(res)
  let passedStr = if passed: "x" else: " "
  let msg = res.issues
    .map(proc (issue: CheckIssue): string =
      fmt"__{issue.importance}__{msgFmt(issue.msg)}"
    )
    .join("<br><hline/><br>")
    .replace("\n", " <br>&nbsp;")
  strm.writeLine(fmt"| [{passedStr}] | {check.name()} | {msg} |")

method finalize(self: MdTableCheckFmt, stats: ReportStats) {.locks: "unknown".} =
  let strm = self.repStream
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
  strm.writeLine(fmt"| Openness | {stats.openness} |")
  # See NOTE in CheckFmt.finalize
  self.repStream.close()
