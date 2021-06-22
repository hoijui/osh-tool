# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

import strformat
import ./init_update

from init_update/readme import nil
from init_update/license import nil

type
  InitUpdatesRegistry* = object
    initUpdates*: seq[InitUpdate]

method register*(this: var InitUpdatesRegistry, initUpdate: InitUpdate) {.base.} =
  this.initUpdates.add(initUpdate)

method registerInitUpdates*(this: var InitUpdatesRegistry) {.base.} =
  this.register(readme.createDefault())
  this.register(license.createDefault())

proc newInitUpdatesRegistry*(): InitUpdatesRegistry =
  return InitUpdatesRegistry(
    initUpdates: @[],
    )
