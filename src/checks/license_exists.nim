# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

import strformat
import re
import options
import ../tools
import ../config
import ../check
import ../state

let R_LICENSE = re".*(LICENSE|COPYING).*"

type LicenseExistsCheck = ref object of Check

method name*(this: LicenseExistsCheck): string =
  return "LICENSE exists"

method run*(this: LicenseExistsCheck, config: RunConfig): CheckResult =
  let error = (if containsFiles(config.proj_root, R_LICENSE):
      none(string)
    else:
      some(fmt"No LICENSE (or COPYING) file found in the root directory. Please consider adding a LICENSE(.md). You might want to choose one from a list by issuing `osh init --license`.")
    )
  return CheckResult(error: error)

proc register*(state: var State) =
  state.registerCheck(LicenseExistsCheck())
