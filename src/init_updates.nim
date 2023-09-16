# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import ./init_update
import ./tools

importAll("init_update")

type
  InitUpdatesRegistry* = object
    initUpdates*: seq[InitUpdate]

method register*(this: var InitUpdatesRegistry, initUpdate: InitUpdate) {.base.} =
  this.initUpdates.add(initUpdate)

method sort*(this: var InitUpdatesRegistry) {.base.} =
  discard

method registerInitUpdates*(this: var InitUpdatesRegistry) {.base.} =
  registerAll("init_update")

proc newInitUpdatesRegistry*(): InitUpdatesRegistry =
  return InitUpdatesRegistry(
    initUpdates: @[],
    )
