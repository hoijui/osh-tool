# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import re
import options
import strformat
import ../tools
import ../check
import ../state

# Requires "LICENSE" or "COPYING" (case-insensitive)
# to appear somewhere in the file name.
let RS_LICENSE = "(?i)^.*(LICENSE|COPYING).*$"
let R_LICENSE = re(RS_LICENSE)

type LicenseExistsCheck = ref object of Check

method name*(this: LicenseExistsCheck): string =
  return "LICENSE exists"

method description*(this: LicenseExistsCheck): string =
  return fmt"""Checks that a LICENSE file exists in the projects root dir, \
using the regex `{RS_LICENSE}`.
Note that this is related to the REUSE lint check."""

method requirements*(this: LicenseExistsCheck): CheckReqs =
  return {
    CheckReq.FilesListL1,
  }

method run*(this: LicenseExistsCheck, state: var State): CheckResult =
  # TODO Add checks for REUSE bom, or check the output of `reuse --lint`
  return (if filterPathsMatching(state.listFilesL1(), R_LICENSE).len > 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    newCheckResult(
      CheckResultKind.Bad,
      CheckIssueImportance.Severe,
      some("No LICENSE (or COPYING) file found in the root directory.\nPlease consider adding a LICENSE(.md).\nYou might want to choose one from a list by issuing `osh init --license`.")
    )
  )

proc createDefault*(): Check =
  LicenseExistsCheck()
