# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

from strutils import join
import re
import options
import ../tools
import ../check
import ../state

let R_GENERATABLE= re"^.*(jpg|jpeg|gif|png|bmp|pdf|stl)$" # TODO Add much more (PDF, STL, ...) and maybe make this list in a CSV as well

type MightBeGeneratedCheck = ref object of Check

method name*(this: MightBeGeneratedCheck): string =
  return "Might be generated" # TODO Rename this, to be something that is good if the tst passes, e.g. "No possibly generatable files"

method description*(this: MightBeGeneratedCheck): string =
  return """Checks that no generated files are part of the project. \
These are usually files that are created using a software \
that is manually configured and executed by a human. \
Try instead, to find a way to automate this process. \
Doing so, both that the projects storage requirement gets lower - \
usually by a lot -
and more importantly,
that the generated files are always up to date with the sources.
This is one of the more controversial checks,
as it often requires writing new software.
That is sometimes a simple script,
and sometimes complex software requiring many person-months of development."""

method requirements*(this: MightBeGeneratedCheck): CheckReqs =
  return {
    CheckReq.FilesListRec,
  }

method getRatingFactors*(this: MightBeGeneratedCheck): CheckRelevancy =
  return CheckRelevancy(
    weight: 0.5,
    openness: 0.6, # because the repo could be less heavy and thus easier to host/share/exchange
    hardware: 0.0,
    quality: 0.5,
    machineReadability: 0.3,
    )

method run*(this: MightBeGeneratedCheck, state: var State): CheckResult =
  let foundFiles = filterPathsMatchingFileName(state.listFiles(), R_GENERATABLE)
  return (if foundFiles.len == 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    newCheckResult(
      CheckResultKind.Bad,
      CheckIssueImportance.Light,
      some(
        "Possibly generatable files found. Please consider removing them:\n\n- " &
        foundFiles.join("\n- ")
      )
    )
  )

proc createDefault*(): Check =
  MightBeGeneratedCheck()
