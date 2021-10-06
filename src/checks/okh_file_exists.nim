# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

import strformat
import os
import options
import ../config
import ../check
import ../state

const OKH_FILE = "okh.toml"
const OKH_URL = "TODO-OKHv2-URL" # TODO Insert OKH docu URL here

proc okhFile(config: RunConfig): string =
  return os.joinPath(config.proj_root, OKH_FILE)

type OkhFileExistsCheck = ref object of Check

method name*(this: OkhFileExistsCheck): string =
  return "OKH file exists"

method run*(this: OkhFileExistsCheck, state: var State): CheckResult =
  let error = (if os.fileExists(okhFile(state.config)):
    none(string)
  else:
    some(fmt"Open Know-How meta-data file ({OKH_FILE}) not found. Please consider using the assistant (`osh okh`), or manually reating it. See <{OKH_URL}> for more information about OKH.")
  )
  return CheckResult(error: error)

proc createDefault*(): Check =
  OkhFileExistsCheck()
