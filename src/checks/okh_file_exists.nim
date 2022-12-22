# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import strformat
from strutils import join
import os
import options
import re
import ../config
import ../check
import ../state
import ../tools

const OKH_FILE* = "okh.toml"
let R_OKH_FILE_V1 = re"okh(-.+)?.ya?ml"
let R_OKH_FILE_LOSH = re"okh(-.+)?.toml"
const OKH_TEMPLATE_TOML_URL = "https://github.com/OPEN-NEXT/OKH-LOSH/blob/master/sample_data/okh-TEMPLATE.toml"

proc okhFile*(config: RunConfig): string =
  return os.joinPath(config.proj_root, OKH_FILE)

type OkhFileExistsCheck = ref object of Check

method name*(this: OkhFileExistsCheck): string =
  return "OKH file exists"

method description*(this: OkhFileExistsCheck): string =
  return """Checks that the OKH manifest file - \
which contains project meta-data - \
exists."""

method requirements*(this: OkhFileExistsCheck): CheckReqs =
  return {
    CheckReq.FilesListL1,
  }


method run*(this: OkhFileExistsCheck, state: var State): CheckResult =
  if os.fileExists(okhFile(state.config)):
    return newCheckResult(CheckResultKind.Perfect)
  else:
    let nonDefaultTomls = filterPathsMatchingFileName(state.listFilesL1(), R_OKH_FILE_LOSH)
    if nonDefaultTomls.len() > 0:
      let presentTomls = nonDefaultTomls.join(", ")
      return newCheckResult(
          CheckResultKind.Bad,
          CheckIssueImportance.Light,
          some(fmt("While you have an OKH meta-data file ({presentTomls}),\nit is prefferable to use the specific file name '{OKH_FILE}'."))
        )
    else:
      let nonDefaultYamls = filterPathsMatchingFileName(state.listFilesL1(), R_OKH_FILE_V1)
      if nonDefaultYamls.len() > 0:
        let presentYamls = nonDefaultYamls.join(", ")
        return newCheckResult(
          CheckResultKind.Bad,
          CheckIssueImportance.Middle,
          some(fmt("While you have an OKH v1 meta-data file ({presentYamls}),\nit is prefferable to use the new OKH LOSH standard,\nwhich would result in having an '{OKH_FILE}'."))
        )
      else:
        return newCheckResult(
          CheckResultKind.Bad,
          CheckIssueImportance.Severe,
          some(fmt("Open Know-How meta-data file ({OKH_FILE}) not found.\nPlease consider creating it, if this is an OSH project.\nSee <{OKH_TEMPLATE_TOML_URL}> for a template.")) # TODO Add: "[Please consider] using the assistant (`osh okh`), or"
        )

proc createDefault*(): Check =
  OkhFileExistsCheck()
