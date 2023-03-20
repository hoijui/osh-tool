# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

from strutils import join
import re
import options
import ../check
import ../state
import ../tools

let R_GENERATABLE= re"^.*(jpg|jpeg|gif|png|bmp|pdf|stl)$" # TODO Add much more (PDF, STL, ...) and maybe make this list in a CSV as well

type MightBeGeneratedCheck = ref object of Check

method name*(this: MightBeGeneratedCheck): string =
  return "Might be generated" # TODO Rename this, to be something that is good if the tst passes, e.g. "No possibly generatable files"

method description*(this: MightBeGeneratedCheck): string =
  return """Checks that no generated files are part of the project. \
These are usually files that are created using a software \
that is manually configured and executed by a human. \
Try instead, to find a way to automate this process, \
and to not store the resulting files in the repository."""

method why*(this: MightBeGeneratedCheck): string =
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

method sourcePath*(this: MightBeGeneratedCheck): string =
  return tools.srcFileName()

method requirements*(this: MightBeGeneratedCheck): CheckReqs =
  return {
    CheckReq.FilesListRecNonGen,
  }

method getSignificanceFactors*(this: MightBeGeneratedCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.5,
    openness: 0.6, # because the repo could be less heavy and thus easier to host/share/exchange
    hardware: 0.0,
    quality: 0.5,
    machineReadability: 0.3,
    )

method run*(this: MightBeGeneratedCheck, state: var State): CheckResult =
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

proc createDefault*(): Check =
  MightBeGeneratedCheck()
