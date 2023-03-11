# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options

type
  YesNoAuto* = enum
    Yes
    No
    Auto
  Command* = enum
    Check
    Init
    Update
  OutputFormat* = enum
    Csv
    MdList
    MdTable
    Json
  Report* = ref object of RootObj
    path*: Option[string]
    outputFormat*: OutputFormat

type
  RunConfig* = object
    command*: Command
    projRoot*: string
    projPrefixes*: seq[string]
      ## A list of roots/prefixes (excluding `projRoot`)
      ## this project might be found at.
      ## This are either absolute paths
      ## to directories on the local file-system,
      ## or web base-URLs.
      ## Examples:
      ## * /home/user/repos/myProj/
      ## * https://github.com/user/myProj/
      ## * NOT: https://user.github.io/myProj/
    reportTargets*: seq[Report]
      ## Where evaluation output gets written to.
      ## Stdout if None, else a file.
    force*: bool
      ## Whether output files get overwritten if they exist,
      ## or the application exits with an error.
    readme*: bool
    license*: bool
    offline*: bool
    electronics*: YesNoAuto
    mechanics*: YesNoAuto
