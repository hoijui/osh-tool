# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import docopt
import results
import options
import strformat
import std/logging
import std/strutils
import std/tables
import ./config_common
import ./config_cmd_check
import ./check_config
import ./checks_registry
import ./checker
import ./state
import ./util/leightweight

include ./constants
include ./version

# TODO Try to name &// describe this tool in a shorter, slightly more catchy way.
let doc = fmt"""
A linter (static analysis tool) for repositories
which contain technical documentation
of Open Source Hardware (OSH) projects.

Please send feedback here:
<{OSH_TOOL_ISSUES_URL}>

This tool supports three main commands:

- **check** (beta, please try; only reads, does not write/create/change anything):
  This checks a given project dir/repo,
  reporting about what is and is not present and in order
  of the things we want to see in a project [1].
- **init** (***NOT IMPLEMENTED***, do not use!):
  This initializes a project directory template from scratch,
  containing as much as possible
  of the structure and meta-data we want to see [1].
- **update** (***NOT IMPLEMENTED***, do not use!):
  This auto-generates as much as possible
  of the structure and meta-data we want to see [1]
  in the given, already existing project directory.

## 1. What we want to see in a project

This is very opinionated. It is our choice of set of rules, and their specific settings.
We came to this, through our years of experience in Open Source Software and Hardware.
As the later is pretty new and still quite "wild" and unorganized,
there is little solid understanding of it all,
and these rules are thus partly just guessing.
We would be happy to get feedback through issues or even pull-requests at:
<{OSH_TOOL_REPO}>

The easiest way to understand what this tool does,
is to just run it in a git repo with some content:

    osh check

This just reads files and writes to stdout.
It neither deletes, changes nor creates files.

Usage:
  osh [-C <path>] [-c=<path>] [--config=<path>] [--default-config=<path>] [--quiet] init    [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics] [-f] [--force] [--readme] [--license]
  osh [-C <path>] [-c=<path>] [--config=<path>] [--default-config=<path>] [--quiet] update  [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics]
  osh [-C <path>] [-c=<path>] [--config=<path>] [--default-config=<path>] [--quiet] [check] [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics] [-f] [--force] [-l] [--list-checks] [--report-md-list=<path> ...] [--report-md-table=<path> ...] [--report-json=<path> ...] [--report-csv=<path> ...]
  osh (-h | --help)
  osh (-V | --version) [--quiet]

Options:
  -h --help          Show this screen and exit.
  -V --version       Show this tools version and exit.
  -q --quiet         Prevents all logging output, showing only the version number in combination with --version.
  -C <path>          Run as if osh was started in <path> instead of the current working directory.
  -c --config <path> Load config from the given path; see --default-config.
  --default-config <path> Path to a to-be-created JSON file, holding the default configuration.
  --offline          Do not access the network/internet.
  -f --force         Force overwriting of any generated files, if they are explicitly requested (e.g. with --readme or --license).
  -l --list-checks   Creates a list of all available checks with descriptions in Markdown format and exits.
  --readme           Generate a template README, to be manually adjusted.
  --license          Choose a license from a list, generating a LICENSE file that will be identified by GitLab and GitHub.
  --report-md-list=<path>  File-path a report in Markdown (list) format gets written to; May be used multiple times; if no --report-* argument is given, a report gets written to stdout & stderr.
  --report-md-table=<path> File-path a report in Markdown (table) format gets written to; May be used multiple times; if no --report-* argument is given, a report gets written to stdout & stderr.
  --report-csv=<path>      File-path a report in CSV format gets written to; May be used multiple times; if no --report-* argument is given, a report gets written to stdout & stderr.
  --report-json=<path>     File-path a report in JSON format gets written to; May be used multiple times; if no --report-* argument is given, a report gets written to stdout & stderr.
  -e --electronics   Indicate that the project contains electronics (KiCad)
  --no-electronics   Indicate that the project does not contain electronics (KiCad)
  -m --mechanics     Indicate that the project contains mechanical parts (FreeCAD)
  -no-mechanics      Indicate that the project does not contain mechanical parts (FreeCAD)

Examples:
  osh
  osh check
  osh -C ./myFolder check
  osh check --force --report-md-list report.md
  osh check --force --report-md-table report.md
  osh check --force --report-json report.json
  osh check --force --report-csv report.csv
  osh --list-checks
"""

type
  Command* = enum
    Check
    # Init
    # Update

# proc init*(registry: var InitUpdatesRegistry, state: var State) =
#   info "Initializing OSH project directory ..."

#   for primaryId, iu in registry.getAllInitUpdates(state.config.initUpdates):
#     let res = iu.init(state)
#     if res.msg.isNone():
#       log(res.kind.logLevel(), fmt"Init - {iu.name()}? - {res.kind}")
#     else:
#       log(res.kind.logLevel(), fmt"Init - {iu.name()}? - {res.kind}: {res.msg.get()}")

# proc update*(registry: var InitUpdatesRegistry, state: var State) =
#   info "Updating OSH project directory to the latest guidelines ..."

#   for primaryId, iu in registry.getAllInitUpdates(state.config.initUpdates):
#     let res = iu.update(state)
#     if res.msg.isNone():
#       log(res.kind.logLevel(), fmt"Update - {iu.name()}? - {res.kind}")
#     else:
#       log(res.kind.logLevel(), fmt"Update - {iu.name()}? - {res.kind}: {res.msg.get()}")

proc run(command: Command, configOpt: ConfigCmdCheckOpt, config: ConfigCmdCheck) =
  debug "Creating the state ..."
  var runState = newState(configOpt, config)
  case command:
    # of Init:
    #   debug "Creating the init & update registry ..."
    #   var registry = newInitUpdatesRegistry()
    #   debug "Registering init handlers ..."
    #   registry.registerGenerators()
    #   debug "Running inits ..."
    #   init(registry, runState)
    # of Update:
    #   debug "Creating the init & update registry ..."
    #   var registry = newInitUpdatesRegistry()
    #   debug "Registering update handlers ..."
    #   registry.registerGenerators()
    #   debug "Running updates ..."
    #   update(registry, runState)
    of Check:
      debug "Creating the checks registry ..."
      var registry = ChecksRegistry.new()
      debug "Registering checks ..."
      registry.registerGenerators()
      debug "Running checks ..."
      checker.check(registry, runState)

proc extractCommand(args: Table[string, Value]): Command =
  if args["init"]:
    # return Command.Init
    raise newException(Defect, "Not implemented")
  elif args["update"]:
    # return Command.Update
    raise newException(Defect, "Not implemented")
  elif args["check"]:
    return Command.Check
  else:
    info "No valid/known command given, defaulting to 'check'"
    return Command.Check

proc extractCfgFile(args: Table[string, Value]): Option[string] =
  if args["--config"]:
    debug "Using config file:"
    let cfgFile = $args["--config"]
    debug cfgFile
    some(cfgFile)
  else:
    none[string]()

proc listChecks() =
  debug "Creating the checks registry ..."
  var registry = ChecksRegistry.new()
  debug "Registering checks ..."
  registry.registerGenerators()
  debug "Listing checks ..."
  registry.list()

type CliRes = Result[void, string]

proc cli(): CliRes =

  debug "Initializing ..."
  let args = docopt(doc, version = VERSION)

  let logLevel = if args["--quiet"]: lvlNone else: lvlAll
  addHandler(newConsoleLogger(levelThreshold = logLevel, useStderr = true))

  if args["--list-checks"]:
    listChecks()
    quit(0)

  debug "Creating config value 'command' ..."
  let command = extractCommand(args)

  if args["--default-config"]:
    let configFile = $args["--default-config"]
    case command
      of Command.Check:
        var cfg = ConfigCmdCheckOpt.new()
        var registry = ChecksRegistry.new()
        let config = cfg.extendWithDefaults(registry.getAllChecksDefaultConfig())
        var configOpt = config.toOpt()
        configOpt.projRoot = none[string]()
        configOpt.projPrefixes = none[seq[string]]()
        configOpt.writeJson(configFile)
    quit(0)

  let configFile = extractCfgFile(args)

  case command
    of Command.Check:
      var cfg = ConfigCmdCheckOpt.fromArgs(args)
      debug ""
      debug "Config (check) parsed from CLI arguments:"
      debug "######################################################################"
      debug cfg.toJsonStr()
      debug "######################################################################"
      debug ""
      if configFile.isSome():
        let cfgFromFile = ConfigCmdCheckOpt.parseJsonFile(configFile.get())
        debug ""
        debug "Config (check) parsed from config file:"
        debug "######################################################################"
        debug  cfgFromFile.toJsonStr()
        debug "######################################################################"
        debug ""
        cfg.extendWith(cfgFromFile)
      var registry = ChecksRegistry.new()
      let config = cfg.extendWithDefaults(registry.getAllChecksDefaultConfig())
      debug ""
      debug "Config (check) combined from CLI, config-file (if used) and extended with defaults where necessary:"
      debug "######################################################################"
      debug  config.toOpt().toJsonStr()
      debug "######################################################################"
      debug ""
      run(command, cfg, config)
    # of Command.Init:
      # ConfigCmdInitOpt.fromArgs(args)
      # raise newException(Defect, "TODO implement")
    # of Command.Update:
      # ConfigCmdUpdateOpt.fromArgs(args)
      # raise newException(Defect, "TODO implement")

  return ok()

when isMainModule:
  let res = cli()
  if res.isErr:
    fatal res.error()
    quit(1)
