# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import strformat
import re
import options
import ../tools
import ../check
import ../state

let R_LICENSE = re"^.*(LICENSE|COPYING).*$"

type LicenseExistsCheck = ref object of Check

method name*(this: LicenseExistsCheck): string =
  return "LICENSE exists"

method run*(this: LicenseExistsCheck, state: var State): CheckResult =
  return (if filterPathsMatching(state.listFilesL1(), R_LICENSE).len > 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    newCheckResult(
      CheckResultKind.Bad,
      CheckIssueWeight.Heavy,
      some(fmt"No LICENSE (or COPYING) file found in the root directory. Please consider adding a LICENSE(.md). You might want to choose one from a list by issuing `osh init --license`.")
    )
  )

proc createDefault*(): Check =
  LicenseExistsCheck()
