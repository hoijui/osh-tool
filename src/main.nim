# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

# TODO Anderst benennen, nicht "project management tool", sondern standardisierung fuer techinsche doku/linter
let doc = """
Open Source Hardware (OSH) project management tool.
It helps in initially setting up an OSH project according certain standards,
updating a project to the latest standards,
and allows to verify which stadnards are met or not.

Usage:
  osh [-C <path>] init   [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics] [--force] [--readme] [--license]
  osh [-C <path>] update [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics]
  osh [-C <path>] check  [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics] [--markdown] [-r <path>] [--report <path>]
  osh (-h | --help)
  osh (-V | --version)

Options:
  -h --help          Show this screen.
  -V --version       Show this tools version.
  -C <path>          Run as if osh was started in <path> instead of the current working directory.
  --offline          Not not access the network/internet.
  --force            Force overwriting of any generatd files, if they are explicitly requested (e.g. with --readme or --license).
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
import chronicles
import os
import options
import strformat
import strutils
import system/io
import ./config
import ./tools
import ./check
import ./checks
import ./init_update
import ./init_updates
import ./state

include ./version

proc check(registry: ChecksRegistry, state: var State) =
  let (reportStream, reportStreamErr) =
    if state.config.reportTarget.isSome():
      let reportFileName = state.config.reportTarget.get()
      let file = io.open(reportFileName, fmWrite)
      (file, file)
    else:
      (stdout, stderr)
  if state.config.markdown:
    reportStream.writeLine(fmt"| Passed | Check | Error |")
    # NOTE In some renderers, number of dashes are used to determine relative column width
    reportStream.writeLine(fmt"| - | --- | ----- |")
  else:
    info "Checking OSH project directory ..."
  for check in registry.checks:
    let res = check.run(state)
    if state.config.markdown:
      let passed = if res.error.isNone(): "x" else: " "
      let error = res.error.get("-").replace("\n", " -- ")
      reportStream.writeLine(fmt"| [{passed}] | {check.name()} | {error} |")
    else:
      if res.error.isNone():
        reportStream.writeLine(fmt"- [x] {check.name()}")
      else:
        reportStreamErr.writeLine(fmt"- [ ] {check.name()} -- Error: {res.error.get()}")
  reportStream.close()

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
  trace "Initializing ..."
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
  trace "Create config value 'electronics' ..."
  let electronics =
    if args["--electronics"]:
      true
    elif args["--no-electronics"]:
      false
    else:
      containsFilesWithSuffix(proj_root, ".kicad_pcb") or
          containsFilesWithSuffix(proj_root, ".sch")
  trace "Create config value 'mechanics' ..."
  let mechanics =
    if args["--mechanics"]:
      true
    elif args["--no-mechanics"]:
      false
    else:
      containsFilesWithSuffix(proj_root, ".fcstd")
  trace "Create configuration ..."
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

  trace "Creating the state ..."
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
    trace "Creating the checks registry ..."
    var registry = newChecksRegistry()
    trace "Register checks ..."
    registry.registerChecks()
    trace "Running checks ..."
    check(registry, runState)

when isMainModule:
  cli()
