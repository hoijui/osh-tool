# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

import strformat
import re
import options
import ../tools
import ../config
import ../check
import ../state

let R_README = re".*README.*"

type ReadmeExistsCheck = ref object of Check

method name(this: ReadmeExistsCheck): string =
  return "README exists"

method run(this: ReadmeExistsCheck, config: RunConfig): CheckResult =
  let error = (if containsFiles(config.proj_root, R_README):
      none(string)
    else:
      some(fmt"No README file found in the root directory. Please consider adding a README.md. You might want to generate a template by issuing `osh init --readme`, or manually reating it.")
    )
  return CheckResult(error: error)

proc register*(state: var State) =
  state.registerCheck(ReadmeExistsCheck())
