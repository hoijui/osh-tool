# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

from strutils import join
import options
import re
import ../check
import ../check_config
import ../state
import ../util/fs

const IDS = @["ngf", "nogenf", "no_generated_files"]
const ID = IDS[0]
let R_GENERATABLE= re"^.*[.](jpg|jpeg|gif|png|bmp|pdf|stl|zip|jar)$" # TODO Add much more, and maybe move this list to a CSV file

type NoGeneratedFilesCheck = ref object of Check
type NoGeneratedFilesCheckGenerator = ref object of CheckGenerator

method name*(this: NoGeneratedFilesCheck): string =
  return "No generated files"

method description*(this: NoGeneratedFilesCheck): string =
  return """Checks that no generated files are part of the project. \
These are usually files that are created using a software \
that is manually configured and executed by a human. \
Try instead, to find a way to automate this process, \
and to not store the resulting files in the repository."""

method why*(this: NoGeneratedFilesCheck): string =
  return """1. The projects storage requirements go down - \
usually by a lot
2. There are no outdated generated files,
    because of either of these two reasons:

    - One only gets the files hwen generating them right when required, or
    - They are regenerated in CI/build-bot and uploaded/hosted on the project pages
      whenever there is a change (e.g. a git push to to the repo)

NOTE: This is one of the more controversial checks,
as it often requires writing new software.
That is sometimes a simple script,
and sometimes complex software requiring many person-months of development."""

method sourcePath*(this: NoGeneratedFilesCheck): string =
  return fs.srcFileName()

method requirements*(this: NoGeneratedFilesCheck): CheckReqs =
  return {
    CheckReq.FilesListRecNonGen,
  }

method getSignificanceFactors*(this: NoGeneratedFilesCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.5,
    openness: 0.6, # because the repo could be less heavy and thus easier to host/share/exchange
    hardware: 0.0,
    quality: 0.5,
    machineReadability: 0.3,
    )

method run*(this: NoGeneratedFilesCheck, state: var State): CheckResult =
  let foundFiles = filterPathsMatchingFileName(state.listFilesNonGenerated(), R_GENERATABLE)
  return (if foundFiles.len == 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    newCheckResult(
      CheckResultKind.Bad,
      CheckIssueSeverity.Low,
      some(
        "Possibly generatable files found. Please consider removing them:\n\n- " &
        foundFiles.join("\n- ")
      )
    )
  )

method id*(this: NoGeneratedFilesCheckGenerator): seq[string] =
  return IDS

method generate*(this: NoGeneratedFilesCheckGenerator, config: CheckConfig = CheckConfig(id: this.id()[0], json: none[string]())): Check =
  this.ensureNonConfig(config)
  NoGeneratedFilesCheck()

proc createGenerator*(): CheckGenerator =
  NoGeneratedFilesCheckGenerator()
