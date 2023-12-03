# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import std/json
import std/logging
import std/strformat
import options
import tables
import ./check
import ./check_config
import ./invalid_config_exception
import ./util/leightweight
import schemaValidator

importAll("checks")

type
  ChecksRegistry* = object
    index*: OrderedTable[string, CheckGenerator]
      ## Contains each check(-generator) exactly once,
      ## indexed and ordered by check(-type)s ID,
      ## which equals the checks nim source file name
      ## without the ".nim" extension.
    configSchemas*: OrderedTable[string, JsonNode]
      ## Contains each check(-generator) parsed JSON Schema,
      ## iff one was specified.
      ## These are only checkd to be valid JSON when inserted in here,
      ## not checkd to be valid JSON _Schema_s yet.
    checks: OrderedTable[string, check.Check]
      ## Contains a mapping of *primary* check-IDs
      ## to their instances, if they were already created.

proc new*(this: typedesc[ChecksRegistry]): ChecksRegistry =
  return ChecksRegistry(
    index: initOrderedTable[string, CheckGenerator](),
    checks: initOrderedTable[string, check.Check](),
    )

method register*(this: var ChecksRegistry, checkGenerator: CheckGenerator) {.base.} =
  let configSchemaOpt = checkGenerator.configSchema()
  if configSchemaOpt.isSome:
    let configSchema = configSchemaOpt.get()
    this.configSchemas[checkGenerator.id()] = configSchema
  this.index[checkGenerator.id()] = checkGenerator

method sort*(this: var ChecksRegistry) {.base.} =
  this.index.sort(proc (x, y: (string, CheckGenerator)): int = cmp(x[0], y[0]))
  this.checks.sort(proc (x, y: (string, Check)): int = cmp(x[0], y[0]))

method registerGenerators*(this: var ChecksRegistry) {.base.} =
  registerAll("checks")

method getCheck*(this: var ChecksRegistry, config: CheckConfig): check.Check {.base.} =
  let id = config.id
  let generator = this.index[id]
  if this.checks.contains(id):
    return this.checks[id]
  else:
    if this.configSchemas.contains(id):
      let schema = this.configSchemas[id]
      debug fmt"Test {id} config schema parsed: '{json.pretty(schema)}'."
      let data = if config.json.isSome():
          config.json.get()
        else:
          info fmt"Test {id} has a configuration schema defined, but no configuration was given for that test. This could be a problem, if any config properties are required."
          json.parseJson("{}")
      let valid = schemaValidator.validate(schema, data)
      if valid:
        info fmt"Configuration for test {id} is valid!"
      else:
        error fmt"Configuration for test {id} is invalid!"
        raise InvalidConfigException.newException(
          fmt "Config for test {id} did not validate against the checks configuration JSON Schema")
    let check = generator.generate(config)
    this.checks[id] = check
    return check

method getChecks*(this: var ChecksRegistry, config: OrderedTable[string, CheckConfig]): OrderedTable[string, check.Check] {.base.} =
  for primaryId, checkConfig in config:
    discard this.getCheck(checkConfig)
  this.sort()
  return this.checks

proc getAllChecksDefaultConfig*(this: var ChecksRegistry): OrderedTable[string, CheckConfig] =
  this.registerGenerators()
  var checkConfigs = initOrderedTable[string, CheckConfig]()
  for (id, generator) in this.index.pairs():
    if generator.isEnabled():
      checkConfigs[id] = newCheckConfig(id)
    else:
      info fmt"Not registering check {id} into list of default checks, because it is marked as not enabled."
  return checkConfigs
