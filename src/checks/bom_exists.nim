# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import re
import options
import strformat
import ../check
import ../check_config
import ../state
import ../util/fs

const IDS = @["bomex", "be", "bom_exists"]
const ID = IDS[0]
let RS_EDITABLE= "^.*(csv|tsv|odp|xls|xslx|md|markdown)$" # TODO Should/Could we add more here? .. or rahter use the osh-file-types repo right away?
let R_EDITABLE= re(RS_EDITABLE) # The Open-o-Meter requires the BoM (and other things) to be present in an editable format; thus we should check that at some point
let RS_BOM = "(?i)^(BoM|BillOfMaterials|Bill_of_Materials|Bill-of-Materials).*$"
let R_BOM = re(RS_BOM)

type BomExistsCheck = ref object of Check
type BomExistsCheckGenerator = ref object of CheckGenerator

method name(this: BomExistsCheck): string =
  return "BoM exists"

method description*(this: BomExistsCheck): string =
  return fmt"""Checks that a Bill of Materials (BoM) file exists in the projects root dir, \
using the regex `{RS_BOM}`."""

method why*(this: BomExistsCheck): string =
  return """A BoM file contains a list of all required parts,
be that raw parts or ready-made ones.
That not only clearly marks the repository as a hardware project,
but also allows for quick human (and partly machine/software)
based analysis for what is needed to build the piece of hardware,
and to have at east a first rought idea about the costs,
and potential candidates that could become a supply problem.

... plus probably many other uses."""

method sourcePath*(this: BomExistsCheck): string =
  return fs.srcFileName()

method requirements*(this: BomExistsCheck): CheckReqs =
  return {
    CheckReq.FilesListL1,
  }

method getSignificanceFactors*(this: BomExistsCheck): CheckSignificance =
  return CheckSignificance(
    weight: 0.2,
    openness: 0.5,
    hardware: 1.0,
    quality: 0.3,
    machineReadability: 0.6,
    )

method run(this: BomExistsCheck, state: var State): CheckResult =
  # TODO Also use osh-dir-std tag "bom" to find it
  return (if filterPathsMatching(state.listFilesL1(), R_BOM).len > 0:
    newCheckResult(CheckResultKind.Perfect)
  else:
    newCheckResult(
      CheckResultKind.Bad,
      CheckIssueSeverity.Middle,
      some("""No BoM file found in the root directory.
Please consider adding e.g. a 'BoM.csv'.""")
    )
  )

method id*(this: BomExistsCheckGenerator): seq[string] =
  return IDS

method generate*(this: BomExistsCheckGenerator, config: CheckConfig = CheckConfig(id: this.id()[0], json: none[string]())): Check =
  this.ensureNonConfig(config)
  BomExistsCheck()

proc createGenerator*(): CheckGenerator =
  BomExistsCheckGenerator()
