import Config

config :vintage_net,
  resolvconf: "/dev/null",
  persistence: VintageNet.Persistence.Null

config :vintage_net, :basic_auth, username: "admin", password: "adminadmin"

import_config "#{Mix.env()}.exs"
