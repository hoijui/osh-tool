<!--
SPDX-FileCopyrightText: 2021-2023 Robin Vobruba <hoijui.quaero@gmail.com>

SPDX-License-Identifier: CC0-1.0
-->

# `osh`-tool

[![License: AGPL-3.0-or-later](
    https://img.shields.io/badge/License-AGPL%20v3+-blue.svg)](
    https://www.gnu.org/licenses/agpl-3.0)
[![REUSE status](
    https://api.reuse.software/badge/github.com/hoijui/osh-tool)](
    https://api.reuse.software/info/github.com/hoijui/osh-tool)

[![In cooperation with FabCity Hamburg](
    https://custom-icon-badges.demolab.com/badge/-FCHH-dddddd.svg?logo=fc_logo)](
    https://fabcity.hamburg)
[![In cooperation with Open Source Ecology Germany](
    https://custom-icon-badges.demolab.com/badge/-OSEG-555555.svg?logo=oseg_logo)](
    https://opensourceecology.de)

A command line tool for Open Source Hardware (OSH)
technical project linting (quality assessment).

[Download binaries](https://hoijui.github.io/osh-tool/)
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
# Fetch the whole source code
git submodule update --init --recursive
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

## Funding

This project was funded by:

* the European Union's [Horizon 2020](
      https://research-and-innovation.ec.europa.eu/funding/funding-opportunities/funding-programmes-and-open-calls/horizon-2020_en)
  research and innovation program,
  under grant agreement no. 869984,
  in the context of the [OPEN!NEXT Project](https://opennext.eu/),
  from June 2021 (project start)
  until November 2021.

  ![Logo of the European Commission](
      https://www.polemermediterranee.com/var/website/storage/images/media/images/european-commission-logo.png/422174-1-fre-FR/european-commission-logo.PNG_reference.png)

* the European Regional Development Fund (ERDF)
  in the context of the [INTERFACER Project](https://www.interfacerproject.eu/),
  from December 2021
  until March 2023.

  ![Logo of the EU ERDF program](
      https://cloud.fabcity.hamburg/s/TopenKEHkWJ8j5P/download/logo-eu-erdf.png)
