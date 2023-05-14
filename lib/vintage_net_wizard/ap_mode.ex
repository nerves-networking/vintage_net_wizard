defmodule VintageNetWizard.APMode do
  @moduledoc """
  This module contains utilities for configuration VintageNet in AP Mode
  """

  @default_hostname "vintage_net_wizard"
  @default_dns_name "wifi.config"
  @default_subnet {192, 168, 0, 0}

  @doc """
  Change the WiFi module into access point mode
  """
  @spec into_ap_mode(VintageNet.ifname()) :: :ok | {:error, any()}
  def into_ap_mode(ifname) do
    hostname = get_hostname()
    our_name = Application.get_env(:vintage_net_wizard, :dns_name, @default_dns_name)

    subnet =
      Application.get_env(:vintage_net_wizard, :subnet, @default_subnet)
      |> VintageNet.IP.ip_to_tuple!()

    config = ap_mode_configuration(hostname, our_name, subnet)
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

  defp create_ip_24(subnet, host) when host > 0 and host < 255 do
    {a, b, c, _} = subnet
    {a, b, c, host}
  end

  @doc """
  Return a configuration to put VintageNet into AP mode

  * `hostname` - the device's hostname which will be modified to be the AP's SSID
  * `our_name` - the name for clients to use when connecting to the wizard if
                 not using the IP address.
  * `class_c_subnet` - A class C subnet to use for all of the IP addresses on
                 this network.
  """
  @spec ap_mode_configuration(String.t(), String.t(), :inet.ip4_address()) :: map()
  def ap_mode_configuration(hostname, our_name, class_c_subnet) do
    ssid = sanitize_hostname_for_ssid(hostname)

    subnet_mask = VintageNet.IP.prefix_length_to_subnet_mask(:inet, 24)
    our_ip_address = create_ip_24(class_c_subnet, 1)

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
        start: create_ip_24(class_c_subnet, 20),
        end: create_ip_24(class_c_subnet, 254),
        max_leases: 235,
        options: %{
          dns: [our_ip_address],
          subnet: subnet_mask,
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
