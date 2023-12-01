# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import os
import strformat
import system
import tables
import ../check
import ../check_config
import ../state
import ../util/fs

type
  Vcs = tuple
    name: string
    store: string
      ## Dir or file name of the store/cache
    distributed: bool
      ## Whether this describes a distributed (vs centralized) VCS

const IDS = @["vu", "vcsu", "vcs_used"]
const ID = IDS[0]

## The cache dir/file name for different VCS,
## and an indication whehter that VCS is distributed.
const STORE_FILE_OR_DIR_NAMES = [
  Vcs ( name: "git", store: ".git", distributed: true),
  Vcs ( name: "CVS", store: ".CVS", distributed: false),
  Vcs ( name: "SVN", store: ".SVN", distributed: false),
  Vcs ( name: "Mercurial", store: ".hg", distributed: true),
  Vcs ( name: "pijul", store: ".pijul", distributed: true),
  Vcs ( name: "DARCS", store: "_darcs", distributed: true),
  Vcs ( name: "Breezy (formerly Bazaar)", store: ".bzr", distributed: true),
]

type VcsUsedCheck = ref object of Check
type VcsUsedCheckGenerator = ref object of CheckGenerator

method name*(this: VcsUsedCheck): string =
  return "VCS is used"

method description*(this: VcsUsedCheck): string =
  return """Checks whether a Version Control System (VCS) \
is used to store the projects files, e.g. git, mercurial or pijul."""

method why*(this: VcsUsedCheck): string =
  return """

## What is a VCS

Version control is a system that maintains a history of changes.
What is packaged into a single, specific change,
(aka commit or patch),
is decided by the people that make the changes.
These changes should be small
and they should form logical units that make sense as a whole,
to the point where it makes no sense to divide them further.
A change might edit any number of files, delete some, and add others.
In the VCS, each change comes complete with a summary,
optional extensive description of the changes,
author info, timestamp and other details.
Thus, the VCS can tell you who changed what, when and why,
and it allows you to go back in time,
or create a new mix of changes:
an alternative history.
A specific change may also be marked as a version,
like '2.0' or '1.5.3-alpha'.

## What is it good for

To share the product documentation on versioning systems
is the most efficient, quality-rich way
to work in parallel within a distributed community.

Having the complete history
enables going back to previous versions
to help in root cause analysis for bugs
and it is crucial when needing to fix problems in older versions.

It allows also to connect reported bugs and project management software
to the relevant change(s),
which allows to see whether a particular version
contains a specific fix of a bug or feature.

Textual documentation can be edited online.
"""

method sourcePath*(this: VcsUsedCheck): string =
  return fs.srcFileName()

method requirements*(this: VcsUsedCheck): CheckReqs =
  return {
    CheckReq.FilesListL1,
  }

method getSignificanceFactors*(this: VcsUsedCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.7,
    openness: 1.0,
    hardware: 0.0,
    quality: 0.6,
    machineReadability: 0.8,
    )

method run*(this: VcsUsedCheck, state: var State): CheckResult =
  let config = state.config.checks[ID]
  var usedVcs = none(Vcs)
  for vcs in STORE_FILE_OR_DIR_NAMES:
    let storePath = os.joinPath(state.config.projRoot, vcs.store)
    if os.fileExists(storePath) or os.dirExists(storePath):
      usedVcs = some(vcs)
      break
  return
    if usedVcs.isSome():
      let vcs = usedVcs.get()
      if vcs.distributed:
        newCheckResult(config, CheckResultKind.Perfect)
      else:
        newCheckResult(
          config,
          CheckResultKind.Ok,
          CheckIssueSeverity.Low,
          some(fmt"""VCS detected ({vcs.name}), but it is not a distributed one
Please consider using a distributed one,
for example [git](https://git-scm.com/).""")
        )
    else:
      newCheckResult(
        config,
        CheckResultKind.Bad,
        CheckIssueSeverity.Middle,
        some("""No VCS detected.
Please consider using one,
for example [git](https://git-scm.com/).""")
      )

method id*(this: VcsUsedCheckGenerator): seq[string] =
  return IDS

method generate*(this: VcsUsedCheckGenerator, config: CheckConfig = newCheckConfig(ID)): Check =
  this.ensureNonConfig(config)
  VcsUsedCheck()

proc createGenerator*(): CheckGenerator =
  VcsUsedCheckGenerator()
