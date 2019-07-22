use Mix.Config

# Configure :nerves_runtime and :vintage_net so that they will run on the host.
# This is needed to run and debug locally
config :nerves_runtime,
  target: "host"

config :vintage_net,
  resolvconf: "/dev/null",
  persistence_dir: "./persistence",
  bin_ip: "false"

import_config "#{Mix.env()}.exs"
