# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import re
import options
import strformat
import ../check
import ../state
import ../tools

let RS_LICENSE = "(?i)^.*(LICEN[SC]E|COPYING).*$"
let R_LICENSE = re(RS_LICENSE)

type LicenseExistsCheck = ref object of Check

method name*(this: LicenseExistsCheck): string =
  return "LICENSE exists"

method description*(this: LicenseExistsCheck): string =
  return fmt"""Checks that a LICENSE file exists in the projects root dir, \
using the regex `{RS_LICENSE}`.
Note that this is related to the REUSE lint check."""

method sourcePath*(this: LicenseExistsCheck): string =
  return tools.srcFileName()

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
 Please consider adding a LICENSE(.md).
 You might want to choose one from a list
 by issuing `osh init --license`.""")
    )
  )

proc createDefault*(): Check =
  LicenseExistsCheck()
