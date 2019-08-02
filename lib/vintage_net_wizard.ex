defmodule VintageNetWizard do
  @moduledoc """
  Documentation for VintageNetWizard.
  """

  @doc """
  Change the WiFi module into access point mode
  """
  def into_ap_mode() do
    config = %{
      type: VintageNet.Technology.WiFi,
      wifi: %{
        mode: :host,
        ssid: "VintageNet Wizard",
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
    }

    VintageNet.configure("wlan0", config)
  end
end
