# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import re
import strformat
import ../check
import ../check_config
import ../state
import ../util/fs

const IDS = @["le", "licex", "license_exists"]
const ID = IDS[0]
let RS_LICENSE = "(?i)^.*(LICEN[SC]E|COPYING).*$"
let R_LICENSE = re(RS_LICENSE)

type LicenseExistsCheck = ref object of Check
type LicenseExistsCheckGenerator = ref object of CheckGenerator

method name*(this: LicenseExistsCheck): string =
  return "LICENSE exists"

method description*(this: LicenseExistsCheck): string =
  return fmt"""Checks that a LICENSE file exists in the projects root dir, \
using the regex `{RS_LICENSE}`.
Note that this is related to the REUSE lint check."""

method why*(this: LicenseExistsCheck): string =
  return """Before REUSE, this was the standard (and only) way
to declare which license(s) are used within the project.
While REUSE is in all ways superior to this approach,
Many platforms and softwares still purely rely on this way
to automatically detect the license(s) of a project.
We thus recommend to keep the "main"
(according ot your subjective decission)
license of the project in such a file,
by first fixing REUSE for the project,
and then running a command similar to:
`cp LICENSES/CERN-OHL-S-2.0.txt LICENSE.txt`"""

method sourcePath*(this: LicenseExistsCheck): string =
  return fs.srcFileName()

method requirements*(this: LicenseExistsCheck): CheckReqs =
  return {
    CheckReq.FilesListL1,
  }

method getSignificanceFactors*(this: LicenseExistsCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.2,
    openness: 1.0,
    hardware: 0.0,
    quality: 0.05,
    machineReadability: 1.0,
    )

method run*(this: LicenseExistsCheck, state: var State): CheckResult =
  # TODO Add checks for REUSE bom, or check the output of `reuse --lint`
  return (if filterPathsMatching(state.listFilesL1(), R_LICENSE).len > 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    newCheckResult(
      CheckResultKind.Bad,
      CheckIssueSeverity.High,
      some("""No LICENSE (or COPYING) file found in the root directory.
 Please consider adding a LICENSE(.md).""")
    )
  )

method id*(this: LicenseExistsCheckGenerator): seq[string] =
  return IDS

method generate*(this: LicenseExistsCheckGenerator, config: CheckConfig = CheckConfig(id: this.id()[0], json: none[string]())): Check =
  this.ensureNonConfig(config)
  LicenseExistsCheck()

proc createGenerator*(): CheckGenerator =
  LicenseExistsCheckGenerator()
