# Changelog

## v0.3.0

This release has modifications to support `vintage_net v0.9.1`. It contains no
functional changes.

## v0.2.4

This release is mostly documentation updates and code refactoring without any
core usage changes. It also updates dependencies, including `vintage_net_wifi`
to allow `vintage_net v0.8` if desired.

## v0.2.3

* Enhancements
  * Support disabling captive portal

## v0.2.2

* New Features
  * Support captive portal detection (thanks to @jmerriweather!)

* Bug Fixes
  * Fix adding a network not shown in the AP list

* Enhancements
  * Include the configuration status on the webpage
  * Allow submitting the configuration without verifying it. (Useful when you want to configure networks that aren't nearby or confident the config is good)
  * Better message page when configuration verification is running
  * Better message when configuration fails
  * Show WPA Enterprise option when adding a network not in the AP list

## v0.2.1

Some fun doc updates and type fixes.

* Enhancements
  * Don't require internet connectivity to consider a WiFi config as successful

## v0.2.0

This release contains updates to use `vintage_net` `v0.7.0`. This includes
depending on `vintage_net_wifi` and renaming keys used for the configuration.
Projects pulling this update should review the [`vintage_net` release
notes](https://github.com/nerves-networking/vintage_net/releases/tag/v0.7.0).

* New features
  * Support customization of the SSID. In your `config.exs`, add the following:

```
config :vintage_net_wizard,
      ssid: "MY_SSID"
```

## v0.1.7

* New features
  * Added `VintageNetWizard.stop_wizard/0`
  * Added a callback so that users could be notified when configuration
    completes

## v0.1.6

* New features
  * Added support for configuring WPA-EAP PEAP

* Bug fixes
  * Fixed issue where the UI would ask for a password for some access points
    that didn't have security.

## v0.1.5

* Bug fixes
  * Fixed error when not using SSL
  * Don't create invalid SSIDs if the hostname isn't set or is something really
    long

## v0.1.4

* Improvements
  * Better handle using Erlang `:ssl` options when starting the wizard

## v0.1.3

* Improvements
  * Add dnsd to reduce connection time and allow users to connect via DNS names
    (mDNS was also possible, but not as likely to work everywhere)

## v0.1.2

* Improvements
  * Actively update WiFi networks in the UI
  * Validate WPA passphrases

* Bug fixes
  * AP mode configuration is no longer persisted. If a device is rebooted when
    running the wizard, it will start with the previous configuration.
  * Fix SSL certificate paths

## v0.1.1

* Improvements
  * Developer must now explicitly start the wizard server to place device into
    AP mode. This prevents the device from starting up automatically in
    and unwanted state.

## v0.1.0

Initial release
