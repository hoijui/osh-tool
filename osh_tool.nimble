# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: CC0-1.0

# Package

version     = "0.1.0"
author      = "Robin Vobruba <hoijui.quaero@gmail.com>"
description = "A Tool for managing Open Source Hardware projects, taking care of meta-data and keeping the structure clean"
license     = "GPL3"

namedBin["src/main"] = "osh"
binDir = "build"

# Deps

requires "nim >= 0.10.0"
requires "docopt"
requires "shell"
