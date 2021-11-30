# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import chronicles
import os
import options
import strformat
import strutils
import system/io
import ./config
import ./check
import ./checks
import ./state

include ./version

proc check*(registry: ChecksRegistry, state: var State) =
  let (reportStream, reportStreamErr) =
    if state.config.reportTarget.isSome():
      let reportFileName = state.config.reportTarget.get()
      if not state.config.force and fileExists(reportFileName):
        error "Report file exists, and --force was not specified; aborting.", reportFile = reportFileName
        quit 1
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
    if not isApplicable(res):
      debug "Skip reporting check because it is inapplicable to this project (in its current state)", checkName = check.name()
      continue
    let passed = isGood(res)
    if state.config.markdown:
      let passedStr = if passed: "x" else: " "
      let error = res.error.get("-").replace("\n", " -- ")
      reportStream.writeLine(fmt"| [{passedStr}] | {check.name()} | {error} |")
    else:
      if passed:
        reportStream.writeLine(fmt"- [x] {check.name()}")
      else:
        reportStreamErr.writeLine(fmt"- [ ] {check.name()} -- Error: {res.error.get()}")
  reportStream.close()
