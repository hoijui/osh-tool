# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

from strutils import join
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

method init(this: LicenseInitUpdate, state: var State): InitResult =
  if not state.config.license and filterPathsMatchingFileName(state.listFilesL1(), R_LICENSE).len() > 0:
    result = InitResult(error: some("Not generating LICENSE.md, because LICENSE(s) are already present: " &
        filterPathsMatchingFileName(state.listFilesL1(), R_LICENSE).join(", ")))
  else:
    let license_md = os.joinPath(state.config.proj_root, "LICENSE.md")
    if os.fileExists(license_md) and not state.config.force:
      result = InitResult(error: some("Not generating LICENSE.md, because the file already exists."))
    else:
      downloadTemplate(state.config, "LICENSE.md", LICENSE_TEMPLATE_URL) # TODO Have multiple file options, and a way to choose from them, maybe?
      result = InitResult(error: none(string))
  return result

method update(this: LicenseInitUpdate, state: var State): UpdateResult =
  return UpdateResult(error: some("Not yet implemented!"))

proc createDefault*(): InitUpdate =
  LicenseInitUpdate()
