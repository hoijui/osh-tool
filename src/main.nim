# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# TODO Try to name&//describe this tool in a shorter, slightly more catchy way.
let doc = """
A linter (static analysis tool) for repositories
which contain technical documentation
of Open Source Hardware (OSH) projects.

It supports three main commands:

- **check** (beta, please try; only reads, does not write/create/change anything):
  This checks a given project dir/repo,
  reporting about what is and is not present and in order
  of the things we want to see in a project [1].
- **init** (alpha, do not use!):
  This initializes a project directory template from scratch,
  containing as much as possible
  of the structure and meta-data we want to see [1].
- **update** (alpha, do not use!):
  This auto-generates as much as possible
  of the structure and meta-data we want to see [1]
  in the given, already existing project directory.

## 1. What we want to see in a project

This is very opinionated. It is our choice of set of rules, and their specific settings.
We came to this, through our years of experience in Open Source Software and Hardware.
As the later is pretty new and still quite "wild" and unorganized,
there is little solid understanding of it all,
and these rules are thus partly just guessing.
We would be happy to get feedback through issues or even pull-reqests at:
<https://gitlab.com/OSEGermany/osh-tool>

The easiest way to understand what this tool does,
is to just run it in a git repo with some content with:

```
osh check
```

This just reads files and writes to stdout.
It neither deletes, changes nor creates files.

Usage:
  osh [-C <path>] init   [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics] [-f] [--force] [--readme] [--license]
  osh [-C <path>] update [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics]
  osh [-C <path>] check  [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics] [-f] [--force] [--markdown] [-r <path>] [--report <path>]
  osh (-h | --help)
  osh (-V | --version)

Options:
  -h --help          Show this screen.
  -V --version       Show this tools version.
  -C <path>          Run as if osh was started in <path> instead of the current working directory.
  --offline          Not not access the network/internet.
  -f --force         Force overwriting of any generatd files, if they are explicitly requested (e.g. with --readme or --license).
  --readme           Generate a template README, to be manually adjusted.
  --license          Choose a license from a list, generating a LICENSE file that will be identified by GitLab and GitHub.
  --markdown         Generates the reporting output in markdow, suitable to render as HTML or cop&paste into an issue report.
  -r --report <path> File-path the check-report (Markdown) gets written to; by default, it gets written to stdout.
  -e --electronics   Indicate that the project contains electronics (KiCad)
  --no-electronics   Indicate that the project does not contain electronics (KiCad)
  -m --mechanics     Indicate that the project contains mechanical parts (FreeCAD)
  -no-mechanics      Indicate that the project does not contain mechanical parts (FreeCAD)
"""

import docopt
import os
import options
import strformat
import std/logging
import ./config
import ./checks
import ./checker
import ./init_update
import ./init_updates
import ./state

include ./version

proc init*(registry: InitUpdatesRegistry, state: var State) =
  info "Initializing OSH project directory ..."

  for iu in registry.initUpdates:
    let res = iu.init(state)
    if res.msg.isNone():
      log(res.kind.logLevel(), fmt"Init - {iu.name()}? - {res.kind}")
    else:
      log(res.kind.logLevel(), fmt"Init - {iu.name()}? - {res.kind}: {res.msg.get()}")

proc update*(registry: InitUpdatesRegistry, state: var State) =
  info "Updating OSH project directory to the latest guidelines ..."

  for iu in registry.initUpdates:
    let res = iu.update(state)
    if res.msg.isNone():
      log(res.kind.logLevel(), fmt"Update - {iu.name()}? - {res.kind}")
    else:
      log(res.kind.logLevel(), fmt"Update - {iu.name()}? - {res.kind}: {res.msg.get()}")

proc run(config: RunConfig) =
  debug "Creating the state ..."
  var runState = newState(config)
  case config.command:
    of Init:
      debug "Creating the init&update registry ..."
      var registry = newInitUpdatesRegistry()
      debug "Registering init handlers ..."
      registry.registerInitUpdates()
      debug "Running inits ..."
      init(registry, runState)
    of Update:
      debug "Creating the init&update registry ..."
      var registry = newInitUpdatesRegistry()
      debug "Registering update handlers ..."
      registry.registerInitUpdates()
      debug "Running updates ..."
      update(registry, runState)
    of Check:
      debug "Creating the checks registry ..."
      var registry = newChecksRegistry()
      debug "Registering checks ..."
      registry.registerChecks()
      debug "Running checks ..."
      checker.check(registry, runState)

proc extract_command(args: Table[string, Value]): Command =
  if args["init"]:
    return Command.Init
  elif args["update"]:
    return Command.Init
  elif args["check"]:
    return Command.Check
  else:
    error "No valid command given, see --help"
    raise newException(Defect, "No valid command given, see --help")

proc cli() =
  addHandler(newConsoleLogger())

  debug "Initializing ..."
  let args = docopt(doc, version = version)

  let projRoot =
    if args["-C"]:
      $args["-C"]
    else:
      os.getCurrentDir()
  let reportTarget: Option[string] =
    if args["--report"]:
      some($args["--report"])
    else:
      none(string)
  debug "Creating config value 'electronics' ..."
  let electronics: YesNoAuto =
    if args["--electronics"]:
      Yes
    elif args["--no-electronics"]:
      No
    else:
      Auto
  debug "Creating config value 'mechanics' ..."
  let mechanics =
    if args["--mechanics"]:
      Yes
    elif args["--no-mechanics"]:
      No
    else:
      Auto
  debug "Creating config value 'command' ..."
  let command = extract_command(args)

  debug "Creating configuration ..."
  let config = RunConfig(
    command: command,
    projRoot: projRoot,
    reportTarget: reportTarget,
    force: args["--force"],
    readme: args["--readme"],
    license: args["--license"],
    offline: args["--offline"],
    markdown: args["--markdown"],
    electronics: electronics,
    mechanics: mechanics,
    )

  run(config)


when isMainModule:
  cli()
