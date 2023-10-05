# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import httpclient
import os
import std/logging
import strutils
import strformat

proc download*(file: string, link: string, overwrite: bool = false) =
  if os.fileExists(file) and not overwrite:
    warn fmt"Not downloading '{link}'; File '{file}' already exists; leaving it as is. Use --force to overwrite."
    return
  var client = newHttpClient()
  try:
    var file_h = open(file, fmWrite)
    defer: file_h.close()
    file_h.write(client.getContent(link))
    info fmt"Compliance - downloaded '{link}' to '{file}'."
  except IOError as err:
    error fmt"Failed to download '{link}' to '{file}': " & err.msg
