# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

from strutils import join
import sequtils
import os
import options
import re
import ../config
import ../tools
import ../init_update
import ../state

const LICENSE_TEMPLATE_URL = "TODO"
let R_LICENSE = re".*(LICENSE|COPYING).*"

type LicenseInitUpdate = ref object of InitUpdate

method name(this: LicenseInitUpdate): string =
  return "LICENSE"

method init(this: LicenseInitUpdate, config: RunConfig): InitResult =
  if not config.license and containsFiles(config.proj_root, R_LICENSE):
    result = InitResult(error: some("Not generating LICENSE.md, because LICENSE(s) are already present: " & toSeq(listFiles(config.proj_root, R_LICENSE)).join(", ")))
  else :
    let license_md = os.joinPath(config.proj_root, "LICENSE.md")
    if os.fileExists(license_md) and not config.force:
      result = InitResult(error: some("Not generating LICENSE.md, because the file already exists."))
    else:
      downloadTemplate(config, "LICENSE.md", LICENSE_TEMPLATE_URL) # TODO Have multiple file options, and a way to choose from them, maybe?
      result = InitResult(error: none(string))
  return result

method update(this: LicenseInitUpdate, config: RunConfig): UpdateResult =
  return UpdateResult(error: some("Not yet implemented!"))

proc register*(state: var State) =
  state.registerInitUpdate(LicenseInitUpdate())
