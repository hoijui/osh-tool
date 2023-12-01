# This file is part of osh-tool.
# <https://github.com/hoijui/osh-tool>
#
# SPDX-FileCopyrightText: 2023 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import options

type
  CheckConfig* = ref object
    id*: string
    json*: Option[string]

template newCheckConfig*(idArg: string): CheckConfig =
  CheckConfig(
      id: idArg,
      json: none[string](),
    )
