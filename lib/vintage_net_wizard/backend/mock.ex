defmodule VintageNetWizard.Backend.Mock do
  @moduledoc """
  A default backend for host machines.

  This is useful for testing and local
  JavaScript development
  """
  @behaviour VintageNetWizard.Backend

  @impl true
  def init() do
    access_points = [
      %{
        band: :wifi_5_ghz,
        bssid: "8a:8a:20:88:7a:50",
        channel: 149,
        flags: [:wpa2_psk_ccmp, :ess],
        frequency: 5745,
        signal_dbm: -76,
        signal_percent: 57,
        ssid: "Let It Crash-5GHz"
      },
      %{
        band: :wifi_2_4_ghz,
        bssid: "04:18:d6:47:1a:6a",
        channel: 6,
        flags: [:wpa2_psk_ccmp, :ess],
        frequency: 2462,
        signal_dbm: -89,
        signal_percent: 10,
        ssid: "Let It Crash-2GHz"
      },
      %{
        band: :wifi_2_4_ghz,
        bssid: "16:18:d6:47:1a:6a",
        channel: 6,
        flags: [:wpa2_psk_ccmp, :ess],
        frequency: 2462,
        signal_dbm: -90,
        signal_percent: 9,
        ssid: "CIA"
      },
      %{
        band: :wifi_2_4_ghz,
        bssid: "06:18:d6:47:1a:6a",
        channel: 6,
        flags: [:wpa2_psk_ccmp, :ess],
        frequency: 2462,
        signal_dbm: -90,
        signal_percent: 9,
        ssid: "Red███ed W███"
      },
      %{
        band: :wifi_2_4_ghz,
        bssid: "26:9e:db:0d:4f:21",
        channel: 6,
        flags: [],
        frequency: 2462,
        signal_dbm: -61,
        signal_percent: 60,
        ssid: "Airport WiFi"
      },
      %{
        band: :wifi_2_4_ghz,
        bssid: "26:9e:db:0d:4f:22",
        channel: 6,
        flags: [:wpa2_eap_ccmp, :ess],
        frequency: 2462,
        signal_dbm: -61,
        signal_percent: 80,
        ssid: "Wayne Enterprises"
      }
    ]

    {:ok, _} = VintageNetWizard.start_server()

    {:ok, access_points}
  end

  @impl true
  def scan() do
    :ok
  end

  @impl true
  def configured?(), do: false

  @impl true
  def apply(_cfgs, _state) do
    :ok = VintageNetWizard.stop_server()
  end

  @impl true
  def access_points(state), do: state

  @impl true
  def device_info() do
    [
      {"Wi-Fi Address", "11:22:33:44:55:66"},
      {"Serial number", "12345678"},
      {"Firmware", "vintage_net_wizard"},
      {"Firmware version", "0.1.0"},
      {"Firmware UUID", "30abd1f4-0e87-5ec8-d1c8-425114a21eec"}
    ]
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end
end
