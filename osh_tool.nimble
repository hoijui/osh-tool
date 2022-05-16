# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: Unlicense

include ./src/version
author      = "Robin Vobruba <hoijui.quaero@gmail.com>"
description = "A Tool for managing Open Source Hardware projects, taking care of meta-data and keeping the structure clean"
license     = "AGPL3"

namedBin["src/main"] = "osh"
binDir = "build"

requires "nim >= 0.10.0"
requires "docopt"
requires "shell"
requires "regex"
