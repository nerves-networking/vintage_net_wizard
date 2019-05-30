# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.

config :shoehorn,
  init: [:nerves_runtime, :vintage_net],
  app: Mix.Project.config()[:app]

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger, :console]

config :vintage_net,
  regulatory_domain: "US",
  config: [
    # {"eth0",
    #  %{
    #    type: VintageNet.Technology.Ethernet,
    #    ipv4: %{
    #      method: :dhcp
    #    }
    #  }},
    {"wlan0",
     %{
       type: VintageNet.Technology.WiFi,
       wifi: %{
         mode: :host,
         ssid: "test ssid",
         key_mgmt: :none,
         scan_ssid: 1,
         ap_scan: 1,
         bgscan: :simple
       },
       ipv4: %{
         method: :static,
         address: "192.168.24.1",
         netmask: "255.255.255.0"
       },
       dhcpd: %{
         start: "192.168.24.2",
         end: "192.168.24.10"
       }
     }}
  ]

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.target()}.exs"
