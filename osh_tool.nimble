# SPDX-FileCopyrightText: 2021-2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: Unlicense

version = "0.4.0"
author      = "Robin Vobruba <hoijui.quaero@gmail.com>"
description = "A Tool for managing Open Source Hardware projects, taking care of meta-data and keeping the structure clean"
license     = "AGPL3"

namedBin["src/main"] = "osh"
binDir = "build"

requires "nim >= 2.0.0"
requires "csvtools"
# HACK Until our fix for nim 2 gets merged and released into upstream docopt, we use our own repo
#requires "docopt"
requires "https://github.com/hoijui/docopt.nim#3e8130e"
requires "shell"
requires "regex"
requires "result"
