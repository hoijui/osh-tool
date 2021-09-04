<!--
SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>

SPDX-License-Identifier: CC0-1.0
-->

[![License: GPL v3](
	https://img.shields.io/badge/License-GPLv3-blue.svg)](
	https://www.gnu.org/licenses/gpl-3.0)
[![REUSE status](
	https://api.reuse.software/badge/gitlab.com/OSEGermany/osh-tool)](
	https://api.reuse.software/info/gitlab.com/OSEGermany/osh-tool)

# `osh`-tool

A command line tool for Open Source Hardware (OSH) technical project linting (quality assessment).

[Download binaries](https://osegermany.gitlab.io/osh-tool/)
(latest build, Linux & Windows, 64bit)

What it can do:

* Initialize a project repository
* Check for compliance
* Update compliance automatically, as much as possible

## Features

* Generate/Check README
* Generate/Check LICENSE
* Generate/Check [okh.toml](https://github.com/OPEN-NEXT/OKH-LOSH/blob/master/OKH-LOSH.ttl)
  ([Open Know-How](https://openknowhow.org) OSH meta-data file)

## Requires

* Nim and Nimble, version 0.10.0 or higher

## Install

### From repository

```sh
# Latest released version
nimble install osh
# Latest developmental state inside git repository
nimble install osh@#head
```

### From local sources

For example when using a local git clone.

```sh
nimble build
./osh --help
```

## Usage

Simply run `osh -h` to see usage information.

## Community

Ask anything, as an issue!

## Similar Projects

We are not just standing on the shoulders of giants,
but also shoulder on shoulder with them!

These are two of our big sister projects.
They are similar both in spirit
and in the way they are used on the command-line.
They also work well in combination with this tool.

* [`git`](https://git-scm.com/) -
  Master of history
* [`reuse`](https://git.fsfe.org/reuse/tool) -
  Handles all things regarding licensing of a project and its sources

## License

GNU General Public License version 3

