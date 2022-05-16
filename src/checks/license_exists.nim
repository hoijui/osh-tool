# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import re
import options
import ../tools
import ../check
import ../state

# Requires "LICENSE" or "COPYING" (case-insensitive)
# to appear somewhere in the file name.
let R_LICENSE = re"(?i)^.*(LICENSE|COPYING).*$"

type LicenseExistsCheck = ref object of Check

method name*(this: LicenseExistsCheck): string =
  return "LICENSE exists"

method requirements*(this: Check): CheckReqs =
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
      CheckIssueWeight.Heavy,
      some("No LICENSE (or COPYING) file found in the root directory.\nPlease consider adding a LICENSE(.md).\nYou might want to choose one from a list by issuing `osh init --license`.")
    )
  )

proc createDefault*(): Check =
  LicenseExistsCheck()
