# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

import options
import ./config

type
  InitResult* = object
    error*: Option[string]
  UpdateResult* = object
    error*: Option[string]

type InitUpdate* = ref object of RootObj

method name*(this: InitUpdate): string {.base.} =
  return "TODO Override!"

method init*(this: InitUpdate, config: RunConfig): InitResult {.base, locks: "unknown".} =
  return InitResult(error: some("Not implemented for specific check!"))

method update*(this: InitUpdate, config: RunConfig): UpdateResult {.base.} =
  return UpdateResult(error: some("Not implemented for specific check!"))
