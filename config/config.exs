import Config

config :vintage_net,
  resolvconf: "/dev/null",
  persistence: VintageNet.Persistence.Null

import_config "#{Mix.env()}.exs"
