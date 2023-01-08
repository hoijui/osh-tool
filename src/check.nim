# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# TODO We may want to introduce a small DSL for reducing checks (and init_updtes) boilerplate code, see https://github.com/GaryM-exkage/GDGW-Maverick-Bot/blob/master/src/nimcordbot/command/command.nim

import options
import tables
import strformat
import strutils
import uri
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

  # Data about the report that is available *before* running the checks
  ReportPrelude* = object
    homepage*: string
    projVars*: TableRef[string, string]
    tool_versions*: tuple[
      osh: string,
      okh: string,
      reuse: string,
      projvar: string,
      mle: string,
      osh_dir_std: string,
    ]

  # Data about the report that is available *after* running the checks
  ReportStats* = object
    checks*: tuple[
      run: int,
      skipped: int,
      passed: int,
      failed: int,
      available: int
      ]
    issues*: Table[string, int]
    # Ratings of the project,
    # each one on a different topic/dimension/axis.
    ratings*: Ratings

  # How much a check is relevant for the different ratings.
  # All values go from 0.0 for not relevant at all,
  # to 1.0 for very relevant.
  CheckRelevancy* = object
    # How relevant/important is the check in general.
    # For combined ratings, this gets multiplied with all the other
    weight*: float32
    # How relevant is the check to determine how much the project
    # adheres to Open Source (Hardware) best-pracitces.
    openness*: float32
    # How relevant is the check to determine whether the project
    # describes hardware.
    hardware*: float32
    # How relevant is the check to determine whether the project
    # is of high quality.
    quality*: float32
    # How relevant is the check to determine whether the project
    # is easily machine readable.
    machineReadability*: float32

  # A single rating for a project,
  # representing its success or failure on a specific axis/dimension,
  # e.g. openness or documentation quality.
  Rating* = object
    # Human redaable, Title Case name of for this rating,
    # e.g. "Openness".
    name*: string
    # The main value of the rating as a factor,
    # from 0.0 for total failure,
    # to 1.0 for complete success.
    factor*: float32
    # The same as `factor`,
    # but as a percentage
    # with exactly two digits after the comma,
    # excluding the '%'.
    # Possible values go from "0.00" to "100.00".
    # NOTE We only have this as field (vs method), so it gets serilized (e.g. to JSON) - TODO Check if one can serialize function return values too
    percent*: string
    # Lower snakeCase name of the color associated to the rating,
    # E.g. "red" for low values,
    # "yellow" for mid-range values,
    # "green" for high values.
    # NOTE We only have this as field (vs method), so it gets serilized (e.g. to JSON)
    color*: string
    # URL to a README badge representing this rating,
    # showing off the `name`, `percentage` and `color`.
    # NOTE We only have this as field (vs method), so it gets serilized (e.g. to JSON)
    badgeUrl*: string

  # How successfull all checks combined ran,
  # as a factor from 0.0 to 1.0,
  # taking each checks weight into account.
  Ratings* = object
    # Overall success of check executaion/passing,
    # not taking any sub-topic/-dimension into account.
    success*: Rating
    # How much does the project adhere to
    # Open Source (Hardware) best-pracitces.
    openness*: Rating
    # How confident are we,
    # that the project describes hardware
    # (vs e.g. software or data).
    hardware*: Rating
    # How confident are we,
    # that the projects documentation is of high quality.
    quality*: Rating
    # How confident are we,
    # that the project is easily machine readable.
    machineReadability*: Rating

method `*`*(this: CheckRelevancy, multiplier: float32) : CheckRelevancy {.base.} =
  CheckRelevancy(
    weight: this.weight * multiplier,
    openness: this.openness * multiplier,
    hardware: this.hardware * multiplier,
    quality: this.quality * multiplier,
    machineReadability: this.machineReadability * multiplier,
  )

method `+=`*(this: var CheckRelevancy, other: CheckRelevancy) {.base.} =
  this.weight += + other.weight
  this.openness += other.openness
  this.hardware += other.hardware
  this.quality += other.quality
  this.machineReadability += other.machineReadability

method `/=`*(this: var CheckRelevancy, other: CheckRelevancy) {.base.} =
  this.weight /= other.weight
  this.openness /= other.openness
  this.hardware /= other.hardware
  this.quality /= other.quality
  this.machineReadability /= other.machineReadability

method `/=`*(this: var CheckRelevancy, dividend: float32) {.base.} =
  this.weight /= dividend
  this.openness /= dividend
  this.hardware /= dividend
  this.quality /= dividend
  this.machineReadability /= dividend

proc toPercentStr*(factor: float32): string =
  formatFloat(factor*100.0, format=ffDecimal, precision=2)

proc toColorName*(factor: float32): string =
  if factor >= 0.9:
    "green"
  elif factor >= 0.5:
    "yellow"
  else:
    "red"

proc newRating*(name: string, factor: float32): Rating =
  let percent = toPercentStr(factor)
  let color = toColorName(factor)
  let nameEnc = encodeUrl(name, usePlus = false)
  return Rating(
    name: name,
    factor: factor,
    percent: percent,
    color: color,
    badgeUrl: fmt"https://img.shields.io/badge/{nameEnc}-{percent}%25-{color}",
  )

method intoRatings*(this: CheckRelevancy): Ratings {.base.} =
  return Ratings(
    success: newRating("OSH Tool Success", this.weight),
    openness: newRating("OSH Openness", this.openness),
    hardware: newRating("is hardware", this.hardware),
    quality: newRating("OSH Documentation Quality", this.quality),
    machineReadability: newRating("OSH Machine Readability", this.machineReadability),
  )

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

proc toColor*(importance: CheckIssueImportance): string =
  return case importance:
    of DeveloperFailure: "pink"
    of Severe: "red"
    of Middle: "orange"
    of Light: "light-blue"

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

method getRatingFactors*(this: Check): CheckRelevancy {.base.} =
  echo "TODO Override!"
  quit 98

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
