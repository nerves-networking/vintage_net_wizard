# SPDX-FileCopyrightText: 2019 Matt Ludwigs
# SPDX-FileCopyrightText: 2020 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
import Config

config :vintage_net_wizard,
  backend: VintageNetWizard.Test.Backend,
  port: 4001,
  captive_portal: false

config :vintage_net,
  path: "#{File.cwd!()}/test/fixtures/root/bin"
