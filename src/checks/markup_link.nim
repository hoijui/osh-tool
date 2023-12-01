# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2022-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import std/logging
import std/osproc
import std/streams
import std/strutils
import strformat
import system
import ../check
import ../check_config
import ../state
import ../util/fs

const IDS = @["mul", "mulinks", "mu_links", "markup_links"]
const ID = IDS[0]
const MLC_CMD = "mlc"

type MarkupLinkCheck = ref object of Check
type MarkupLinkCheckGenerator = ref object of CheckGenerator

method name*(this: MarkupLinkCheck): string =
  return "Markup link check"

method description*(this: MarkupLinkCheck): string =
  return """Checks whether links in Markdown and HTML documents \
in the repo are pointing to something valid."""

method why*(this: MarkupLinkCheck): string =
  return """Links are often put in by project maintainers once
and then they forget about them.
Due to the dynamic nature of the web,
links become defunct over time,
which of course hurts the quality of the documentation
and the experience the users have, browsing it.

This is especially important and freuqent
in regards to repo-internal links.

This check brings the attention of this issue
back to the repo maintainers,
without having to rely on users
reporting each link individually."""

method sourcePath*(this: MarkupLinkCheck): string =
  return fs.srcFileName()

method requirements*(this: MarkupLinkCheck): CheckReqs =
  return {
    CheckReq.FileContent,
    CheckReq.ExternalTool,
  }

method getSignificanceFactors*(this: MarkupLinkCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.7,
    openness: 0.9,
    hardware: 0.0,
    quality: 1.0,
    machineReadability: 0.6,
    )

method run*(this: MarkupLinkCheck, state: var State): CheckResult =
  # return newCheckResult(CheckResultKind.Perfect)
  let mdFiles = filterByExtensions(state.listFiles(), @["md", "markdown"], 1)
  if mdFiles.len() == 0:
    return newCheckResult(
      CheckResultKind.Inapplicable,
      CheckIssueSeverity.Low,
      some(fmt"No Markdown sources found, thus we can not lint anything")
    )
  try:
    debug fmt"Now running '{MLC_CMD}' ..."
    let process = osproc.startProcess(
      command = MLC_CMD,
      workingDir = state.config.projRoot,
      args = ["."],
      env = nil,
      options = {poUsePath, poStdErrToStdOut})
    process.inputStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    #process.errorStream.close() # NOTE (We can and should not use this, because we use poStdErrToStdOut above, and thus stderr does not exist) - **Essential** - This prevents hanging/freezing when reading stdoerr below
    let (lines, exCode) = process.readLines()
    debug fmt"'{MLC_CMD}' run done."
    if exCode == 0:
      newCheckResult(CheckResultKind.Perfect)
    else:
      let kind = if exCode == 1:
          # At least one link failed to resolve
          CheckResultKind.Acceptable
        else:
          # The tool failed to run for an extraordinary reason
          CheckResultKind.Bad
      let msg = if len(lines) > 0:
          some(lines.join("\n"))
        else:
          none(string)
      newCheckResult(kind, CheckIssueSeverity.Middle, msg)
  except OSError as err:
    let msg = fmt("ERROR Failed to run '{MLC_CMD}'; make sure it is in your PATH: {err.msg}")
    newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.High, some(msg))

method id*(this: MarkupLinkCheckGenerator): seq[string] =
  return IDS

method generate*(this: MarkupLinkCheckGenerator, config: CheckConfig = CheckConfig(id: this.id()[0], json: none[string]())): Check =
  this.ensureNonConfig(config)
  MarkupLinkCheck()

proc createGenerator*(): CheckGenerator =
  MarkupLinkCheckGenerator()
