# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

from strutils import join
import options
import re
import strformat
import ../config
import ../tools
import ../init_update
import ../state

const LICENSE_GUIDE_URL = "TODO-Licensing-Guide-URL" # TODO
const REUSE_URL = "https://github.com/fsfe/reuse-tool"
let R_LICENSE = re".*(LICENSE|COPYING).*"

type LicenseInitUpdate = ref object of InitUpdate

method name(this: LicenseInitUpdate): string =
  return "LICENSE"

method init(this: LicenseInitUpdate, state: var State): InitResult =
  if not state.config.license and filterPathsMatchingFileName(state.listFilesL1(), R_LICENSE).len() > 0:
    result = InitResult(error: some("Not generating LICENSE.md, because LICENSE(s) are already present: " &
        filterPathsMatchingFileName(state.listFilesL1(), R_LICENSE).join(", ")))
  else:
    result = InitResult(error: some(fmt"Please use the REUSE tool (<{REUSE_URL}>) for handling licensing, and choose Licenses using <{LICENSE_GUIDE_URL}>."))
  return result

method update(this: LicenseInitUpdate, state: var State): UpdateResult =
  return UpdateResult(error: some(fmt"Licenses need to be updated manually, see the REUSE tools documentation: <{REUSE_URL}>"))

proc createDefault*(): InitUpdate =
  LicenseInitUpdate()
