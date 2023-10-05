# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

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
      ## indexed and ordered by the *main*-ID.
    lookup*: Table[string, CheckGenerator]
      ## Contains a mapping of each check-ID
      ## to its corresponding generator.
      ## This *will* contain each check-generator multiple times.
    checks: OrderedTable[string, check.Check]
      ## Contains a mapping of *primary* check-IDs
      ## to their instances, if they were already created.

proc new*(this: typedesc[ChecksRegistry]): ChecksRegistry =
  return ChecksRegistry(
    index: initOrderedTable[string, CheckGenerator](),
    lookup: initTable[string, CheckGenerator](),
    checks: initOrderedTable[string, check.Check](),
    )

method register*(this: var ChecksRegistry, checkGenerator: CheckGenerator) {.base.} =
  this.index[checkGenerator.id()[0]] = checkGenerator
  for id in checkGenerator.id():
    this.lookup[id] = checkGenerator

method sort*(this: var ChecksRegistry) {.base.} =
  this.index.sort(proc (x, y: (string, CheckGenerator)): int = cmp(x[0], y[0]))
  this.checks.sort(proc (x, y: (string, Check)): int = cmp(x[0], y[0]))

method registerGenerators*(this: var ChecksRegistry) {.base.} =
  registerAll("checks")

method getCheck*(this: var ChecksRegistry, config: CheckConfig = CheckConfig(id: "non-ID", json: none[string]())): check.Check {.base.} =
  let generator = this.lookup[config.id]
  let primaryId = generator.id[0]
  if this.checks.contains(primaryId):
    return this.checks[primaryId]
  else:
    let check = generator.generate(config)
    this.checks[primaryId] = check
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
  for primaryId in this.index.keys:
    checkConfigs[primaryId] = CheckConfig(id: primaryId, json: none[string]())
  return checkConfigs
