# SPDX-FileCopyrightText: 2021-2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: Unlicense

version = "0.3.0"
author      = "Robin Vobruba <hoijui.quaero@gmail.com>"
description = "A Tool for managing Open Source Hardware projects, taking care of meta-data and keeping the structure clean"
license     = "AGPL3"

namedBin["src/main"] = "osh"
binDir = "build"

requires "nim >= 0.10.0"
requires "csvtools"
requires "docopt"
requires "shell"
requires "regex"
requires "result"
