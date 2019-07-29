# VintageNet Configuration Wizard

[![CircleCI](https://circleci.com/gh/nerves-networking/vintage_net_wizard.svg?style=svg)](https://circleci.com/gh/nerves-networking/vintage_net_wizard)
[![Hex version](https://img.shields.io/hexpm/v/vintage_net_wizard.svg "Hex version")](https://hex.pm/packages/vintage_net_wizard)

Experimental Configuration utility for
[VintageNet](https://github.com/nerves-networking/vintage_net).

This library will create a WiFi access point and captive portal. Upon
connection, the user will be presented with a simple HTML form for
selecting and configuring available WiFi networks.

## Screenshots

![see it in action](assets/screenshot00.gif)

## Configuration

### Port

VintageNetWizard can be configured to listen on a particular port. By default it
will listen on port `80`.

Doing local development the server will start on port `4001`

```elixir
config :vintage_net_wizard,
  port: 4001
```

### Networks

VintageNetWizard has the option to configuration which `network` to use. Networks
are used to switch out functionally of the networking logic. The default network
is `VintageNetWizard.Network.Default` which uses `VintageNet` to handle scanning
and network configuration.

If you want to do local development primarily testing the JavaScript frontend you
can use `VintageNetWizard.Network.Mock` to do so.

```elixir
config :vintage_net_wizard,
  network: VintageNetWizard.Network.Mock
```
