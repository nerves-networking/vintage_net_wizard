defmodule VintageNetWizard.Backend.Host do
  @behaviour VintageNetWizard.Backend

  @impl true
  def init(), do: {:ok, %{}}

  @impl true
  def scan() do
    access_points = %{
      "04:18:d6:47:1a:6a" => %{
        band: :wifi_2_4_ghz,
        bssid: "04:18:d6:47:1a:6a",
        channel: 6,
        flags: [:wpa2_psk_ccmp, :ess],
        frequency: 2462,
        signal_dbm: -89,
        signal_percent: 10,
        ssid: "WirelessPCU"
      },
      "16:18:d6:47:1a:6a" => %{
        band: :wifi_2_4_ghz,
        bssid: "16:18:d6:47:1a:6a",
        channel: 6,
        flags: [:wpa2_psk_ccmp, :ess],
        frequency: 2462,
        signal_dbm: -90,
        signal_percent: 9,
        ssid: ""
      },
      "06:18:d6:47:1a:6a" => %{
        band: :wifi_2_4_ghz,
        bssid: "06:18:d6:47:1a:6a",
        channel: 6,
        flags: [:wpa2_psk_ccmp, :ess],
        frequency: 2462,
        signal_dbm: -90,
        signal_percent: 9,
        ssid: "WirelessPCU - Guest"
      },
      "26:9e:db:0d:4f:21" => %{
        band: :wifi_2_4_ghz,
        bssid: "26:9e:db:0d:4f:21",
        channel: 6,
        flags: [],
        frequency: 2462,
        signal_dbm: -61,
        signal_percent: 60,
        ssid: "SETUP"
      },
      "26:9e:db:0d:4f:22" => %{
        band: :wifi_2_4_ghz,
        bssid: "26:9e:db:0d:4f:22",
        channel: 6,
        flags: [:wpa2_eap_ccmp, :ess],
        frequency: 2462,
        signal_dbm: -61,
        signal_percent: 80,
        ssid: "enterprise"
      }
    }

    send(
      self(),
      {VintageNet, ["interface", "wlan0", "wifi", "access_points"], %{}, access_points, %{}}
    )

    :ok
  end

  @impl true
  def access_points(state), do: state

  @impl true
  def handle_info(
        {VintageNet, ["interface", "wlan0", "wifi", "access_points"], _, access_points, _},
        _
      ) do
    {:reply, {:access_points, access_points}, access_points}
  end
end
