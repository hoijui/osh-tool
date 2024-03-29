# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

from strutils import join
import os
import options
import re
import ../config
import ../tools
import ../init_update
import ../init_update_config
import ../invalid_config_exception
import ../state

const README_TEMPLATE_URL = "https://raw.githubusercontent.com/othneildrew/Best-README-Template/master/BLANK_README.md"
let R_README = re".*README.*"
#const IDS = @[srcFileNameBase(), "re", "readme"]
const ID = srcFileNameBase()

type ReadmeInitUpdate = ref object of InitUpdate
type ReadmeInitUpdateGenerator = ref object of InitUpdateGenerator

method name(this: ReadmeInitUpdate): string =
  return "README"

method init(this: ReadmeInitUpdate, state: var State): InitResult =
  if not state.config.readme and filterPathsMatchingFileName(state.listFilesL1(), R_README).len() > 0:
    result = InitResult(kind: Note, msg: some("Not generating README.md, because README(s) are already present: " &
        filterPathsMatchingFileName(state.listFilesL1(), R_README).join(", ")))
  else:
    let readmeMd = os.joinPath(state.config.projRoot, "README.md")
    if os.fileExists(readmeMd) and not state.config.force:
      result = InitResult(kind: Note, msg: some("Not generating README.md, because the file already exists."))
    else:
      downloadTemplate(state.config, "README.md", README_TEMPLATE_URL) # TODO Have multiple file options, and a way to choose from them, maybe?
      result = InitResult(kind: Compliance, msg: none(string))
  return result

method update(this: ReadmeInitUpdate, state: var State): UpdateResult =
  return UpdateResult(kind: Error, msg: some("Not yet implemented!")) # TODO

method id*(this: ReadmeInitUpdateGenerator): seq[string] =
  return ID

method generate*(this: ReadmeInitUpdateGenerator, config: Option[InitUpdateConfig] = none[InitUpdateConfig]()): InitUpdate =
  if config.isSome:
    raise InvalidConfigException.newException("This init&update does not take any configuration")
  ReadmeInitUpdate()

proc createGenerator*(): InitUpdateGenerator =
  ReadmeInitUpdateGenerator()
