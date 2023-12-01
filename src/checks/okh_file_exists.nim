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
import tables
import ../config_cmd_check
import ../check
import ../check_config
import ../state
import ../util/fs

const IDS = @["oe", "okhex", "okh_file_exists"]
const ID = IDS[0]
const OKH_FILE* = "okh.toml"
let R_OKH_FILE_V1 = re"okh(-.+)?.ya?ml"
let R_OKH_FILE_LOSH = re"okh(-.+)?.toml"
const OKH_TEMPLATE_TOML_URL = "https://github.com/OPEN-NEXT/OKH-LOSH/blob/master/sample_data/okh-TEMPLATE.toml"
const OKH_TOOL_URL = "https://github.com/OPEN-NEXT/LOSH-OKH-tool/"

proc okhFile*(config: ConfigCmdCheck): string =
  return os.joinPath(config.projRoot, OKH_FILE)

type OkhFileExistsCheck = ref object of Check
type OkhFileExistsCheckGenerator = ref object of CheckGenerator

method name*(this: OkhFileExistsCheck): string =
  return "OKH file exists"

method description*(this: OkhFileExistsCheck): string =
  return """Checks that the OKH manifest file - \
which contains project meta-data - \
exists."""

method why*(this: OkhFileExistsCheck): string =
  return """If this is actually a hardware project,
the existence of this file clearly and unmistakingly marks it as such,
both for humans and machines/software.

This is useful when dealing with a lot of projects,
to not waste life- or processing-time,
which likely would still be less exact in its findings."""

method sourcePath*(this: OkhFileExistsCheck): string =
  return fs.srcFileName()

method requirements*(this: OkhFileExistsCheck): CheckReqs =
  return {
    CheckReq.FilesListL1,
  }

method getSignificanceFactors*(this: OkhFileExistsCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.7,
    openness: 1.0,
    hardware: 1.0,
    quality: 0.5,
    machineReadability: 1.0,
    )

method run*(this: OkhFileExistsCheck, state: var State): CheckResult =
  let config = state.config.checks[ID]
  if os.fileExists(okhFile(state.config)):
    return newCheckResult(config, CheckResultKind.Perfect)
  else:
    let nonDefaultTomls = filterPathsMatchingFileName(state.listFilesL1(), R_OKH_FILE_LOSH)
    if nonDefaultTomls.len() > 0:
      let presentTomls = nonDefaultTomls.join(", ")
      return newCheckResult(
          config,
          CheckResultKind.Bad,
          CheckIssueSeverity.Low,
          some(fmt("While you have an OKH meta-data file ({presentTomls}),\nit is prefferable to use the specific file name '{OKH_FILE}'."))
        )
    else:
      let nonDefaultYamls = filterPathsMatchingFileName(state.listFilesL1(), R_OKH_FILE_V1)
      if nonDefaultYamls.len() > 0:
        let presentYamls = nonDefaultYamls.join(", ")
        return newCheckResult(
          config,
          CheckResultKind.Bad,
          CheckIssueSeverity.Middle,
          some(fmt("While you have an OKH v1 meta-data file ({presentYamls}),\nit is prefferable to use the new OKH LOSH standard.\nYou may want to use the okh-tool (<{OKH_TOOL_URL}>) to convert your OKH v1 '{presentYamls}' to an OKH-LOSH '{OKH_FILE}'."))
        )
      else:
        return newCheckResult(
          config,
          CheckResultKind.Bad,
          CheckIssueSeverity.High,
          some(fmt("Open Know-How meta-data file ({OKH_FILE}) not found.\nPlease consider creating it, if this is an OSH project.\nSee <{OKH_TEMPLATE_TOML_URL}> for a template.")) # TODO Add: "[Please consider] using the assistant (`osh okh`), or"
        )

method id*(this: OkhFileExistsCheckGenerator): seq[string] =
  return IDS

method generate*(this: OkhFileExistsCheckGenerator, config: CheckConfig = newCheckConfig(ID)): Check =
  this.ensureNonConfig(config)
  OkhFileExistsCheck()

proc createGenerator*(): CheckGenerator =
  OkhFileExistsCheckGenerator()
