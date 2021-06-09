# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

import strformat
import options
import ./init_update
import ./state

from init_update/readme import nil
from init_update/license import nil

proc registerInitUpdates*(state: var State) =
  readme.register(state)
  license.register(state)

proc init*(state: State) =
  echo "Initializing OSH project directory ..."

  for iu in state.init_updates:
    let res = iu.init(state.config)
    if res.error.isNone():
      stdout.writeLine(fmt"Init - {iu.name()}? - Succeeded")
    else:
      stderr.writeLine(fmt"Init - {iu.name()}? - Failed ({res.error.get()})")

proc update*(state: State) =
  echo "Updating OSH project directory to the latest guidelines ..."

  for iu in state.init_updates:
    let res = iu.update(state.config)
    if res.error.isNone():
      stdout.writeLine(fmt"Update - {iu.name()}? - Succeeded")
    else:
      stderr.writeLine(fmt"Update - {iu.name()}? - Failed ({res.error.get()})")
