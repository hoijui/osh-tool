# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

import options
import ./state

type
  CheckResult* = object
    error*: Option[string]

type Check* = ref object of RootObj

method name*(this: Check): string {.base.} =
  return "TODO Override!"

method run*(this: Check, state: var State): CheckResult {.base,
    locks: "unknown".} =
  return CheckResult(error: some("Not implemented for specific check!"))
