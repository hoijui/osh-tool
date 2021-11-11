# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import os
import re
import sequtils
import strutils
import ./config
import ./check
import ./init_update
import ./tools as tools

type
  Registry* = object
    checks*: seq[Check]
    initUpdates*: seq[InitUpdate]

method registerCheck*(this: var State, check: Check) {.base.} =
  this.checks.add(check)

method registerInitUpdate*(this: var State, initUpdate: InitUpdate) {.base.} =
  this.initUpdates.add(initUpdate)

proc newRegistry*(config: RunConfig): State =
  return State(
    checks: @[],
    initUpdates: @[],
    )
