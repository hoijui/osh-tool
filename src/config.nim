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
    ## A list of roots/prefixes (excluding `projRoot`)
    ## this project might be found at,
    ## either absolute paths to directories on the local file-system
    ## or web base-URLs.
    ## Examples:
    ## * /home/user/repos/myProj/
    ## * https://user.github.com/myProj/
    projPrefixes*: seq[string]
    ## Where evaluation output gets written to.
    ## Stdout if None, else a file.
    reportTargets*: seq[Report]
    ## Whether output files get overwritten if they exist,
    ## or the application exits with an error.
    force*: bool
    readme*: bool
    license*: bool
    offline*: bool
    electronics*: YesNoAuto
    mechanics*: YesNoAuto
