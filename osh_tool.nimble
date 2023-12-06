# SPDX-FileCopyrightText: 2021-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: Unlicense

version = "0.5.0"
author      = "Robin Vobruba <hoijui.quaero@gmail.com>"
description = "A Tool for managing Open Source Hardware projects, taking care of meta-data and keeping the structure clean"
license     = "AGPL3"

namedBin["src/main"] = "osh"
binDir = "build"

requires "nim >= 2.0.0"
requires "csvtools"
requires "docopt"
requires "https://github.com/hoijui/JsonSchemaValidator"
# HACK We use our own, patched version of this library,
#      until this gets merged upstream:
#      <https://github.com/treeform/jsony/pull/83>
# requires "jsony"
requires "https://github.com/hoijui/jsony#1f57ea0"
requires "shell"
requires "regex"
requires "result"
