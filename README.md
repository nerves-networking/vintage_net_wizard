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

VintageNetWizard has the option to configuration which `backend` to use. Backends
are used to switch out functionally of the networking logic. The default backend
is `VintageNetWizard.Backend.Default` which uses `VintageNet` to handle scanning
and network configuration.

If you want to do local development primarily testing the JavaScript frontend you
can use `VintageNetWizard.Backend.Mock` to do so.

```elixir
config :vintage_net_wizard,
  backend: VintageNetWizard.Backend.Mock
```
