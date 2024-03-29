# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import std/json
import std/jsonutils
import re
import strformat
import strutils
import tables
import ../check

include ../constants

type
  CheckFmt* = ref object of RootObj
    repStream*: File
    repStreamErr*: File

proc getStream*(self: CheckFmt, res: CheckResult): File =
# method getStream(self: CheckFmt, res: CheckResult): File {.base.} =
  if isGood(res):
    self.repStream
  else:
    self.repStreamErr

proc msgFmt*(msg: Option[string]): string =
  return if msg.isSome():
      fmt(" - {msg.get()}").replace("\n", "\n    ")
    else:
      ""

proc mdPrelude*(strm: File, prelude: ReportPrelude) =
  strm.writeLine("")
  strm.writeLine("<details>")
  strm.writeLine("")
  strm.writeLine("<summary>Project meta-data</summary>")
  strm.writeLine("")
  strm.writeLine("| | |")
  strm.writeLine("| --- | -------- |")
  strm.writeLine(fmt"""| _version_ | {prelude.projVars.getOrDefault("VERSION", "N/A")} |""")
  strm.writeLine(fmt"""| _version release date_ | {prelude.projVars.getOrDefault("VERSION_DATE", "N/A")} |""")
  strm.writeLine(fmt"""| _branch_ | {prelude.projVars.getOrDefault("BUILD_BRANCH", "N/A")} |""")
  strm.writeLine(fmt"""| _report build date_ | {prelude.projVars.getOrDefault("BUILD_DATE", "N/A")} |""")
  strm.writeLine(fmt"""| _licenses_ | {prelude.projVars.getOrDefault("LICENSES", "N/A")} |""")
  strm.writeLine("")
  strm.writeLine("</details>")
  strm.writeLine("")
  strm.writeLine("<details>")
  strm.writeLine("")
  strm.writeLine("<summary>Report tools</summary>")
  strm.writeLine("")
  strm.writeLine("| [CLI](https://en.wikipedia.org/wiki/Command-line_interface) tool | version |")
  strm.writeLine("| --- | -------- |")
  strm.writeLine(fmt"| [`osh`]({OSH_TOOL_REPO}) | {prelude.tool_versions.osh} |")
  strm.writeLine(fmt"| [`okh`](https://github.com/OPEN-NEXT/LOSH-OKH-tool) | {prelude.tool_versions.okh} |")
  strm.writeLine(fmt"| [`reuse`](https://github.com/fsfe/reuse-tool/) | {prelude.tool_versions.reuse} |")
  strm.writeLine(fmt"| [`projvar`](https://github.com/hoijui/projvar/) | {prelude.tool_versions.projvar} |")
  strm.writeLine(fmt"| [`mle`](https://github.com/hoijui/mle/) | {prelude.tool_versions.mle} |")
  strm.writeLine(fmt"| [`mlc`](https://github.com/hoijui/mlc/) | {prelude.tool_versions.mlc} |")
  strm.writeLine(fmt"| [`osh-dir-std`](https://github.com/hoijui/osh-dir-std/) | {prelude.tool_versions.osh_dir_std} |")
  strm.writeLine("")
  strm.writeLine("</details>")
  strm.writeLine("")
  strm.writeLine("## Report")
  strm.writeLine("")

proc mdOutro*(strm: File, prelude: ReportPrelude, stats: ReportStats, bashStyle: bool = false) =
  strm.writeLine("")
  strm.writeLine("<details>")
  strm.writeLine("")
  strm.writeLine("<summary>Project meta-data (by projvar)</summary>")
  strm.writeLine("")
  strm.writeLine("| key | value |")
  strm.writeLine("| --- | -------- |")
  for (key, val) in prelude.projVars.pairs:
    let valMd = if match(val, re"^(https?|mailto):"):
        fmt"<{val}>"
      else:
        fmt"`{val}`"
    strm.writeLine(fmt"| `{key}` | {valMd} |")
  if bashStyle:
    strm.writeLine("")
    strm.writeLine("### BASH style")
    strm.writeLine("")
    strm.writeLine("```")
    for (key, val) in prelude.projVars.pairs:
      strm.writeLine(fmt"{key}='{val}'")
    strm.writeLine("```")
  strm.writeLine("")
  strm.writeLine("</details>")
  strm.writeLine("")
  strm.writeLine("<details>")
  strm.writeLine("")
  strm.writeLine("<summary>Configuration used for this `osh`-tool run</summary>")
  strm.writeLine("")
  strm.writeLine("```json")
  let configJsonNode = jsonutils.toJson(prelude.config)
  strm.writeLine(json.pretty(configJsonNode))
  strm.writeLine("```")
  strm.writeLine("")
  strm.writeLine("</details>")

method init*(self: CheckFmt, prelude: ReportPrelude) {.base.} =
  quit "to override!"

method report*(self: CheckFmt, check: Check, res: CheckResult, index: int, indexAll: int, total: int) {.base.} =
  quit "to override!"

method finalize*(self: CheckFmt, stats: ReportStats)  {.base.} =
  self.repStream.close()
  # NOTE This is not required,
  # because stderr does not need to be closed,
  # and if it is a file, it is the same like repStream,
  # which was already closed in the line above
  #repStreamErr.close()
