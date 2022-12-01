<!--
SPDX-FileCopyrightText: 2021 Robin Vobruba <hoijui.quaero@gmail.com>

SPDX-License-Identifier: CC0-1.0
-->

# `osh`-tool

[![License: AGPL v3+](
    https://img.shields.io/badge/License-AGPL%20v3+-blue.svg)](
    https://www.gnu.org/licenses/agpl-3.0)
[![REUSE status](
    https://api.reuse.software/badge/gitlab.com/OSEGermany/osh-tool)](
    https://api.reuse.software/info/gitlab.com/OSEGermany/osh-tool)
[![In cooperation with FabCity Hamburg](
    https://custom-icon-badges.demolab.com/badge/-FCHH-dddddd.svg?logo=fc_logo)](
    https://fabcity.hamburg)
[![In cooperation with Open Source Ecology Germany](
    https://custom-icon-badges.demolab.com/badge/-OSEG-555555.svg?logo=oseg_logo)](
    https://opensourceecology.de)

A command line tool for Open Source Hardware (OSH)
technical project linting (quality assessment).

[Download binaries](https://osegermany.gitlab.io/osh-tool/)
(latest build, Linux & Windows, 64bit)

What it can do:

* Check for compliance

What it will additionally do in the future:

* Initialize a project repository
* Update compliance automatically, as much as possible

## Example Projects

Two sample hardware projects,
using this tool to check their own Open Source'ness
with the help of this tool,
executed in [CI](https://en.wikipedia.org/wiki/Continuous_integration).
The generated report is linked to form the README in a badge
(image after the title) with the text "OSH Report".

* GitLab CI
  * <https://gitlab.com/OSEGermany/ohloom>
  * [Generated Report](https://osegermany.gitlab.io/ohloom/osh-report.html)
  * [CI script](https://gitlab.com/OSEGermany/ohloom/-/blob/master/.gitlab-ci.yml)
* GitHub Actions
  * <https://github.com/hoijui/MeditationBench>
  * [Generated Report](https://hoijui.github.io/MeditationBench/osh-report.html)
  * [CI script](https://github.com/hoijui/MeditationBench/blob/master/.github/workflows/check.yml)

## Features

So far, It may only check/lint OSH projects,
while later it is supposed to also initialize them
with all sorts of standard files and tooling.

See [src/checks](src/checks) for the currently supported checks,
including at least:

* Check README existence
* Check LICENSE existence
* Check [okh.toml](https://github.com/OPEN-NEXT/OKH-LOSH/blob/master/OKH-LOSH.ttl)
  ([Open Know-How](https://openknowhow.org) OSH meta-data file) existence

## Requires

To compile:

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

Ask anything as an issue!

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

GNU Affero General Public License version 3
