# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import os
import options
import strutils
import strformat
import std/uri
import ../check
import ../state
import ../tools

type MdNoGlobalLinksToLocalFilesCheck = ref object of Check

method name*(this: MdNoGlobalLinksToLocalFilesCheck): string =
  return "No global links to local files"

method description*(this: MdNoGlobalLinksToLocalFilesCheck): string =
  return """Checks no links to project local files use a 'global' prefix,
be it a web-hosting URL or an absolute local path. \
This is in favor of a documentation that is as distributed/distributable as possible."""

method sourcePath*(this: MdNoGlobalLinksToLocalFilesCheck): string =
  return tools.srcFileName()

method requirements*(this: MdNoGlobalLinksToLocalFilesCheck): CheckReqs =
  return {
    CheckReq.FilesListRec,
  }

method getRatingFactors*(this: MdNoGlobalLinksToLocalFilesCheck): CheckRelevancy =
  return CheckRelevancy(
    weight: 0.4,
    openness: 0.8, # because it indicates how well the repo works offline/in a distributed environment
    hardware: 0.0,
    quality: 0.8,
    machineReadability: 0.8,
    )

method run*(this: MdNoGlobalLinksToLocalFilesCheck, state: var State): CheckResult =
  let mdFiles = filterByExtensions(state.listfiles(), @["md", "markdown"]) # TODO Make case-insensitive
  let links = try:
    extractMarkdownLinks(state.config, mdFiles)
  except IOError as err:
    let msg = fmt("Failed to extract Markdown links from docu: {err.msg}")
    return newCheckResult(CheckResultKind.Bad, CheckIssueImportance.Severe, some(msg))
  var issues = newSeq[CheckIssue]()
  let nl = "<br>&nbsp;"
  for link in links:
    for projGlobPref in state.config.projPrefixes:
      if link.target.startsWith(projGlobPref) and len(link.target) > len(projGlobPref) and not (len(link.target) - 1 == len(projGlobPref) and link.target[^1] == '/'):
        var newTarget = link.target
        let uri = parseUri(newTarget)
        if uri.scheme == "file":
          # "file://..." URL
          newTarget.removePrefix(projGlobPref)
          newTarget = relativePath(newTarget, projGlobPref)
        elif len(uri.scheme) > 0:
          # URL, but not a "file://..." one
          newTarget.removePrefix(projGlobPref)
        else:
          # file path
          newTarget = relativePath(link.target, projGlobPref)
        issues.add(CheckIssue(
          importance: CheckIssueImportance.Middle,
          msg: some(fmt"'{link.srcFile}':{link.srcLine}:{link.srcColumn}{nl}    '{link.target}'{nl}    ->{nl}    '{newTarget}'")))
        continue
  if len(issues) == 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    CheckResult(
      kind: CheckResultKind.Bad,
      issues: issues)

proc createDefault*(): Check =
  MdNoGlobalLinksToLocalFilesCheck()
