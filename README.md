<!--
SPDX-FileCopyrightText: 2021 - 2025 Robin Vobruba <hoijui.quaero@gmail.com>

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
    https://raw.githubusercontent.com/osegermany/tiny-files/master/res/media/img/badge-fchh.svg)](
    https://www.fabcity.hamburg/)
[![In cooperation with Open Source Ecology Germany](
    https://raw.githubusercontent.com/osegermany/tiny-files/master/res/media/img/badge-oseg.svg)](
    https://www.ose-germany.de/die-bewegung/)

A command line tool for Open Source Hardware (OSH)
technical project linting (quality assessment).

You give this tool a directory containing the documentation and design documents
about a technology;
which could be a chair, a tractor, a radio, a dress, shoes ...
most anything human made. \
The tool analyzes that directory,
and then tells you how well organized it thinks the project is.
This analysis is made up of tests,
each of which checks for one [best](https://www.merriam-webster.com/dictionary/best%20practice)-[practice](https://en.wikipedia.org/wiki/Best_practice).

There are three ways to use this tool:

1. [through CI](#example-projects) (aka build-bot) -
    We recommend to use this if you host your project in a (git)-repository
2. [through docker/podman](#docker) -
    Use this preferably when you want to run it on your local machine.
3. natively -
    This (probably) requires you to compile the tool yourself,
    and also all the required CLI tools
    (see the [Dockerfile](Dockerfile) for reference).
    This is **not recommended**,
    because it is much more work,
    and it is hard to keep all the required tools up to date.

    Iff you want to use this anyway,
    you might want to try downloading one of the
    [prebuilt binaries](https://hoijui.github.io/osh-tool/)
    (non-static, development=build, Linux & Windows, 64bit).
    They are not statically linked though,
    so you might run into issues with different versions of dynamic libraries
    (like `libc` or `ssl`).

## Examples

### Badges

To be used at the top of a README:

- [![Meditation Bench - OSH - Openness](
    https://hoijui.github.io/MeditationBench/osh-badge-openness.svg)](
    https://hoijui.github.io/MeditationBench/osh-report.html)
- [![Agro Circle - OSH - Openness](
    https://osegermany.github.io/AgroCircle/osh-badge-openness.svg)](
    https://osegermany.github.io/AgroCircle/osh-report.html)
- [![OHLOOM - OSH - compliance](
    https://osegermany.gitlab.io/ohloom/osh-badge-compliance.svg)](
    <https://osegermany.gitlab.io/ohloom/osh-report.html>)
- [![OHLOOM - OSH - machineReadability](
    https://osegermany.gitlab.io/ohloom/osh-badge-machineReadability.svg)](
    <https://osegermany.gitlab.io/ohloom/osh-report.html>)
- [![OHLOOM - OSH - quality](
    https://osegermany.gitlab.io/ohloom/osh-badge-quality.svg)](
    <https://osegermany.gitlab.io/ohloom/osh-report.html>)
- [![OHLOOM - OSH - openness](
    https://osegermany.gitlab.io/ohloom/osh-badge-openness.svg)](
    <https://osegermany.gitlab.io/ohloom/osh-report.html>)

### Example Projects

Two sample hardware projects,
using this tool to check their own Open Source'ness
with the help of this tool,
executed in [CI](https://en.wikipedia.org/wiki/Continuous_integration).
The generated report is linked to form the README in a badge
(image after the title) with the text "OSH Report".

| CI Type | Sample Project Hosting | Generated Report | CI Script |
| --- | ------ | --- | --- |
| GitHub Actions | <https://github.com/hoijui/MeditationBench> | [Generated Report](https://hoijui.github.io/MeditationBench/osh-report.html) | [.github/workflows/check.yml](https://github.com/hoijui/MeditationBench/blob/master/.github/workflows/check.yml) |
| GitHub Actions 2 | <https://github.com/osegermany/AgroCircle> | [Generated Report](https://osegermany.github.io/AgroCircle/osh-report.html) | [.github/workflows/check.yml](https://github.com/osegermany/AgroCircle/blob/master/.github/workflows/check.yml) |
| GitLab CI | <https://gitlab.com/OSEGermany/ohloom> | [Generated Report](https://osegermany.gitlab.io/ohloom/osh-report.html) | [.gitlab-ci.yml](https://gitlab.com/OSEGermany/ohloom/-/blob/master/.gitlab-ci.yml) |

## Docker

> NOTE
> Instead of `docker` you may also use the Open Source alternative `podman`
> in all the code snippets in this section.

The easiest way to use this tool -
if you are hosting your project on a git repo that is -
is through CI (aka build-bot).
You can find examples for how to do this
in the [Example Projects](#example-projects) section. \
The second easiest
because it depends on/uses a lto of other CLI tools,
many of which you would have to compile manually!

and the easiest way to use this tool _with docker_,
is to use the pre-built image hosted in the registry:

You can download with this command:

```shell
docker pull hoijui/osh-tool:latest
```

And execute it in this way
(NOTE: This gives the docker image read and write access to your current directory):

```shell
docker run \
    --volume "$PWD:/data" \
    hoijui/osh-tool:latest \
    report_gen \
        --force \
        --download-badges
```

You should then have the report files in the directory `public/`.

In the above command,
`report_gen` is a wrapper script around `osh`.
Think of it as what you generally want to use,
while `osh` is a rather bare-metal tool,
which requires post-processing the generated output for human consumption.

Alternatively,
you can also build the docker image on your local machine like so
(note that here we use `:local` instead of `:latest`):

```shell
docker build --tag hoijui/osh-tool:local .
```

After building the image like this,
it is also in your local registry,
so you can use it with the `docker run` command from above;
you just need to replace `:latest` with `:local`.
Building the image yourself is useful
if you develop the tool further yourself.

## Features

What it does in the rough:

- Check for OSH project design compliance
- Create human-readable reports
- Create machine-readable reports

See [src/checks](src/checks) for the currently supported checks,
including at least:

- Check README existence
- Check LICENSE existence
- Check BoM existence
- Very basic CAD file checks
- Very basic Electronics CAD file checks
- Markdown issues
- Markdown & HTML link checking
- Check [okh.toml] ([Open Know-How] OSH meta-data file) existence
- Check `okh.toml` validity
- Check detailed licensing information according to REUSE
- Check if a Version Control System ([VCS]) (like [git]) is used
- Check if the [VCS] repo is publicly hosted
- Check if it adheres to the
  [Open Source Hardware Directory Standard][osh-dir-std]

## Requires

To compile:

- Nim and Nimble, version 0.10.0 or higher

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

Simply run `osh --help` to see usage information.

For more details how to use it locally and on CI/build-bot,
see the [**user documentation**](doc/user/README.md).

## Community

Ask anything as an [issue](https://github.com/hoijui/osh-tool/issues/)!

## Similar Projects

We are not just standing on the shoulders of giants,
but also toe on toe with them!

These are two of our big sister projects.
They are similar both in spirit
and in the way they are used on the command-line.
They also work well in combination with this tool.

- [git] - Master of history
- [REUSE] -
  Handles all things regarding licensing of a project and its sources

## License

GNU Affero General Public License version 3

## Funding

This project was funded by:

- the European Union's [Horizon 2020](
      https://research-and-innovation.ec.europa.eu/funding/funding-opportunities/funding-programmes-and-open-calls/horizon-2020_en)
  research and innovation program,
  under grant agreement no. 869984,
  in the context of the [OPEN!NEXT Project](https://opennext.eu/),
  from June 2021 (project start)
  until November 2021.

  ![Logo of the European Commission](
      https://commission.europa.eu/themes/contrib/oe_theme/dist/ec/images/logo/positive/logo-ec--en.svg)

- the European Regional Development Fund (ERDF)
  in the context of the [INTERFACER Project](https://www.interfacerproject.eu/),
  from December 2021
  until March 2023.

  ![Logo of the EU ERDF program](
      https://cloud.fabcity.hamburg/s/TopenKEHkWJ8j5P/download/logo-eu-erdf.png)

[okh.toml]: https://github.com/iop-alliance/OpenKnowHow/blob/master/res/sample_data/okh-TEMPLATE.toml
[Open Know-How]: https://www.internetofproduction.org/openknowhow
[VCS]: https://www.geeksforgeeks.org/version-control-systems/
[git]: https://git-scm.com/
[REUSE]: https://git.fsfe.org/reuse/tool
[osh-dir-std]: https://gitlab.com/OSEGermany/osh-dir-std/
