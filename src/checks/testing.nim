# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options
import strformat
import std/json
import std/jsonutils
import tables
import ../check
import ../check_config
import ../invalid_config_exception
import ../state
import ../util/fs

#const IDS = @[srcFileNameBase()]
const ID = srcFileNameBase()
const CONFIG_JSON_SCHEMA = """
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://raw.githubusercontent.com/hoijui/osh-tool/master/src/checks/testing.config.schema.json",
  "title": "OSH-Tool - check: testing -  configuration",
  "description": "The JSON-Schema to validate the configuration for the osh-tool check 'testing', defined in testing.nim.",
  "type": "object",
  "properties": {
    "pass": {
      "description": "Whether this check should pass (true) or fail (false)",
      "type": "boolean"
    }
  },
  "required": [ "pass" ]
}
"""

type TestingCheck = ref object of Check
  config: JsonNode
type TestingCheckGenerator = ref object of CheckGenerator

method name*(this: TestingCheck): string =
  return "Tool internal testing"

method description*(this: TestingCheck): string =
  return fmt"""This check is only for those testing development of checks for this tool. \
Do not use it in production!"""

method why*(this: TestingCheck): string =
  return """Checking out this tests source code, \
one can learn how to write a check with a custom configuration."""

method sourcePath*(this: TestingCheck): string =
  return fs.srcFileName()

method requirements*(this: TestingCheck): CheckReqs =
  return { }

method getSignificanceFactors*(this: TestingCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.0,
    openness: 0.0,
    hardware: 0.0,
    quality: 0.0,
    machineReadability: 0.0,
    )

method configSchema*(this: TestingCheckGenerator): Option[JsonNode] =
  return some(json.parseJson(CONFIG_JSON_SCHEMA))

# TODO Remove this proc entirely, when copy&pasting this file, to use it as a template for your own check
method isEnabled*(this: TestingCheckGenerator): bool =
  return false

method run*(this: TestingCheck, state: var State): CheckResult =
  let config = state.config.checks[ID]
  let pass = this.config["pass"].getBool()
  return (if pass:
    newCheckResult(config, CheckResultKind.Perfect)
  else:
    newCheckResult(
      config,
      CheckResultKind.Bad,
      CheckIssueSeverity.High,
      some("""This test was configured to fail.""")
    )
  )

method id*(this: TestingCheckGenerator): string =
  return ID

method generate*(this: TestingCheckGenerator, config: CheckConfig = newCheckConfig(ID)): Check =
  if config.json.isNone():
    raise InvalidConfigException.newException(
      fmt"This check ({this.id()}) requires a configuration to be set")
  let jsonConfig = jsonutils.toJson(config.json.get())
  if not jsonConfig.contains("pass"):
    raise InvalidConfigException.newException(
      fmt"This check ({this.id()}) requires the ocnfig property 'pass' (boolean) to be set")
  TestingCheck(config: jsonConfig)

proc createGenerator*(): CheckGenerator =
  TestingCheckGenerator()
