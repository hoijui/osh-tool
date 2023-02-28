---
title: osh - Output of `osh --help`
---

```
A linter (static analysis tool) for repositories
which contain technical documentation
of Open Source Hardware (OSH) projects.

Please send feedback here:
<https://github.com/hoijui/osh-tool/issues>

This tool supports three main commands:

- **check** (beta, please try; only reads, does not write/create/change anything):
  This checks a given project dir/repo,
  reporting about what is and is not present and in order
  of the things we want to see in a project [1].
- **init** (***NOT IMPLEMENTED***, do not use!):
  This initializes a project directory template from scratch,
  containing as much as possible
  of the structure and meta-data we want to see [1].
- **update** (***NOT IMPLEMENTED***, do not use!):
  This auto-generates as much as possible
  of the structure and meta-data we want to see [1]
  in the given, already existing project directory.

## 1. What we want to see in a project

This is very opinionated. It is our choice of set of rules, and their specific settings.
We came to this, through our years of experience in Open Source Software and Hardware.
As the later is pretty new and still quite "wild" and unorganized,
there is little solid understanding of it all,
and these rules are thus partly just guessing.
We would be happy to get feedback through issues or even pull-requests at:
<https://github.com/hoijui/osh-tool/>

The easiest way to understand what this tool does,
is to just run it in a git repo with some content:

    osh check

This just reads files and writes to stdout.
It neither deletes, changes nor creates files.

Usage:
  osh [-C <path>] [--quiet] init    [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics] [-f] [--force] [--readme] [--license]
  osh [-C <path>] [--quiet] update  [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics]
  osh [-C <path>] [--quiet] [check] [--offline] [-e] [--electronics] [--no-electronics] [-m] [--mechanics] [--no-mechanics] [-f] [--force] [-l] [--list-checks] [--report-md-list=<path> ...] [--report-md-table=<path> ...] [--report-json=<path> ...] [--report-csv=<path> ...]
  osh (-h | --help)
  osh (-V | --version) [--quiet]

Options:
  -h --help          Show this screen and exit.
  -V --version       Show this tools version and exit.
  -q --quiet         Prevents all logging output, showing only the version number in combination with --version.
  -C <path>          Run as if osh was started in <path> instead of the current working directory.
  --offline          Do not access the network/internet.
  -f --force         Force overwriting of any generated files, if they are explicitly requested (e.g. with --readme or --license).
  -l --list-checks   Creates a list of all available checks with descriptions in Markdown format and exits.
  --readme           Generate a template README, to be manually adjusted.
  --license          Choose a license from a list, generating a LICENSE file that will be identified by GitLab and GitHub.
  --report-md-list=<path>  File-path a report in Markdown (list) format gets written to; May be used multiple times; if no --report-* argument is given, a report gets written to stdout & stderr.
  --report-md-table=<path> File-path a report in Markdown (table) format gets written to; May be used multiple times; if no --report-* argument is given, a report gets written to stdout & stderr.
  --report-csv=<path>      File-path a report in CSV format gets written to; May be used multiple times; if no --report-* argument is given, a report gets written to stdout & stderr.
  --report-json=<path>     File-path a report in JSON format gets written to; May be used multiple times; if no --report-* argument is given, a report gets written to stdout & stderr.
  -e --electronics   Indicate that the project contains electronics (KiCad)
  --no-electronics   Indicate that the project does not contain electronics (KiCad)
  -m --mechanics     Indicate that the project contains mechanical parts (FreeCAD)
  -no-mechanics      Indicate that the project does not contain mechanical parts (FreeCAD)

Examples:
  osh
  osh check
  osh -C ./myFolder check
  osh check --force --report-md-list report.md
  osh check --force --report-md-table report.md
  osh check --force --report-json report.json
  osh check --force --report-csv report.csv
  osh --list-checks
```
