# Changelog

## v0.4.6 - 2021-08-20

* Changed
  * Support `:phoenix_html` `~> 2.13 or ~> 3.0`. The `v0.4.5` release removed
    support for `~> 2.13`, but it turns out that not everyone has updated and
    `vintage_net_wizard` works with both.

## v0.4.5 - 2021-08-20

* Added
  * Support for WPA3/WPA2 transitional networks. The connection still uses WPA2
    even if WPA3 is supported by the WiFi module.

## v0.4.4

* Fixes
  * Fixed an issue that prevented the wizard from timing out due to inactivity. See PR #217.

## v0.4.3

* Enhancements
  * Improve mobile experience. Thanks to Ole Michaelis for this update.

## v0.4.2

* Bug Fixes
  * Fix a runtime error on the apply page.
  * Fix "undefined" as the wizard name during application of configuration in the
    dynamic content.

## v0.4.1

* Enhancements
  * Can add some custom branding to the UI such as page title, title color, and
    button color.
  * Will display pre-existing configurations on the configuration page.
  * Update example app to use `nerves_pack` and updated nerves systems.

* Bug Fixes
  * Fix a bug where starting `VintageNetWizard` would delete any pre-existing
    configurations.

## v0.4.0

This release has several changes to UI text to reduce jargon and make some
elements configurable. In particular, the title and footer are now configurable.
Given the breadth of styling and UI updates that have been proposed, it is
likely for the configuration mechanism to change again.

* New features
  * The title for the UI was changed from "VintageNetWizard" to "WiFi Setup Wizard".
  * The footer is now empty by default. See `WizardExample.Button` for how to
    replicate the previous information in your project.
  * An idle timer will now exit the wizard on inactivity. The default inactivity
    timeout is 10 minutes. This prevents accidental button presses, etc. from
    entering the wizard and remaining there forever.

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
