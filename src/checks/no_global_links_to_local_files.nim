# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2022-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import os
import std/uri
import strformat
import strutils
import tables
import ../check
import ../check_config
import ../state
import ../util/fs
import ../util/run

#const IDS = @[srcFileNameBase(), "mdngltlf", "mdnogloblinks", "md_no_global_links", "md_no_global_links_to_local_files"]
const ID = srcFileNameBase()

type MdNoGlobalLinksToLocalFilesCheck = ref object of Check
type MdNoGlobalLinksToLocalFilesCheckGenerator = ref object of CheckGenerator

method name*(this: MdNoGlobalLinksToLocalFilesCheck): string =
  return "No global links to local files"

method description*(this: MdNoGlobalLinksToLocalFilesCheck): string =
  return """Checks no links to project local files use a 'global' prefix,
be it a web-hosting URL or an absolute local path."""

method why*(this: MdNoGlobalLinksToLocalFilesCheck): string =
  return """This is a step towards a documentation that is:

- locally browsable an editable without internet connection
- showing and linking to the actual, local, correct content"""

method sourcePath*(this: MdNoGlobalLinksToLocalFilesCheck): string =
  return fs.srcFileName()

method requirements*(this: MdNoGlobalLinksToLocalFilesCheck): CheckReqs =
  return {
    CheckReq.FilesListRec,
    CheckReq.ExternalTool,
  }

method getSignificanceFactors*(this: MdNoGlobalLinksToLocalFilesCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.4,
    # because it indicates how well the repo works offline,
    # or say: in a distributed environment
    openness: 0.8,
    hardware: 0.0,
    quality: 0.8,
    machineReadability: 0.8,
    )

method run*(this: MdNoGlobalLinksToLocalFilesCheck, state: var State): CheckResult =
  let config = state.config.checks[ID]
  let mdFiles = filterByExtensions(state.listfiles(), @["md", "markdown"]) # TODO Make case-insensitive
  let links = try:
    extractMarkdownLinks(state.config.projRoot, mdFiles)
  except IOError as err:
    let msg = fmt("Failed to extract Markdown links from docu: {err.msg}")
    return newCheckResult(config, CheckResultKind.Bad, CheckIssueSeverity.High, some(msg))
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
          severity: CheckIssueSeverity.Middle,
          msg: some(fmt"'{link.srcFile}':{link.srcLine}:{link.srcColumn}{nl}    '{link.target}'{nl}    ->{nl}    '{newTarget}'")))
        continue
  if len(issues) == 0:
    newCheckResult(config, CheckResultKind.Perfect)
  else:
    CheckResult(
      config: config,
      kind: CheckResultKind.Bad,
      issues: issues)

method id*(this: MdNoGlobalLinksToLocalFilesCheckGenerator): string =
  return ID

method generate*(this: MdNoGlobalLinksToLocalFilesCheckGenerator, config: CheckConfig = this.defaultConfig()): Check =
  this.ensureNonConfig(config)
  MdNoGlobalLinksToLocalFilesCheck()

proc createGenerator*(): CheckGenerator =
  MdNoGlobalLinksToLocalFilesCheckGenerator()
