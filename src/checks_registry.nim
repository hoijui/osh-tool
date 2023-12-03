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
import ./util/leightweight

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

method getCheck*(this: var ChecksRegistry, config: CheckConfig = newCheckConfig("non-ID")): check.Check {.base.} =
  let id = config.id
  let generator = this.index[id]
  if this.checks.contains(id):
    return this.checks[id]
  else:
    let check = generator.generate(config)
    this.checks[id] = check
    return check

method getChecks*(this: var ChecksRegistry, config: Option[OrderedTable[string, CheckConfig]] = none[OrderedTable[string, CheckConfig]]()): OrderedTable[string, check.Check] {.base.} =
  if config.isSome():
    for primaryId, checkConfig in config.get():
      discard this.getCheck(checkConfig)
  else:
    for primaryId, checkGenerator in this.index:
      discard this.getCheck()
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
