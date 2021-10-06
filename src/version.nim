# SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: Unlicense

# Use this file as an include (NOT an import!)
# wherever you need access to this softwares version:
# ```
# include ./version
# print(version)
# ```
#
# This approach is suggested by Nims author, here:
# https://forum.nim-lang.org/t/7231#45682
#
# You usually want to include this in the projects *.nimble file
# and in the main file/where you want supply it to the user
# at runtime with 'this-tool --version'.
#
# An alternatie approach which only works for nimble projects,
# is to manually specify the version in the *.nimble file,
# and use this in the projects code wherever you need access to the version:
# ```
# const NimblePkgVersion {.strdefine.} = "<UNKNOWN>"
# ```
# The value of this const gets replaced by nimble when compiling.

const version = "0.1.0"
