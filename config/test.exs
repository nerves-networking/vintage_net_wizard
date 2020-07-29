use Mix.Config

config :vintage_net_wizard,
  backend: VintageNetWizard.Test.Backend

config :vintage_net,
  path: "#{File.cwd!()}/test/fixtures/root/bin"
