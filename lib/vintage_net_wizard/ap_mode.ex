defmodule VintageNetWizard.APMode do
  @moduledoc """
  This module contains utilities for configuration VintageNet in AP Mode
  """

  @doc """
  Change the WiFi module into access point mode
  """
  @spec into_ap_mode() :: :ok | {:error, any()}
  def into_ap_mode() do
    hostname = get_hostname()
    our_name = Application.get_env(:vintage_net_wizard, :dns_name, "wifi.config")

    config = ap_mode_configuration(hostname, our_name)
    VintageNet.configure("wlan0", config, persist: false)
  end

  @doc """
  Return a configuration to put VintageNet into AP mode
  """
  @spec ap_mode_configuration(String.t(), String.t()) :: map()
  def ap_mode_configuration(hostname, our_name) do
    ssid = hostname
    our_ip_address = {192, 168, 0, 1}

    %{
      type: VintageNet.Technology.WiFi,
      wifi: %{
        networks: [
          %{
            mode: :host,
            ssid: ssid,
            key_mgmt: :none
          }
        ]
      },
      ipv4: %{
        method: :static,
        address: our_ip_address,
        prefix_length: 24
      },
      dhcpd: %{
        # These are defaults and are reproduced here as documentation
        start: {192, 168, 0, 20},
        end: {192, 168, 0, 254},
        max_leases: 235,
        options: %{
          dns: [our_ip_address],
          subnet: {255, 255, 255, 0},
          router: [our_ip_address],
          domain: our_name,
          search: [our_name]
        }
      },
      dnsd: %{
        records: [
          {our_name, our_ip_address}
        ]
      }
    }
  end

  defp get_hostname() do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end
end
