# SPDX-FileCopyrightText: 2019 Matt Ludwigs
# SPDX-FileCopyrightText: 2020 Jean-Francois Cloutier
#
# SPDX-License-Identifier: Apache-2.0
#
import Config

config :vintage_net_wizard,
  backend: VintageNetWizard.Backend.Mock,
  port: 4001,
  captive_portal: false
