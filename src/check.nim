# This file is part of osh-tool.
# <https://gitlab.opensourceecology.de/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# TODO We may want to introduce a small DSL for reducing checks (and init_updtes) boilerplate code, see https://github.com/GaryM-exkage/GDGW-Maverick-Bot/blob/master/src/nimcordbot/command/command.nim

import options
import ./state

type
  CheckResultKind* {.pure.} = enum
    Perfect, Ok, Acceptable, Bad, Inapplicable

  CheckIssueWeight* {.pure.} = enum
    DeveloperFailure, Heavy, Middle, Light

  CheckIssue* = object
    weight*: CheckIssueWeight
    msg*: Option[string]

  CheckResult* = object
    kind*: CheckResultKind
    # Zero or more issues
    issues*: seq[CheckIssue]
    # msg*: Option[string]

# Creates a check-result without an issue
proc newCheckResult*(kind: CheckResultKind): CheckResult =
  return CheckResult(kind: kind, issues: @[])

# Creates a check-result with a single issue
proc newCheckResult*(kind: CheckResultKind, weight: CheckIssueWeight, msg: Option[string]): CheckResult =
  return CheckResult(
    kind: kind,
    issues: @[
      CheckIssue(
        weight: weight,
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

method run*(this: Check, state: var State): CheckResult {.base,
    locks: "unknown".} =
  return CheckResult(
    kind: CheckResultKind.Bad,
    issues: @[
      CheckIssue(
        weight: CheckIssueWeight.DeveloperFailure,
        msg: some("Not implemented for this specific check!")
      )
    ]
  )
