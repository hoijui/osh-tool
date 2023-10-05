# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import ./init_update
import ./init_update_config
import ./util/leightweight
import options
import tables

importAll("init_update")

type
  InitUpdatesRegistry* = object
    index*: OrderedTable[string, InitUpdateGenerator]
      ## Contains each initUpdate(-generator) exactly once,
      ## indexed and ordered by the *main*-ID.
    lookup*: Table[string, InitUpdateGenerator]
      ## Contains a mapping of each initUpdate-ID
      ## to its corresponding generator.
      ## This *will* contain each initUpdate-generator multiple times.
    initUpdates: OrderedTable[string, initUpdate.InitUpdate]
      ## Contains a mapping of *primary* initUpdate-IDs
      ## to their instances, if they were already created.

method register*(this: var InitUpdatesRegistry, initUpdateGenerator: InitUpdateGenerator) {.base.} =
  this.index[initUpdateGenerator.id()[0]] = initUpdateGenerator
  for id in initUpdateGenerator.id():
    this.lookup[id] = initUpdateGenerator

method sort*(this: var InitUpdatesRegistry) {.base.} =
  this.index.sort(proc (x, y: (string, InitUpdateGenerator)): int = cmp(x[0], y[0]))
  this.initUpdates.sort(proc (x, y: (string, InitUpdate)): int = cmp(x[0], y[0]))

method registerGenerators*(this: var InitUpdatesRegistry) {.base.} =
  registerAll("init_update")

method getInitUpdate*(this: var InitUpdatesRegistry, id: string, config: Option[InitUpdateConfig]): init_update.InitUpdate {.base.} =
  let generator = this.lookup[id]
  let primaryId = generator.id[0]
  if this.initUpdates.contains(primaryId):
    return this.initUpdates[primaryId]
  else:
    let initUpdate = generator.generate(config)
    this.initUpdates[primaryId] = initUpdate
    return initUpdate

method getAllInitUpdates*(this: var InitUpdatesRegistry, config: Option[OrderedTable[string, Option[InitUpdateConfig]]]): OrderedTable[string, init_update.InitUpdate] {.base.} =
  if config.isSome():
    for primaryId, initUpdateConfig in config.get():
      discard this.getInitUpdate(primaryId, initUpdateConfig)
  else:
    for primaryId, initUpdateGenerator in this.index:
      discard this.getInitUpdate(primaryId, none[InitUpdateConfig]())
  this.sort()
  return this.initUpdates

proc newInitUpdatesRegistry*(): InitUpdatesRegistry =
  return InitUpdatesRegistry(
    index: initOrderedTable[string, InitUpdateGenerator](),
    lookup: initTable[string, InitUpdateGenerator](),
    initUpdates: initOrderedTable[string, InitUpdate](),
    )
