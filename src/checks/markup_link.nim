# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2022-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import json
import options
import std/logging
import std/osproc
import std/streams
import std/strutils
import strformat
import system
import tables
import ../check
import ../check_config
import ../state
import ../util/fs

#const IDS = @[srcFileNameBase(), "mul", "mulinks", "mu_links", "markup_links"]
const ID = srcFileNameBase()
const HIGH_COMPLIANCE = 0.97
const MIN_COMPLIANCE = 0.80
const MLC_CMD = "mlc"
const LYCHEE_CMD = "lychee"

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

proc runWithLychee(this: MarkupLinkCheck, state: var State, markupFiles: seq[string]): CheckResult =
  let config = state.config.checks[ID]
  try:
    debug fmt"Now running '{LYCHEE_CMD}' (link-checker - CLI) ..."
    let process = osproc.startProcess(
      command = LYCHEE_CMD,
      workingDir = state.config.projRoot,
      args = [
        "--format=json",
        "--host-stats",
        "--include-fragments=full",
        "--include-mail",
        "--include-verbatim",
        "--no-progress",
        "--suggest",
        "--files-from", "-"],
      env = nil,
      options = {poUsePath}
      )

    debug fmt"Waiting for '{LYCHEE_CMD}' run to end ..."
    let procStdin = process.inputStream()
    debug fmt"  {LYCHEE_CMD}: Writing Markup files to stdin ..."
    for path in markupFiles:
      procStdin.writeLine(path)
    debug fmt"  {LYCHEE_CMD}: Close stdin (we supposedly should not do this manually, but apparently we have to!) ..."
    procStdin.close()
    debug fmt"  {LYCHEE_CMD}: Ask for exit code and stdout ..."
    let (lines, exCode) = process.readLines()
    debug fmt"  {LYCHEE_CMD}: Collect stderr ..."
    let stderrCollected = process.errorStream.readAll()
    process.errorStream.close()
    debug fmt"Waiting for '{LYCHEE_CMD}' run to end ..."
    process.close()

    debug fmt"  {LYCHEE_CMD}: Run finished; analyze results ..."
    if exCode == 0:
      newCheckResult(config, CheckResultKind.Perfect)
    else:
      if exCode == 2:
        # At least one link failed to resolve
        debug fmt"Parsing {LYCHEE_CMD}' output as JSON ..."
        let jsonRoot = parseJson(lines.join("\n"))
        debug fmt"Calculating links success rate ..."
        # Total number of links seen in this link-check
        let numLinks = jsonRoot["total"].getInt()
        let numFailedLinks = jsonRoot["errors"].getInt()
        let successRate = float32(numLinks - numFailedLinks) / float32(numLinks)
        var issues: seq[CheckIssue] = @[]
        let extendedIssues = false
        debug fmt"Wrapping bad links in issues ..."
        for (localFilePath, failedLinks) in jsonRoot["error_map"].pairs:
          for failedLink in failedLinks:
            let span = failedLink["span"]
            let badLink = fmt"""{localFilePath}:{span["line"].getInt()}:{span["column"].getInt()}:{failedLink["url"].getStr()}"""
            let msg = if extendedIssues:
                let status = failedLink["status"]
                let issueDesc = if status.hasKey("code"):
                    status["code"].getStr()
                  elif status.hasKey("details"):
                    status["details"].getStr()
                  else:
                    status["text"].getStr()
                fmt"""Bad Link at:
  {badLink}
      -> issue: {issueDesc}"""
              else:
                badLink
            issues.add(CheckIssue(
                severity: CheckIssueSeverity.Low,
                msg: some(msg)
              ))
        debug fmt"Wrapping bad links in issues - done."
        let kind = if successRate >= HIGH_COMPLIANCE:
            CheckResultKind.Ok
          elif successRate >= MIN_COMPLIANCE:
            CheckResultKind.Acceptable
          else:
            CheckResultKind.Bad
        return CheckResult(
          config: config,
          kind: kind,
          issues: issues,
        )
      else:
        # The tool failed to run for an extraordinary reason
        debug fmt"""{LYCHEE_CMD} exited with unknown code {exCode}.
stdout was:
################################################################
{lines.join("\n")}
################################################################
stdout was:
################################################################
{stderrCollected}
################################################################"""
        let msg = fmt("ERROR Failed to run '{LYCHEE_CMD}'; reason unknown; exit code: {exCode}")
        return newCheckResult(
          config,
          CheckResultKind.Bad,
          CheckIssueSeverity.High,
          some(msg))
  except OSError as err:
    let msg = fmt("ERROR Failed to run '{LYCHEE_CMD}'; make sure it is in your PATH: {err.msg}")
    newCheckResult(config, CheckResultKind.Bad, CheckIssueSeverity.High, some(msg))

proc runWithMlc(this: MarkupLinkCheck, state: var State, markupFiles: seq[string]): CheckResult =
  let config = state.config.checks[ID]
  try:
    debug fmt"Now running '{MLC_CMD}' (link-checker - CLI) ..."
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
      newCheckResult(config, CheckResultKind.Perfect)
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
      newCheckResult(config, kind, CheckIssueSeverity.Middle, msg)
  except OSError as err:
    let msg = fmt("ERROR Failed to run '{MLC_CMD}'; make sure it is in your PATH: {err.msg}")
    newCheckResult(config, CheckResultKind.Bad, CheckIssueSeverity.High, some(msg))

method run*(this: MarkupLinkCheck, state: var State): CheckResult =
  let config = state.config.checks[ID]
  let markupFiles = filterByExtensions(state.listFiles(), @["md", "markdown"], 1)
  if markupFiles.len() == 0:
    return newCheckResult(
      config,
      CheckResultKind.Inapplicable,
      CheckIssueSeverity.Low,
      some(fmt"No Markdown sources found, thus we can not lint anything")
    )
  # this.runWithMlc(state, markupFiles)
  this.runWithLychee(state, markupFiles)

method id*(this: MarkupLinkCheckGenerator): string =
  return ID

method generate*(this: MarkupLinkCheckGenerator, config: CheckConfig = this.defaultConfig()): Check =
  this.ensureNonConfig(config)
  MarkupLinkCheck(generator: this)

proc createGenerator*(): CheckGenerator =
  MarkupLinkCheckGenerator()
