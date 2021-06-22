# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

from strutils import join
import os
import options
import re
import ../config
import ../tools
import ../init_update
import ../state

const README_TEMPLATE_URL = "https://raw.githubusercontent.com/othneildrew/Best-README-Template/master/BLANK_README.md"
let R_README = re".*README.*"

type ReadmeInitUpdate = ref object of InitUpdate

method name(this: ReadmeInitUpdate): string =
  return "README"

method init(this: ReadmeInitUpdate, state: var State): InitResult =
  if not state.config.readme and filterPathsMatchingFileName(state.listFilesL1(), R_README).len() > 0:
    result = InitResult(error: some("Not generating README.md, because README(s) are already present: " &
        filterPathsMatchingFileName(state.listFilesL1(), R_README).join(", ")))
  else:
    let readmeMd = os.joinPath(state.config.projRoot, "README.md")
    if os.fileExists(readmeMd) and not state.config.force:
      result = InitResult(error: some("Not generating README.md, because the file already exists."))
    else:
      downloadTemplate(state.config, "README.md", README_TEMPLATE_URL) # TODO Have multiple file options, and a way to choose from them, maybe?
      result = InitResult(error: none(string))
  return result

method update(this: ReadmeInitUpdate, state: var State): UpdateResult =
  return UpdateResult(error: some("Not yet implemented!"))

proc createDefault*(): InitUpdate =
  ReadmeInitUpdate()
