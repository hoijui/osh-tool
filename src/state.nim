# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

import ./config
import ./check
import ./init_update

type
  State* = object
    config*: RunConfig
    checks*: seq[Check]
    initUpdates*: seq[InitUpdate]

method registerCheck*(this: var State, check: Check) {.base.} =
  this.checks.add(check)

method registerInitUpdate*(this: var State, initUpdate: InitUpdate) {.base.} =
  this.initUpdates.add(initUpdate)
