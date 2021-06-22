# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

import strformat
import ./check

from checks/readme_exists import nil
from checks/license_exists import nil
from checks/okh_file_exists import nil
from checks/unwanted_files_exist_not import nil

#proc logChecking(msg: string) =
#  stdout.writeLine(fmt"Checking {msg} ...")

#proc checkFailed(msg: string) =
#  stderr.writeLine(msg)

type
  ChecksRegistry* = object
    checks*: seq[Check]

method register*(this: var ChecksRegistry, check: Check) {.base.} =
  this.checks.add(check)

method registerChecks*(this: var ChecksRegistry) {.base.} =
  this.register(readme_exists.createDefault())
  this.register(license_exists.createDefault())
  this.register(okh_file_exists.createDefault())
  this.register(unwanted_files_exist_not.createDefault())

proc newChecksRegistry*(): ChecksRegistry =
  return ChecksRegistry(
    checks: @[],
    )
