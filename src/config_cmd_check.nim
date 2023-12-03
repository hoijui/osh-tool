# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import docopt
import json
import jsony
import options
import std/sets
import strformat
import strutils
import tables
import ./check_config
import ./config_common
import ./util/leightweight

type
  ConfigCmdCheckOpt* = ref object #of CommonConfigOpt
    ## This is designed to directly map
    ## to the (JSON) config file for a check run.
    ## It is used to parse that file only,
    ## after which the values in here get transferred to -
    ## extended with default-values where needed -
    ## the actual config container `RunConfig`.
    ## For a setting to be optional to define in the config file,
    ## it has to be wrapped with `Option[...]` in here.
    projRoot*: Option[string]
      ## The local file-system root of this project
      ## as an absolute, canonical path.
    projPrefixes*: Option[seq[string]]
      ## A list of roots/prefixes (excluding `projRoot`)
      ## this project might be found at.
      ## This are either absolute paths
      ## to directories on the local file-system,
      ## or web base-URLs.
      ## Examples:
      ## * /home/user/repos/myProj/
      ## * https://github.com/user/myProj/
      ## * NOT: https://user.github.io/myProj/
    projVars*: Option[TableRef[string, string]]
      ## Project specific properties, as produced by [`projvar`](https://github.com/hoijui/projvar/).
    reportTargets*: Option[seq[Report]]
      ## Where evaluation output gets written to.
      ## Stdout if None, else a file.
    force*: Option[bool]
      ## Whether output files get overwritten if they exist,
      ## or the application exits with an error.
    offline*: Option[bool]
      ## Whether to do everything without accessing the internet,
      ## and skip everything that does not work without it.
    electronics*: Option[YesNoAuto]
      ## Whether to treat the project as an electronics project -
      ## meaning, one that contains schematics and PCB designs.
    mechanics*: Option[YesNoAuto]
    checks*: Option[seq[CheckConfig]]

  ConfigCmdCheck* = ref object #of CommonConfig
    ## Same like `ConfigCmdCheckOpt`, but with certainty.
    projRoot*: string
    projPrefixes*: seq[string]
    projVars*: TableRef[string, string]
    reportTargets*: seq[Report]
    force*: bool
    offline*: bool
    electronics*: YesNoAuto
    mechanics*: YesNoAuto
    checks*: OrderedTable[string, CheckConfig]

proc new*(configType: typedesc[ConfigCmdCheckOpt], super: CommonConfigOpt): ConfigCmdCheckOpt =
  return configType(
    projRoot: super.projRoot,
    projPrefixes: super.projPrefixes,
    projVars: super.projVars,
    reportTargets: super.reportTargets,
    force: super.force,
    offline: super.offline,
    electronics: super.electronics,
    mechanics: super.mechanics,
    checks: none[seq[CheckConfig]](),
  )

proc new*(configType: typedesc[ConfigCmdCheckOpt]): ConfigCmdCheckOpt =
  configType.new(CommonConfigOpt.new())

proc fromArgs*(configType: typedesc[ConfigCmdCheckOpt], args: Table[string, docopt.Value]): ConfigCmdCheckOpt =
  let configCommon = CommonConfigOpt.fromArgs(args)
  let config = ConfigCmdCheckOpt.new(configCommon)
  return config

proc plainToTable*(plain: seq[CheckConfig]): OrderedTable[string, CheckConfig] =
  var table = initOrderedTable[string, CheckConfig]()
  for cfg in plain:
    table[cfg.id] = cfg
  return table

proc tableToPlain*(table: OrderedTable[string, CheckConfig]): seq[CheckConfig] =
  var plain = newSeq[CheckConfig]()
  for id, cfg in table:
    plain.add(cfg)
  return plain

proc toOpt*(this: ConfigCmdCheck): ConfigCmdCheckOpt =
  ConfigCmdCheckOpt(
    projRoot: some(this.projRoot),
    projPrefixes: some(this.projPrefixes),
    reportTargets: some(this.reportTargets),
    force: some(this.force),
    offline: some(this.offline),
    electronics: some(this.electronics),
    mechanics: some(this.mechanics),
    checks: some(tableToPlain(this.checks)),
  )

proc extendWith*(this: var ConfigCmdCheckOpt, other: ConfigCmdCheckOpt) =
  this.projRoot = this.projRoot.orr(other.projRoot)
  this.projPrefixes = this.projPrefixes.orr(other.projPrefixes)
  this.projVars = this.projVars.orr(other.projVars)
  this.reportTargets = this.reportTargets.orr(other.reportTargets)
  this.force = this.force.orr(other.force)
  this.offline = this.offline.orr(other.offline)
  this.electronics = this.electronics.orr(other.electronics)
  this.mechanics = this.mechanics.orr(other.mechanics)
  this.checks = this.checks.orr(other.checks)

proc toCommon*(this: ConfigCmdCheckOpt): CommonConfigOpt =
  return CommonConfigOpt(
    projRoot: this.projRoot,
    projPrefixes: this.projPrefixes,
    projVars: this.projVars,
    reportTargets: this.reportTargets,
    force: this.force,
    offline: this.offline,
    electronics: this.electronics,
    mechanics: this.mechanics,
  )

proc extendWithDefaults*(this: ConfigCmdCheckOpt, allChecksDefaultConfig: OrderedTable[string, CheckConfig]): ConfigCmdCheck =
  let superOut = config_common.extendWithDefaults(this.toCommon())
  let checks = if this.checks.isSome():
      plainToTable(this.checks.get())
    else:
      allChecksDefaultConfig
  return ConfigCmdCheck(
    projRoot: superOut.projRoot,
    projPrefixes: superOut.projPrefixes,
    projVars: superOut.projVars,
    reportTargets: superOut.reportTargets,
    force: superOut.force,
    offline: superOut.offline,
    electronics: superOut.electronics,
    mechanics: superOut.mechanics,
    checks: checks,
  )

proc dumpHook*(s: var string, v: object)
proc dumpHook*(s: var string, v: ref object)
proc dumpHook*[N, T](s: var string, v: array[N, T])
proc dumpHook*[T](s: var string, v: seq[T])
type t[T] = tuple[a: string, b: T]
proc dumpHook*[N, T](s: var string, v: array[N, t[T]])

proc dumpKeyValuePair[VT](s: var string, k: string, v: VT, i: var int) =
  let dump = when compiles(v.isNone()):
      if v.isNone():
        false
      else:
        true
    else:
      true
  if dump:
    if i > 0:
      s.add ','
    s.dumpHook(k)
    s.add ':'
    s.dumpHook(v)
    inc i

proc dumpValue[VT](s: var string, v: VT, i: var int) =
  let dump = when compiles(v.isNone()):
      if e.isNone():
        false
      else:
        true
    else:
      true
  if dump:
    if i > 0:
      s.add ','
    s.dumpHook(v)
    inc i

proc dumpHook*(s: var string, v: object) =
  s.add '{'
  var i = 0
  when compiles(for k, e in v.pairs: discard):
    # Tables and table like objects.
    for k, e in v.pairs:
      dumpKeyValuePair(s, k, e, i)
  else:
    # Normal objects.
    for k, e in v.fieldPairs:
      dumpKeyValuePair(s, k, e, i)
  s.add '}'

proc dumpHook*(s: var string, v: ref object) =
  s.add '{'
  var i = 0
  when compiles(for k, e in v.pairs: discard):
    # Tables and table like objects.
    for k, e in v.pairs:
      dumpKeyValuePair(s, k, e, i)
  else:
    # Normal objects.
    for k, e in v[].fieldPairs:
      dumpKeyValuePair(s, k, e, i)
  s.add '}'

proc dumpHook*[N, T](s: var string, v: array[N, T]) =
  s.add '['
  var i = 0
  for e in v:
    dumpValue(s, e, i)
  s.add ']'

proc dumpHook*[T](s: var string, v: seq[T]) =
  s.add '['
  var j = 0
  for i, e in v:
    dumpValue(s, e, j)
  s.add ']'

proc dumpHook*[N, T](s: var string, v: array[N, t[T]]) =
  s.add '{'
  var i = 0
  # Normal objects.
  for (k, e) in v:
    dumpKeyValuePair(s, k, e, i)
  s.add '}'

proc enumHook*(val: string, v: var YesNoAuto) =
  v = case val.toLower():
    of "yes": Yes
    of "no": No
    of "auto": Auto
    else: raise newException(IOError, fmt("Failed to parse value '{val}' into a YesNoAuto enum variant"))

proc toJson*(this: ConfigCmdCheckOpt): JsonNode =
  ## Converts the configuration into a JSON node.
  ## Unset values (Option types set to none)
  ## will be left out of the string completely.
  let jsonStr = jsony.toJson(this)
  return json.parseJson(jsonStr)

proc toJsonStr*(this: ConfigCmdCheckOpt): string =
  ## Converts the configuration into a pretty JSON string.
  ## Unset values (Option types set to none)
  ## will be left out of the string completely.
  let jsonNode = this.toJson()
  return json.pretty(jsonNode)

proc writeJson*(this: ConfigCmdCheckOpt, configFile: string) =
  ## Writes a pretty JSON version of this configuration
  ## to the give path.
  ## See `toJsonStr` for more details.
  let jsonStr = this.toJsonStr()
  writeFile(configFile, jsonStr)

proc fromJsonStr(t: typedesc[ConfigCmdCheckOpt], jsonStr: string): ConfigCmdCheckOpt =
  ## Parses a given string as JSON into a configuration object.
  ## Values not present in the JSON will be set to the Option variant none.
  return jsony.fromJson(jsonStr, ConfigCmdCheckOpt)

proc parseJsonFile*(t: typedesc[ConfigCmdCheckOpt], configFile: string): ConfigCmdCheckOpt =
  ## Parses the content of the given file as JSON into a configuration object.
  ## See 'fromJsonStr' for more details.
  let jsonStr = readFile(configFile)
  return t.fromJsonStr(jsonStr)
