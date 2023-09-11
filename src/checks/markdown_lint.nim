# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2022-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import strformat
import system
import ../check
import ../config
import ../file_ext_meta
import ../state
import ../tools
import std/logging
import std/osproc
import std/streams
import std/strutils

const MDL_CMD = "mdl"
const OK_NUM_ISSUES_PER_FILE = 5

type MarkdownLintCheck = ref object of Check

method name*(this: MarkdownLintCheck): string =
  return "Markdown content"

method description*(this: MarkdownLintCheck): string =
  return """Checks that the content of all Markdown files in the repository
adheres to a strict set of syntax rules for that format."""

method why*(this: MarkdownLintCheck): string =
  return """Markdown exists in many different varieties.
There is mostly one original format (simply: "Markdown"),
which has very loose syntax rules,
and which nobody uses anymore,
because it can be unclear what was meant to be expressed
(format wise).
Then there are all the derivatives,
which are not fully compatible amongst each other.
Examples for these are:

* CommonMark (Close)
* Github Flavored Markdown (GFM)
* GitLab Markdown (very similar to the above)
* Pandoc Markdown

CommonMark has the same, limited set of features like the original Markdown,
but is very strict with regards to what is valid and what not.
This is good, because it means, that if you adhere to this set of rules,
__your Markdown will be correctly interpreted whereever Markdown is accepted__

Most other Markdown flavors -
like the other three above -
have extended the original set of features,
and try to guess what the user wanted to express,
even if they did not use correct syntax.
To rely on this though, makes ones Markdown less portable,
and thus in a way, kind of inflicts a soft lock-in
on systems supporting such heuristics."""

method sourcePath*(this: MarkdownLintCheck): string =
  return tools.srcFileName()

method requirements*(this: MarkdownLintCheck): CheckReqs =
  return {
    CheckReq.FilesListRec,
    CheckReq.FileContent,
    CheckReq.ExternalTool,
  }

method getSignificanceFactors*(this: MarkdownLintCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.5,
    openness: 0.9,
    hardware: 0.0,
    quality: 1.0,
    machineReadability: 1.0,
    )

method run*(this: MarkdownLintCheck, state: var State): CheckResult =
  let mdFiles = filterByExtensions(state.listFiles(), @["md", "markdown"], 1)
  if mdFiles.len() == 0:
    return newCheckResult(
      CheckResultKind.Inapplicable,
      CheckIssueSeverity.Low,
      some(fmt"No Markdown sources found, thus we can not lint anything")
    )
  try:
    debug fmt"Now running '{MDL_CMD}' ..."
    let process = osproc.startProcess(
      command = MDL_CMD,
      workingDir = state.config.projRoot,
      args = ["."],
      env = nil,
      options = {poUsePath})
    process.inputStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    process.errorStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    let (lines, exCode) = process.readLines()
    process.close()
    debug fmt"'{MDL_CMD}' run done."
    if exCode == 0:
      newCheckResult(CheckResultKind.Perfect)
    else:
      var issues: seq[CheckIssue] = @[]
      var explLines: seq[string] = @[]
      var issuesPart = true
      for line in lines:
        if line.len() == 0:
          issuesPart = false
          continue
        if issuesPart:
          issues.add(CheckIssue(
              severity: CheckIssueSeverity.Low,
              msg: some(line)
            ))
        else:
          explLines.add(line)
      if len(explLines) > 0:
        let msg = some(explLines.join("\n"))
        issues.add(CheckIssue(
            severity: CheckIssueSeverity.Info,
            msg: msg
          ))
      let fileExts = @["md", "markdown"]
      let fileExtsMaxParts = 1
      let matchingFiles = filterByExtensions(state.listFilesNonGenerated(), fileExts, fileExtsMaxParts)
      let numFiles = matchingFiles.len()
      let kind = if issues.len() > OK_NUM_ISSUES_PER_FILE * numFiles:
          CheckResultKind.Ok
        else:
          CheckResultKind.Acceptable
      CheckResult(
        kind: kind,
        issues: issues
      )
  except OSError as err:
    let msg = fmt("ERROR Failed to run '{MDL_CMD}'; make sure it is in your PATH: {err.msg}")
    newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.High, some(msg))

proc createDefault*(): Check =
  MarkdownLintCheck()
