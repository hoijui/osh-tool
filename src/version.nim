# SPDX-FileCopyrightText: 2021-2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: Unlicense

# Use this file as an include (NOT an import!)
# wherever you need access to this softwares version:
# ```
# include ./version
# print(VERSION)
# ```
#
# A different approach is suggested by Nims author:
# https://forum.nim-lang.org/t/7231#45682
#
# You usually want to include this in the projects main file,
# where you want to supply it to the user at runtime
# with 'this-tool --version'.
#
# An alternatie approach which only works for nimble projects,
# is to manually specify the version in the *.nimble file,
# and use this in the projects code wherever you need access to the version:
#
# ```
# const NimblePkgVersion {.strdefine.} = "<UNKNOWN>"
# ```
#
# The value of this const gets replaced by nimble when compiling.

const VERSION = static:
  # This uses the same arguments to `git describe` like the Rust crate `git_version`:
  # https://github.com/fusion-engineering/rust-git-version/blob/master/git-version-macro/src/lib.rs
  let (output, exitCode) = gorgeEx("git describe --always --dirty=-modified")
  doAssert exitCode == 0, output
  output
