# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

let version = "0.0.1"
let doc = """
Open Source Hardware (OSH) project management tool.
It helps in initially setting up an OSH project according certain standards,
updating a project to the latest standards,
and allows to verify which stadnards are met or not.

TODO Anderst benennen, nicht proj management tool sondern standardisierung fuer techinsche doku

Usage:
  osh [-C <path>] init   [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics] [--force] [--readme] [--license]
  osh [-C <path>] update [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics]
  osh [-C <path>] check  [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics] [--markdown]
  osh (-h | --help)
  osh (-V | --version)

Options:
  -h --help          Show this screen.
  -V --version       Show this tools version.
  --offline          Not not access the network/internet.
  --force            Force overwriting of any generatd files, if they are explicitly requested (e.g. with --readme or --license).
  --readme           Generate a template README, to be manually adjusted.
  --license          Choose a license from a list, generating a LICENSE file that will be identified by GitLab and GitHub.
  --markdown         Generates the reporting output in markdow, suitable to render as HTML or cop&paste into an issue report.
  -e --electronics   Indicate that the project contains electronics (KiCad)
  --no-electronics   Indicate that the project does not contain electronics (KiCad)
  -m --mechanics     Indicate that the project contains mechanical parts (FreeCAD)
  -no-mechanics      Indicate that the project does not contain mechanical parts (FreeCAD)
  -C <path>          Run as if osh was started in <path> instead of the current working directory.
"""

import docopt
import os
import options
import strformat
import strutils
import ./config
import ./tools
import ./check
import ./checks
import ./init_update
import ./init_updates
import ./state

proc check(registry: ChecksRegistry, state: var State) =
  if state.config.markdown:
    stdout.writeLine(fmt"| Passed | Check | Error |")
    # NOTE In some renderers, number of dashes are used to determine relative column width
    stdout.writeLine(fmt"| - | --- | ----- |")
  else:
    echo "Checking OSH project directory ..."
  for check in registry.checks:
    let res = check.run(state)
    if state.config.markdown:
      let passed = if res.error.isNone(): "x" else: " "
      let error = res.error.get("-").replace("\n", " -- ")
      stdout.writeLine(fmt"| [{passed}] | {check.name()} | {error} |")
    else:
      if res.error.isNone():
        stdout.writeLine(fmt"Check - {check.name()}? - Succeeded")
      else:
        stderr.writeLine(fmt"Check - {check.name()}? - Failed: {res.error.get()}")

proc init*(registry: InitUpdatesRegistry, state: var State) =
  echo "Initializing OSH project directory ..."

  for iu in registry.initUpdates:
    let res = iu.init(state)
    if res.error.isNone():
      stdout.writeLine(fmt"Init - {iu.name()}? - Succeeded")
    else:
      stderr.writeLine(fmt"Init - {iu.name()}? - Failed: {res.error.get()}")

proc update*(registry: InitUpdatesRegistry, state: var State) =
  echo "Updating OSH project directory to the latest guidelines ..."

  for iu in registry.initUpdates:
    let res = iu.update(state)
    if res.error.isNone():
      stdout.writeLine(fmt"Update - {iu.name()}? - Succeeded")
    else:
      stderr.writeLine(fmt"Update - {iu.name()}? - Failed: {res.error.get()}")

proc cli() =
  let args = docopt(doc, version = version)

  let proj_root =
    if args["-C"]:
      $args["-C"]
    else:
      os.getCurrentDir()
  let electronics =
    if args["--electronics"]:
      true
    elif args["--no-electronics"]:
      false
    else:
      containsFilesWithSuffix(proj_root, ".kicad_pcb") or
          containsFilesWithSuffix(proj_root, ".sch")
  let mechanics =
    if args["--mechanics"]:
      true
    elif args["--no-mechanics"]:
      false
    else:
      containsFilesWithSuffix(proj_root, ".fcstd")
  let config = RunConfig(
    proj_root: proj_root,
    force: args["--force"],
    readme: args["--readme"],
    license: args["--license"],
    offline: args["--offline"],
    markdown: args["--markdown"],
    electronics: electronics,
    mechanics: mechanics,
    )

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
    var registry = newChecksRegistry()
    registry.registerChecks()
    check(registry, runState)

when isMainModule:
  cli()
