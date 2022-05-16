# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# TODO Anderst benennen, nicht "project management tool", sondern standardisierung fuer techinsche doku/linter
let doc = """
Open Source Hardware (OSH) project management tool.
It helps in initially setting up an OSH project according certain standards,
updating a project to the latest standards,
and allows to verify which stadnards are met or not.

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
import system/io
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
    if res.error.isNone():
      stdout.writeLine(fmt"Init - {iu.name()}? - Succeeded")
    else:
      stderr.writeLine(fmt"Init - {iu.name()}? - Failed: {res.error.get()}")

proc update*(registry: InitUpdatesRegistry, state: var State) =
  info "Updating OSH project directory to the latest guidelines ..."

  for iu in registry.initUpdates:
    let res = iu.update(state)
    if res.error.isNone():
      stdout.writeLine(fmt"Update - {iu.name()}? - Succeeded")
    else:
      stderr.writeLine(fmt"Update - {iu.name()}? - Failed: {res.error.get()}")

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
  debug "Creating configuration ..."
  let config = RunConfig(
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

  debug "Creating the state ..."
  var runState = newState(config)
  if args["init"]:
    var registry = newInitUpdatesRegistry()
    registry.registerInitUpdates()
    init(registry, runState)
  elif args["update"]:
    var registry = newInitUpdatesRegistry()
    registry.registerInitUpdates()
    update(registry, runState)
  elif args["check"]:
    debug "Creating the checks registry ..."
    var registry = newChecksRegistry()
    debug "Registering checks ..."
    registry.registerChecks()
    debug "Running checks ..."
    checker.check(registry, runState)

when isMainModule:
  cli()
