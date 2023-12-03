# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

from strutils import join
import options
import re
import strformat
import ../config
import ../tools
import ../init_update
import ../init_update_config
import ../invalid_config_exception
import ../state

const LICENSE_GUIDE_URL = "TODO-Licensing-Guide-URL" # TODO
const REUSE_URL = "https://github.com/fsfe/reuse-tool"
let R_LICENSE = re"(?i)^.*(LICENSE|COPYING).*$"
#const IDS = @[srcFileNameBase(), "li", "license"]
const ID = srcFileNameBase()

type LicenseInitUpdate = ref object of InitUpdate
type LicenseInitUpdateGenerator = ref object of InitUpdateGenerator

method name(this: LicenseInitUpdate): string =
  return "LICENSE"

method init(this: LicenseInitUpdate, state: var State): InitResult =
  if not state.config.license and filterPathsMatchingFileName(state.listFilesL1(), R_LICENSE).len() > 0:
    result = InitResult(kind: Note, msg: some("Not generating LICENSE.txt, because LICENSE(s) are already present: " &
        filterPathsMatchingFileName(state.listFilesL1(), R_LICENSE).join(", ")))
  else:
    result = InitResult(kind: Warning, msg: some(fmt"Please use the REUSE tool (<{REUSE_URL}>) for handling licensing, and choose Licenses using <{LICENSE_GUIDE_URL}>."))
  return result

method update(this: LicenseInitUpdate, state: var State): UpdateResult =
  return UpdateResult(kind: Note, msg: some(fmt"Licenses need to be updated manually, see the REUSE tools documentation: <{REUSE_URL}>"))

method id*(this: LicenseInitUpdateGenerator): seq[string] =
  return ID

method generate*(this: LicenseInitUpdateGenerator, config: Option[InitUpdateConfig] = none[InitUpdateConfig]()): InitUpdate =
  if config.isSome:
    raise InvalidConfigException.newException("This init&update does not take any configuration")
  LicenseInitUpdate()

proc createGenerator*(): InitUpdateGenerator =
  LicenseInitUpdateGenerator()
