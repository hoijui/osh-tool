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
  osh [-C <path>] init   [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics] [--force] [--readme] [--license]
  osh [-C <path>] update [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics]
  osh [-C <path>] check  [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics]
  osh (-h | --help)
  osh (-V | --version)

Options:
  -h --help          Show this screen.
  -V --version       Show version.
  --force            Force overwriting of any generatd files, if they are explicitly requested (e.g. with --readme or --license).
  --readme           Generate a template README, to be manually adjusted.
  --license          Choose a license from a list, generating a LICENSE file that will be identified by GitLab and GitHub.
  -e --electronics   Indicate that the project contains electronics (KiCad)
  --no-electronics   Indicate that the project does not contain electronics (KiCad)
  -m --mechanics     Indicate that the project contains mechanical parts (FreeCAD)
  -no-mechanics      Indicate that the project does not contain mechanical parts (FreeCAD)
  -C <path>          Run as if osh was started in <path> instead of the current working directory.
"""

import docopt
import os
import ./config
import ./tools
import ./checks
import ./init_updates
import ./state

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
      containsFilesWithSuffix(proj_root, ".kicad_pcb") or containsFilesWithSuffix(proj_root, ".sch")
  let mechanics =
    if args["--mechanics"]:
      true
    elif args["--no-mechanics"]:
      false
    else:
      containsFilesWithSuffix(proj_root, ".fcstd")
  let config = RunConfig(
    proj_root : proj_root,
    force: args["--force"],
    readme: args["--readme"],
    license: args["--license"],
    electronics: electronics,
    mechanics : mechanics,
    )

  var run_state = State(
    config: config,
    checks: @[],
    init_updates: @[]
    )
  if args["init"]:
    run_state.registerInitUpdates()
    init(run_state)
  elif args["update"]:
    run_state.registerInitUpdates()
    update(run_state)
  elif args["check"]:
    run_state.registerChecks()
    check(run_state)

when isMainModule:
  cli()
