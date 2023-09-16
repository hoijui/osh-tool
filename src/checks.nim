# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import ./check
import ./tools
import tables

importAll("checks")

type
  ChecksRegistry* = object
    checks*: OrderedTable[string, Check]

method register*(this: var ChecksRegistry, check: Check) {.base.} =
  this.checks[check.id()[0]] = check

method sort*(this: var ChecksRegistry) {.base.} =
  this.checks.sort(proc (x, y: (string, Check)): int = cmp(x[0], y[0]))

method registerChecks*(this: var ChecksRegistry) {.base.} =
  registerAll("checks")

proc newChecksRegistry*(): ChecksRegistry =
  return ChecksRegistry(
    checks: initOrderedTable[string, Check](),
    )
