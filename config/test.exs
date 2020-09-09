use Mix.Config

config :vintage_net_wizard,
  backend: VintageNetWizard.Test.Backend,
  port: 4001,
  captive_portal: false

config :vintage_net,
  path: "#{File.cwd!()}/test/fixtures/root/bin"
