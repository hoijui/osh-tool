# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# TODO We may want to introduce a small DSL for reducing checks (and init_updates) boilerplate code; see https://github.com/GaryM-exkage/GDGW-Maverick-Bot/blob/master/src/nimcordbot/command/command.nim

import logging
import json
import options
import tables
import strformat
import strutils
import uri
import ./state
from ./util/leightweight import toPercentStr
import ./check_config
import ./invalid_config_exception

type
  CheckResultKind* {.pure.} = enum
    ## The basic states the result of running a checks
    ## on a project may yield.
    Perfect,
      ## Not a single thing could be better
    Ok,
      ## Still quite good, but could be better.
      ## For a more specific understanding,
      ## one has to check out the individual checks implementations;
      ## as in: their code.
    Acceptable,
      ## worse then `Ok`, but not yet `Bad`.
    Bad,
      ## The worst state a check can result in.
      ## Would we be in school, this would be a failing grade.
    Inapplicable

  CheckIssueSeverity* {.pure.} = enum
    ## The result of a check run can come with `CheckIssue`s,
    ## which further describe what would have to change in the project
    ## to get a better rating according to that check.
    DeveloperFailure, High, Middle, Low, Info

  CheckIssue* = object
    ## The result of a checks run may include 0, 1 or more instnaces of this.
    ## An issue further describes what would have to change in the project,
    ## for it to get a better rating according to the specific check.
    severity*: CheckIssueSeverity
      ## Giving an idea how important this issue is
    msg*: Option[string]
      ## A message describing the issue in some detail to a human audience.

  CheckResult* = object
    ## A container for all the data that makes up the result/scoring,
    ## by running a single check on a project.
    config*: CheckConfig
      ## The configuration that was used to generate this result.
    kind*: CheckResultKind
      ## The main status indicator of the check run.
    issues*: seq[CheckIssue]
      ## Zero or more issues
    # msg*: Option[string]

  CheckReq* {.size: sizeof(cint).} = enum
    ## Requirements of a check at runtime.
    Online
      ## Requires a connection to the internet
    FilesListRec
      ## Requires the recursive directory tree of the project files
    FilesListRecNonGen
      ## Requires the recursive directory tree of the project files,
      ## plus osh-dir-std to be available to filter files&dirs out,
      ## which are allowed to be generated
    FilesListL1
      ## Requires the list of files in the root of the project
    FileContent
      ## Requires access to the contents of one or more files in the project
    ProjMetaData
      ## Requires access to the the projects meta-data, like:
      ## name, git-clone URL, current version, ...
      ## This will be fetched with 'projvar',
      ## and then be available through [`state.projVars`].
    ExternalTool
      ## Requires executing an external tool, for example `reuse lint`
  CheckReqs* = set[CheckReq]

  ReportPrelude* = object
    ## Data about the report that is available *before* running the checks.
    config*: JsonNode
    homepage*: string
    projVars*: TableRef[string, string]
      ## Project meta-data; see <https://github.com/hoijui/projvar/>
    tool_versions*: tuple[
      osh: string,
      okh: string,
      reuse: string,
      projvar: string,
      mlc: string,
      mle: string,
      osh_dir_std: string,
    ]
      ## The versions of external CLI tools used by the checks.

  ReportStats* = object
    ## Statistical and rating/compliance related data,
    ## making up a report.
    ## All this data is only available *after* running the checks.
    checks*: tuple[
      run: int, ## Number of checks that were executed/that ran.
        ## This should equal `available` - `skipped`.
      skipped: int, ## Number of checks that were skipped, due to being inapplicable.
        ## See `CheckResult.isApplicable()`.
      passed: int, ## Number of checks that passed.
        ## See `CheckResult.isGood()`.
        ## This should equal `run` - `failed`.
      failed: int, ## Number of checks that did not pass.
        ## This should equal `run` - `passed`.
      available: int,## Number of checks that are available.
        ## This should equal `run` + `skipped`. 
      complianceSum: float, ## The sum over the unweighted compliance factors
        ## of all checks that ran.
      weightsSum: float, ## The sum over the weights
        ## of all checks that ran.
      weightedComplianceSum: float, ## The sum over the weighted compliance factors
        ## of all checks that ran.
      customCompliance: tuple[
        passed: int, ## The number of tests that passed, according to their custom config.
        failed: int, ## The number of tests that failed, according to their custom config.
        notConfigured: int, ## The number of tests run that had no custom config.
        ], ## Checks statistics related to their individual,
        ## custom, required compliance factor, as provided in the configuration.
      ]
      ## Rough statistical data about the running of the checks.
    issues*: Table[string, int]
      ## How many times each `CheckIssueSeverity` variant appeared
      ## in all check runs combined.
    ratings*: Ratings
      ## Ratings of the project,
      ## each one on a different topic/dimension/axis.

  CheckSignificance* = object
    ## How much a check is relevant for the different ratings.
    ## All values go from 0.0 for not relevant at all,
    ## to 1.0 for very relevant.
    weight*: float32
      ## How relevant/important is the check in general.
      ## For combined ratings, this gets multiplied with all the other
    openness*: float32
      ## How relevant is the check to determine how much the project
      ## adheres to Open Source (Hardware) best-pracitces.
    hardware*: float32
      ## How relevant is the check to determine whether the project
      ## describes hardware.
    quality*: float32
      ## How relevant is the check to determine whether the project
      ## is of high quality.
    machineReadability*: float32
      ## How relevant is the check to determine whether the project
      ## is easily machine readable.

  Rating* = object
    ## A single rating for a project,
    ## representing its compliance or failure on a specific axis/dimension,
    ## e.g. openness or documentation quality.
    name*: string
      ## Human readable, Title Case name of for this rating,
      ## e.g. "Openness".
    factor*: float32
      ## The main value of the rating as a factor,
      ## from 0.0 for total failure,
      ## to 1.0 for complete compliance.
    percent*: string
      ## The same as `factor`,
      ## but as a percentage
      ## with exactly two digits after the comma,
      ## excluding the '%'.
      ## Possible values go from "0.00" to "100.00".
      ## NOTE We only have this as field (vs method), so it gets serilized (e.g. to JSON) - TODO Check if one can serialize function return values too
    color*: string
      ## Lower snakeCase name of the color associated to the rating,
      ## E.g. "red" for low values,
      ## "yellow" for mid-range values,
      ## "green" for high values.
      ## NOTE We only have this as field (vs method), so it gets serilized (e.g. to JSON)
    badgeUrl*: string
      ## URL to a README badge representing this rating,
      ## showing off the `name`, `percentage` and `color`.
      ## NOTE We only have this as field (vs method), so it gets serilized (e.g. to JSON)

  Ratings* = object
    ## How successfull all checks combined ran,
    ## as factors from 0.0 to 1.0,
    ## taking each checks weight into account.
    compliance*: Rating
      ## Overall compliance of check executaion/passing,
      ## not taking any sub-topic/-dimension into account.
    openness*: Rating
      ## How much does the project adhere to
      ## Open Source (Hardware) best-pracitces.
    hardware*: Rating
      ## How confident are we,
      ## that the project describes hardware
      ## (vs e.g. software or data).
    quality*: Rating
      ## How confident are we,
      ## that the projects documentation is of high quality.
    machineReadability*: Rating
      ## How confident are we,
      ## that the project is easily machine readable.

  Check* = ref object of RootObj

  CheckGenerator* = ref object of RootObj

proc isAllCustom*(this: ReportStats) : bool =
  ## Returns `true` if all checks that ran
  ## had a custom required compliance factor configured.
  return this.checks.customCompliance.notConfigured == 0

proc isNoneCustom*(this: ReportStats) : bool =
  ## Returns `true` if none of the checks that ran
  ## had a custom required compliance factor configured.
  return this.checks.customCompliance.notConfigured == this.checks.run

proc isNoneCustomFailed*(this: ReportStats) : bool =
  ## Returns `true` if none of the checks failed that ran
  ## and had a custom required compliance factor configured.
  return this.checks.customCompliance.failed == 0

method `*`*(this: CheckSignificance, multiplier: float32) : CheckSignificance {.base.} =
  CheckSignificance(
    weight: this.weight * multiplier,
    openness: this.openness * multiplier,
    hardware: this.hardware * multiplier,
    quality: this.quality * multiplier,
    machineReadability: this.machineReadability * multiplier,
  )

method `+=`*(this: var CheckSignificance, other: CheckSignificance) {.base.} =
  this.weight += + other.weight
  this.openness += other.openness
  this.hardware += other.hardware
  this.quality += other.quality
  this.machineReadability += other.machineReadability

method `/`*(first: var CheckSignificance, second: CheckSignificance) : CheckSignificance {.base.} =
  CheckSignificance(
    weight: first.weight / second.weight,
    openness: first.openness / second.openness,
    hardware: first.hardware / second.hardware,
    quality: first.quality / second.quality,
    machineReadability: first.machineReadability / second.machineReadability,
  )

method `/=`*(this: var CheckSignificance, other: CheckSignificance) {.base.} =
  this.weight /= other.weight
  this.openness /= other.openness
  this.hardware /= other.hardware
  this.quality /= other.quality
  this.machineReadability /= other.machineReadability

method `/=`*(this: var CheckSignificance, dividend: float32) {.base.} =
  this.weight /= dividend
  this.openness /= dividend
  this.hardware /= dividend
  this.quality /= dividend
  this.machineReadability /= dividend

proc toColorName*(factor: float32): string =
  ## Converts a factor (a float between `[0.0, 1.0]`) -
  ## while assuming 0.0 is undesirably/worst, and 1.0 is desirable/best -
  ## to a name of a color from the web colors palette:
  ## <https://www.w3schools.com/tags/ref_colornames.asp>
  if factor >= 0.9:
    "Green"
  elif factor >= 0.5:
    "Yellow"
  else:
    "Red"

proc newRating*(name: string, factor: float32): Rating =
  ## Instantiates a new `Rating`;
  ## ... no magic here!
  let percent = toPercentStr(factor)
  let color = toColorName(factor).toLower()
  let nameEnc = encodeUrl(name, usePlus = false)
  return Rating(
    name: name,
    factor: factor,
    percent: percent,
    color: color,
    badgeUrl: fmt"https://img.shields.io/badge/{nameEnc}-{percent}%25-{color}",
  )

method intoRatings*(this: CheckSignificance): Ratings {.base.} =
  ## Instantiates a new `Ratings` vector,
  ## based on the  average, weighted `CheckSignificance`
  ## from a run over all checks.
  return Ratings(
    compliance: newRating("OSH Tool Compliance", this.weight),
    openness: newRating("OSH Openness", this.openness),
    hardware: newRating("is hardware", this.hardware),
    quality: newRating("OSH Documentation Quality", this.quality),
    machineReadability: newRating("OSH Machine Readability", this.machineReadability),
  )

proc toNum*(flags: CheckReqs): int =
  ## Converts a variant of the pure enum `CheckReqs`
  ## into an integer.
  ## This is the inverse of `CheckReqs.toCheckReqs(int)`.
  cast[cint](flags)

proc toCheckReqs*(bits: int): CheckReqs =
  ## Converts an integer into a variant
  ## of the pure enum `CheckReqs`.
  ## This is the inverse of `CheckReqs.toNum(CheckReqs)`.
  cast[CheckReqs](bits)

proc newCheckResult*(config: CheckConfig, kind: CheckResultKind): CheckResult =
  ## Creates a check-result without an issue
  return CheckResult(config: config, kind: kind, issues: @[])

proc newCheckResult*(config: CheckConfig, kind: CheckResultKind, severity: CheckIssueSeverity, msg: Option[string]): CheckResult =
  ## Creates a check-result with a single issue
  return CheckResult(
    config: config,
    kind: kind,
    issues: @[
      CheckIssue(
        severity: severity,
        msg: msg
      )
    ]
  )

proc toColor*(severity: CheckIssueSeverity): string =
  ## Converts the severity of an isssue
  ## to a name of a color from the web colors palette:
  ## <https://www.w3schools.com/tags/ref_colornames.asp>
  return case severity:
    of DeveloperFailure: "Pink"
    of High: "Red"
    of Middle: "Orange"
    of Low: "LightBlue"
    of Info: "Black"

proc isApplicable*(res: CheckResult): bool =
  ## Whether the check reported being applicable to the project in question.
  ## It might not be applicable, for example,
  ## if it checks the content of a file for correctness,
  ## but that file is not present in the project.
  return res.kind != Inapplicable

proc isGood*(res: CheckResult): bool =
  ## Whether the check got a passing or a failing "grade".
  return res.kind in [Perfect, Ok, Acceptable]

proc getGoodHumanReadable*(res: CheckResult): string =
  return if res.isGood(): "passed" else: "failed"

proc getGoodColor*(res: CheckResult): string =
  ## Returns a web color name
  ## that fits to the result of `CheckResukt.isGood()`.
  ## It will be part of this pallette:
  ## <https://www.w3schools.com/tags/ref_colornames.asp>
  return if res.isGood(): "Green" else: "Red"

proc getKindColor*(res: CheckResult): string =
  ## Returns a web color name
  ## that fits to `CheckResukt.kind`.
  ## It will be part of this pallette:
  ## <https://www.w3schools.com/tags/ref_colornames.asp>
  return case res.kind:
    of Perfect: "Green"
    of Ok: "DarkGoldenRod"
    of Acceptable: "Orange"
    of Bad: "Red"
    of Inapplicable: "Black"

proc calcCompliance*(res: CheckResult): float32 =
  ## Calculates the compliance factor of executing a check.
  ## Explained here (among other things):
  ## https://github.com/hoijui/osh-tool/issues/27
  let oKind = case res.kind:
    of Perfect:
      1.0
    of Ok:
      0.8
    of Acceptable:
      0.6
    of Bad:
      0.0
    of Inapplicable:
      let errMsg = "Code should never try to calculate the compliance factor of an 'Inapplicable' check!"
      error fmt"Programmer error: {errMsg}"
      raise newException(Defect, errMsg)

  var dedLow = 0.075
  var dedMiddle = 0.15
  var dedHigh = 0.3
  var oIssues = 1.0
  for issue in res.issues:
    let severity = case issue.severity:
      of Info:
        0.0
      of Low:
        dedLow /= 2
        dedLow * 2
      of Middle:
        dedMiddle /= 2
        dedMiddle * 2
      of High:
        dedHigh /= 2
        dedHigh * 2
      of DeveloperFailure:
        0.0
    oIssues -= severity
    if oIssues <= 0.0:
      oIssues = 0.0
      break

  return oKind * oIssues

proc isCustomPassed*(res: CheckResult): Option[bool] =
  ## Whether the user-/config-supplied,
  ## custom compliance factor has been reached.
  ## See `CheckConfig.customReqCompFac`.
  let checkConfig = res.config
  if checkConfig.customReqCompFac.isSome():
    let reqComFactor = checkConfig.customReqCompFac.get()
    if res.calcCompliance() < reqComFactor:
      some(false)
    else:
      some(true)
  else:
    none[bool]()

method id*(this: CheckGenerator): string {.base.} =
  ## Returns a list of short, human&machine oriented, unique IDs/names
  ## of the check that this can generate.
  ## These IDs are used to reffer to the check in configuration.
  return "TODO Override!"

method configSchema*(this: CheckGenerator): Option[JsonNode] {.base.} =
  ## Returns the JSON-Schema for the configuration
  ## of the type of check generated by this.
  return none[JsonNode]()

method defaultConfigJson*(this: CheckGenerator): Option[JsonNode] {.base.} =
  ## Returns the default JSON config for the check type.
  return none[JsonNode]()

method defaultConfig*(this: CheckGenerator): CheckConfig {.base.} =
  ## Returns the default config for the check type.
  let config = newCheckConfig(this.id())
  config.json = this.defaultConfigJson()
  return config

method isEnabled*(this: CheckGenerator): bool {.base.} =
  ## Returns whether this check is enabled by default.
  ## This should only be set to false for unstable and testing checks.
  return true

method generate*(this: CheckGenerator, config: CheckConfig = this.defaultConfig()): Check {.base.} =
  ## Generates a check instance,
  ## using either the default configuration if `none` is supplied,
  ## or configured by the JSON formatted configuration given.
  echo "TODO Override!"
  quit 97

proc ensureNonConfig*(this: CheckGenerator, config: CheckConfig) =
  if config.json.isSome:
    raise InvalidConfigException.newException(fmt"This check ({this.id()}) does not take any configuration")

proc applies*(this: CheckGenerator, id: string): bool =
  ## Checks whether the given ID is a valid identifier
  ## for the check generated by this.
  ## This just means, it is in the list of our IDs.
  this.id.contains(id)

method name*(this: Check): string {.base.} =
  ## Returns the name of the check.
  ## This might often be a description,
  ## but should be kept short.
  return "TODO Override!"

method description*(this: Check): string {.base.} =
  ## Returns a detailed, human oriented description
  ## of what the check checks for.
  return "TODO Override!"

method why*(this: Check): string {.base.} =
  ## Returns a detailed, human oriented explanation
  ## for why this check makes sense.
  return "TODO Override!"

method sourcePath*(this: Check): string {.base.} =
  ## Returns the path to the source file that implements the check,
  ## relative to the root of this tools project root directory.
  return "TODO Override!"

method requirements*(this: Check): CheckReqs {.base.} =
  ## Returns a machine-oriented descriptions of the requriements
  ## to run this check.
  ## This might be, that the list requires a list of all files
  ## of the project to check,
  ## which might not always be available.
  echo "TODO Override!"
  quit 99

method getSignificanceFactors*(this: Check): CheckSignificance {.base.} =
  ## This indicates how relevant this check is
  ## for the different ratings this supplies,
  ## plus the overall weight of this check.
  echo "TODO Override!"
  quit 98

method run*(this: Check, state: var State): CheckResult {.base.} =
  ## Runs this check on a specific project.
  return newCheckResult(
    newCheckConfig("non-ID"),
    CheckResultKind.Bad,
    CheckIssueSeverity.DeveloperFailure,
    some("Not implemented for this specific check!")
  )
