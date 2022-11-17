# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# TODO We may want to introduce a small DSL for reducing checks (and init_updtes) boilerplate code, see https://github.com/GaryM-exkage/GDGW-Maverick-Bot/blob/master/src/nimcordbot/command/command.nim

import options
import tables
import ./state

type
  CheckResultKind* {.pure.} = enum
    Perfect, Ok, Acceptable, Bad, Inapplicable

  CheckIssueImportance* {.pure.} = enum
    DeveloperFailure, Severe, Middle, Light

  CheckIssue* = object
    importance*: CheckIssueImportance
    msg*: Option[string]

  CheckResult* = object
    kind*: CheckResultKind
    # Zero or more issues
    issues*: seq[CheckIssue]
    # msg*: Option[string]

  # Requirements of a check at runtime
  CheckReq* {.size: sizeof(cint).} = enum
    # Requires a connection to the internet
    Online
    # Requires the recursive directory tree of the project files
    FilesListRec
    # Requires the list of files in the root of the project
    FilesListL1
    # Requires access to the contents of one or more files in the project
    FileContent
    # Requires executing an external tool, for example `reuse lint`
    ExternalTool
  # CheckReqs* {.size: sizeof(cint).} = set[CheckReq]
  CheckReqs* = set[CheckReq]

  ReportStats* = object
    checks*: tuple[
      run: int,
      skipped: int,
      passed: int,
      failed: int,
      available: int
      ]
    issues*: Table[string, int]
    # How well the project adheres to this tools criteria,
    # from 0.0 for not at all, to 1.0 for compleetely.
    openness*: float32

proc toNum*(flags: CheckReqs): int = cast[cint](flags)
proc toCheckReqs*(bits: int): CheckReqs = cast[CheckReqs](bits)

# Creates a check-result without an issue
proc newCheckResult*(kind: CheckResultKind): CheckResult =
  return CheckResult(kind: kind, issues: @[])

# Creates a check-result with a single issue
proc newCheckResult*(kind: CheckResultKind, importance: CheckIssueImportance, msg: Option[string]): CheckResult =
  return CheckResult(
    kind: kind,
    issues: @[
      CheckIssue(
        importance: importance,
        msg: msg
      )
    ]
  )

type Check* = ref object of RootObj

proc isApplicable*(res: CheckResult): bool =
  return res.kind != Inapplicable

proc isGood*(res: CheckResult): bool =
  return res.kind in [Perfect, Ok, Acceptable]

method name*(this: Check): string {.base.} =
  return "TODO Override!"

method description*(this: Check): string {.base.} =
  return "TODO Override!"

method requirements*(this: Check): CheckReqs {.base.} =
  echo "TODO Override!"
  quit 99

method run*(this: Check, state: var State): CheckResult {.base,
    locks: "unknown".} =
  return CheckResult(
    kind: CheckResultKind.Bad,
    issues: @[
      CheckIssue(
        importance: CheckIssueImportance.DeveloperFailure,
        msg: some("Not implemented for this specific check!")
      )
    ]
  )
