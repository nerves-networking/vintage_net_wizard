defmodule VintageNetWizard.APMode do
  @moduledoc """
  This module contains utilities for configuration VintageNet in AP Mode
  """

  @default_hostname "vintage_net_wizard"

  @doc """
  Change the WiFi module into access point mode
  """
  @spec into_ap_mode(VintageNet.ifname()) :: :ok | {:error, any()}
  def into_ap_mode(ifname) do
    hostname = get_hostname()
    our_name = Application.get_env(:vintage_net_wizard, :dns_name, "wifi.config")

    config = ap_mode_configuration(hostname, our_name)
    VintageNet.configure(ifname, config, persist: false)
  end

  @doc """
  Change the WIFi module to exit AP mode and apply the wifi configs.
  """
  @spec exit_ap_mode(VintageNet.ifname(), [map()]) :: :ok | {:error, any()}
  def exit_ap_mode(ifname, networks) do
    configuration = VintageNet.get_configuration(ifname)

    no_ap_mode =
      configuration
      |> Map.put(:ipv4, %{method: :dhcp})
      |> Map.put(:vintage_net_wifi, %{networks: networks})
      |> Map.delete(:dhcpd)
      |> Map.delete(:dnsd)

    VintageNet.configure(ifname, no_ap_mode)
  end

  @doc """
  Return a configuration to put VintageNet into AP mode
  """
  @spec ap_mode_configuration(String.t(), String.t()) :: map()
  def ap_mode_configuration(hostname, our_name) do
    ssid = sanitize_hostname_for_ssid(hostname)
    our_ip_address = {172, 16, 61, 0}

    %{
      type: VintageNetWiFi,
      vintage_net_wifi: %{
        networks: [
          %{
            mode: :ap,
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
        start: {172, 16, 61, 20},
        end: {172, 16, 61, 254},
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
        records: dnsd_records(our_name, our_ip_address)
      }
    }
  end

  @doc """
  Return SSID that is used for AP Mode
  """
  @spec ssid() :: String.t()
  def ssid() do
    get_hostname()
    |> sanitize_hostname_for_ssid()
  end

  defp dnsd_records(our_name, our_ip_address) do
    if Application.get_env(:vintage_net_wizard, :captive_portal, true) do
      [{our_name, our_ip_address}, {"*", our_ip_address}]
    else
      [{our_name, our_ip_address}]
    end
  end

  defp get_hostname() do
    {:ok, hostname} = :inet.gethostname()
    hostname_string = to_string(hostname)
    Application.get_env(:vintage_net_wizard, :ssid, hostname_string)
  end

  defp sanitize_hostname_for_ssid(<<ssid::32-bytes, _rest::binary>>) do
    ssid
  end

  defp sanitize_hostname_for_ssid("") do
    @default_hostname
  end

  defp sanitize_hostname_for_ssid(good_hostname) do
    good_hostname
  end
end
