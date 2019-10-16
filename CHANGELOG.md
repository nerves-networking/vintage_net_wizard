# Changelog

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
