# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import docopt
import options
import os
import std/logging
import std/sequtils
import std/sets
import tables
import ./util/leightweight
import ./util/run

type
  OutputFormat* = enum
    Csv
    MdList
    MdTable
    Json
  Report* = ref object of RootObj
    path*: Option[string]
    outputFormat*: OutputFormat

type
  CommonConfigOpt* = ref object
    ## This is designed to directly map
    ## to the (JSON) config file for a check run.
    ## It is used to parse that file only,
    ## after which the values in here get transferred to -
    ## extended with default-values where needed -
    ## the actual config container `RunConfig`.
    ## For a setting to be optional to define in the config file,
    ## it has to be wrapped with `Option[...]` in here.
    projRoot*: Option[string]
      ## The local file-system root of this project
      ## as an absolute, canonical path.
    projPrefixes*: Option[seq[string]]
      ## A list of roots/prefixes (excluding `projRoot`)
      ## this project might be found at.
      ## This are either absolute paths
      ## to directories on the local file-system,
      ## or web base-URLs.
      ## Examples:
      ## * /home/user/repos/myProj/
      ## * https://github.com/user/myProj/
      ## * NOT: https://user.github.io/myProj/
    projVars*: Option[TableRef[string, string]]
      ## Project specific properties, as produced by [`projvar`](https://github.com/hoijui/projvar/).
    reportTargets*: Option[seq[Report]]
      ## Where evaluation output gets written to.
      ## Stdout if None, else a file.
    force*: Option[bool]
      ## Whether output files get overwritten if they exist,
      ## or the application exits with an error.
    offline*: Option[bool]
      ## Whether to do everything without accessing the internet,
      ## and skip everything that does not work without it.
    electronics*: Option[bool]
      ## Whether to treat the project as an electronics project -
      ## meaning, one that contains schematics and PCB designs.
    mechanics*: Option[bool]

  CommonConfig* = ref object
    ## Same like `CommonConfigOpt`, but with certainty.
    projRoot*: string
    projPrefixes*: seq[string]
    projVars*: TableRef[string, string]
    reportTargets*: seq[Report]
    force*: bool
    offline*: bool
    electronics*: YesNoAuto
    mechanics*: YesNoAuto

proc new*(configType: typedesc[CommonConfigOpt]): CommonConfigOpt =
  return configType(
    projRoot: none[string](),
    projPrefixes: none[seq[string]](),
    projVars: none[TableRef[string, string]](),
    reportTargets: none[seq[Report]](),
    force: none[bool](),
    offline: none[bool](),
    electronics: none[bool](),
    mechanics: none[bool](),
  )

proc fromArgs*(configType: typedesc[CommonConfigOpt], args: Table[string, docopt.Value]): CommonConfigOpt =
  var config = configType.new()
  
  if args["-C"]:
    config.projRoot = some($args["-C"])

  var reportTargets = newSeq[Report]()
  for rep in  args["--report-csv"]:
    reportTargets.add(Report(path: some(rep), outputFormat: OutputFormat.Csv))
  for rep in args["--report-md-list"]:
    reportTargets.add(Report(path: some(rep), outputFormat: OutputFormat.MdList))
  for rep in  args["--report-md-table"]:
    reportTargets.add(Report(path: some(rep), outputFormat: OutputFormat.MdTable))
  for rep in  args["--report-json"]:
    reportTargets.add(Report(path: some(rep), outputFormat: OutputFormat.Json))
  let reportPaths = reportTargets.mapIt(it.path).filterIt(it.isSome).mapIt(it.get()).toHashSet()

  if reportTargets.len() > reportPaths.len():
    error "Duplicate report paths supplied; Please use each path only once!"
    raise newException(Defect, "Duplicate report paths supplied")

  if reportTargets.len() != 0:
    config.reportTargets = some(reportTargets)

  if args["--force"]:
    config.force = some(true)

  if args["--offline"]:
    config.offline = some(true)

  if args["--electronics"]:
    config.electronics = Yes.toOpt()
  elif args["--no-electronics"]:
    config.electronics = No.toOpt()

  if args["--mechanics"]:
    config.mechanics = Yes.toOpt()
  elif args["--no-mechanics"]:
    config.mechanics = No.toOpt()

  return config

proc defaultReport*() : Report =
  Report(path: none(string), outputFormat: OutputFormat.MdList)

proc extendWithDefaults*(this: CommonConfigOpt): CommonConfig =

  let projRoot = if this.projRoot.isSome():
      this.projRoot.get()
    else:
      os.getCurrentDir()

  var reportTargets = if this.reportTargets.isSome():
      var repTrgs = this.reportTargets.get()
      if repTrgs.len() == 0:
        repTrgs.add(defaultReport())
      repTrgs
    else:
      @[defaultReport()]

  if reportTargets.len() == 0:
    reportTargets.add(Report(path: none(string), outputFormat: OutputFormat.MdList))

  debug "Running projvar ..."
  let projVars = runProjvar(projRoot)

  return CommonConfig(
    projRoot: projRoot,
    projPrefixes: createProjectPrefixes(projRoot, projVars),
    projVars: projVars,
    reportTargets: reportTargets,
    force: this.force.get(false),
    offline: this.offline.get(false),
    electronics: YesNoAuto.fromOpt(this.electronics),
    mechanics: YesNoAuto.fromOpt(this.mechanics),
  )

proc toOpt*(this: CommonConfig): CommonConfigOpt =
  return CommonConfigOpt(
    projRoot: some(this.projRoot),
    projPrefixes: some(this.projPrefixes),
    reportTargets: some(this.reportTargets),
    force: some(this.force),
    offline: some(this.offline),
    electronics: this.electronics.toOpt(),
    mechanics: this.mechanics.toOpt(),
  )
