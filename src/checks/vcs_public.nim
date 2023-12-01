# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# import httpclient
import options
# import os
import strformat
import system
import ../check
import ../check_config
import ../config_cmd_check
import ../state
import ../util/fs
import ./vcs_used
import std/logging
import std/osproc
import std/streams
import std/tables

const IDS = @["vp", "vcsp", "vcspub", "vcs_pub", "vcs_public"]
const ID = IDS[0]
const IS_PUB_CMD = "is-git-forge-public"
const NOT_YOUR_FAULT = "This is not your fault; please report it!"
const PV_URL_KEY = "REPO_WEB_URL"

type VcsPublicCheck = ref object of Check
type VcsPublicCheckGenerator = ref object of CheckGenerator

method name*(this: VcsPublicCheck): string =
  return "VCS public"

method description*(this: VcsPublicCheck): string =
  return """Checks whether the Version Control System (VCS) \
is publicly available, and without requiring authentication."""

method why*(this: VcsPublicCheck): string =
  return """A public VCS (e.g. a git repo on GitHub) -
while somewhat challenging to use for some people -
currently (May 2023) is the best way to colaboratively work on Open Source projects together.

It allows to track changes in parallel,
to see who did what when and why (if use right).

Without a public VCS, the project develoment is reserved for "the elite" that is allowed access to it,
or alternatively - and maybe even worse - the development is split up and happening in parallel,
without a good way of sharing the fruits of labout of that process.
"""

method sourcePath*(this: VcsPublicCheck): string =
  return fs.srcFileName()

method requirements*(this: VcsPublicCheck): CheckReqs =
  return {
    CheckReq.ProjMetaData,
  }

method getSignificanceFactors*(this: VcsPublicCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.7,
    openness: 1.0,
    hardware: 0.0,
    quality: 0.6,
    machineReadability: 0.0,
    )

method run*(this: VcsPublicCheck, state: var State): CheckResult =
  let vcsUsedGen = vcs_used.createGenerator()
  let vcsUsedId = vcsUsedGen.id()[0]
  let vcsUsedConfig = ConfigCmdCheck(state.config).checks.getOrDefault(vcsUsedId, CheckConfig(id: vcsUsedId, json: none[string]()))
  let vcsUsedResult = vcsUsedGen.generate(vcsUsedConfig).run(state)
  if not vcsUsedResult.isGood():
    let msg = fmt"""Project does not use a VCS, \
so it could not possibly be publicly hosted."""
    return newCheckResult(CheckResultKind.Inapplicable, CheckIssueSeverity.High, some(msg))
  # TODO Support other VCS then git
  if not state.config.projVars.hasKey(PV_URL_KEY):
    let msg = fmt"""Project meta-data property '{PV_URL_KEY}' is not available; \
You might not be using a local and public git repo to host this project, \
or the projvar tool fails to find it for some reason.
We currently only support the git VCS in this check."""
    return newCheckResult(CheckResultKind.Inapplicable, CheckIssueSeverity.High, some(msg))
  let publicGitRepoWebUrl = state.config.projVars[PV_URL_KEY]
  try: # TODO Move ths to ./util/run
    debug fmt"Now running '{IS_PUB_CMD}' ..."
    let process = osproc.startProcess(
      command = IS_PUB_CMD,
      workingDir = state.config.projRoot,
      args = [publicGitRepoWebUrl],
      env = nil,
      options = {poUsePath})
    process.inputStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    process.errorStream.close() # NOTE **Essential** - This prevents hanging/freezing when reading stdout below
    let (lines, exCode) = process.readLines()
    process.close()
    debug fmt"'{IS_PUB_CMD}' run done."
    if exCode == 0:
      let firstLine = lines[0]
      let isPublicOpt =
        if firstLine == "true":
          some(true)
        elif firstLine == "false":
          some(false)
        else:
          none(bool)
      if isPublicOpt.isNone():
        let msg = fmt"""Failed to parse output of '{IS_PUB_CMD}'. \
The first line should be 'true' or 'false', but was:
'{firstLine}'
""" & NOT_YOUR_FAULT
        newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.High, some(msg))
      else:
        let isPublic = isPublicOpt.get()
        if isPublic:
          newCheckResult(CheckResultKind.Perfect)
        else:
          newCheckResult(CheckResultKind.Perfect)
    else:
      let msg = fmt"""Failed to run '{IS_PUB_CMD}'.
exit code: {exCode}
""" & NOT_YOUR_FAULT
      newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.High, some(msg))
  except OSError as err:
    let msg = fmt"""Failed to run '{IS_PUB_CMD}'.
error message:
'{err.msg}'
""" & NOT_YOUR_FAULT
    newCheckResult(CheckResultKind.Bad, CheckIssueSeverity.High, some(msg))

method id*(this: VcsPublicCheckGenerator): seq[string] =
  return IDS

method generate*(this: VcsPublicCheckGenerator, config: CheckConfig = newCheckConfig(ID)): Check =
  this.ensureNonConfig(config)
  VcsPublicCheck()

proc createGenerator*(): CheckGenerator =
  VcsPublicCheckGenerator()
