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

const README_TEMPLATE_URL = "https://raw.githubusercontent.com/othneildrew/Best-README-Template/master/BLANK_README.md"
let R_README = re".*README.*"

type ReadmeInitUpdate = ref object of InitUpdate

method name(this: ReadmeInitUpdate): string =
  return "README"

method init(this: ReadmeInitUpdate, config: RunConfig): InitResult =
  if not config.readme and containsFiles(config.proj_root, R_README):
    result = InitResult(error: some("Not generating README.md, because README(s) are already present: " & toSeq(listFiles(config.proj_root, R_README)).join(", ")))
  else :
    let readme_md = os.joinPath(config.proj_root, "README.md")
    if os.fileExists(readme_md) and not config.force:
      result = InitResult(error: some("Not generating README.md, because the file already exists."))
    else:
      downloadTemplate(config, "README.md", README_TEMPLATE_URL) # TODO Have multiple file options, and a way to choose from them, maybe?
      result = InitResult(error: none(string))
  return result

method update(this: ReadmeInitUpdate, config: RunConfig): UpdateResult =
  return UpdateResult(error: some("Not yet implemented!"))

proc register*(state: var State) =
  state.registerInitUpdate(ReadmeInitUpdate())
