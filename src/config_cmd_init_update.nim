# # This file is part of osh-tool.
# # <https://github.com/hoijui/osh-tool>
# #
# # SPDX-FileCopyrightText: 2021 - 2023 Robin Vobruba <hoijui.quaero@gmail.com>
# #
# # SPDX-License-Identifier: AGPL-3.0-or-later

# import docopt
# import json
# # import std/jsonutils
# import options
# import streams
# import tables
# import ./init_update_config
# import ./config_common
# import ./util/leightweight

# type
#   ConfigCmdInitUpdateOpt* = ref object of CommonConfigOpt
#     initUpdate*: Option[OrderedTable[string, Option[InitUpdateConfig]]]

#   ConfigCmdInitUpdate* = ref object of CommonConfig
#     ## Same like `ConfigCmdInitUpdateOpt`, but with certainty.
#     initUpdate*: OrderedTable[string, Option[InitUpdateConfig]]

# proc new*(super: CommonConfigOpt): ConfigCmdInitUpdateOpt =
#   return ConfigCmdInitUpdateOpt(
#     projRoot: super.projRoot,
#     projPrefixes: super.projPrefixes,
#     projVars: super.projVars,
#     reportTargets: super.reportTargets,
#     force: super.force,
#     offline: super.offline,
#     electronics: super.electronics,
#     mechanics: super.mechanics,
#     initUpdate: none[OrderedTable[string, Option[InitUpdateConfig]]](),
#   )

# proc new*(): ConfigCmdInitUpdateOpt =
#   new(config_common.new())

# proc fromArgs*(args: Table[string, docopt.Value]): ConfigCmdInitUpdateOpt =
#   let configCommon = config_common.fromArgs(args)
#   var config = new(configCommon)
  
#   # let initUpdateConfigFile = if args["--initUpdate"]:
#   #     debug "Using config file:"
#   #     let cfgFile = $args["--initUpdate"]
#   #     debug cfgFile
#   #     some(cfgFile)
#   #   else:
#   #     none[string]()
#   # # let initUpdate = none[OrderedTable[string, Option[InitUpdateConfig]]]()
#   # let initUpdate = parseInitUpdatesConfig(initUpdateConfigFile)

#   return config

# proc extendWith*(this: var ConfigCmdInitUpdateOpt, other: ConfigCmdInitUpdateOpt) =
#   this.projRoot = this.projRoot.orr(other.projRoot)
#   this.projPrefixes = this.projPrefixes.orr(other.projPrefixes)
#   this.projVars = this.projVars.orr(other.projVars)
#   this.reportTargets = this.reportTargets.orr(other.reportTargets)
#   this.force = this.force.orr(other.force)
#   this.offline = this.offline.orr(other.offline)
#   this.electronics = this.electronics.orr(other.electronics)
#   this.mechanics = this.mechanics.orr(other.mechanics)
#   this.initUpdate = this.initUpdate.orr(other.initUpdate)

# proc extendWithDefaults*(this: ConfigCmdInitUpdateOpt, allInitUpdatesDefaultConfigCreator: (proc(): OrderedTable[string, Option[InitUpdateConfig]] {.cdecl, gcsafe.})): ConfigCmdInitUpdate =

#   let superOut = config_common.extendWithDefaults(this)
#   let initUpdate = if this.initUpdate.isSome():
#       this.initUpdate.get()
#     else:
#       allInitUpdatesDefaultConfigCreator()
#   return ConfigCmdInitUpdate(
#     projRoot: superOut.projRoot,
#     projPrefixes: superOut.projPrefixes,
#     projVars: superOut.projVars,
#     reportTargets: superOut.reportTargets,
#     force: superOut.force,
#     offline: superOut.offline,
#     electronics: superOut.electronics,
#     mechanics: superOut.mechanics,
#     initUpdate: initUpdate,
#   )
