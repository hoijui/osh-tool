# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

import strformat
import options
import ./check
import ./state

from checks/readme_exists import nil
from checks/license_exists import nil
from checks/okh_file_exists import nil

#proc logChecking(msg: string) =
#  stdout.writeLine(fmt"Checking {msg} ...")

#proc checkFailed(msg: string) =
#  stderr.writeLine(msg)

proc registerChecks*(state: var State) =
  readme_exists.register(state)
  license_exists.register(state)
  okh_file_exists.register(state)


proc check*(state: State) =
  echo "Checking OSH project directory ..."

  for check in state.checks:
    let res = check.run(state.config)
    if res.error.isNone():
      stdout.writeLine(fmt"Check - {check.name()}? - Succeeded")
    else:
      stderr.writeLine(fmt"Check - {check.name()}? - Failed ({res.error.get()})")
