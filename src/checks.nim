# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import ./check
import ./tools

importAll("checks")

type
  ChecksRegistry* = object
    checks*: seq[Check]

method register*(this: var ChecksRegistry, check: Check) {.base.} =
  this.checks.add(check)

method registerChecks*(this: var ChecksRegistry) {.base.} =
  registerAll("checks")

proc newChecksRegistry*(): ChecksRegistry =
  return ChecksRegistry(
    checks: @[],
    )
