defmodule VintageNetWizard.Backend.Mock do
  @moduledoc """
  A default backend for host machines.

  This is useful for testing and local
  JavaScript development
  """
  @behaviour VintageNetWizard.Backend

  alias VintageNetWizard.Web.Endpoint
  alias VintageNet.WiFi.AccessPoint

  @impl true
  def init() do
    # It either starts, already running, or will error. So
    # don't need to care about the return
    _ = Endpoint.start_server()

    initial_state()
  end

  @impl true
  def apply(_configs, state) do
    Process.send_after(self(), {__MODULE__, :stop_server}, 2_000)
    {:ok, state}
  end

  @impl true
  def access_points(%{access_points: access_points}), do: access_points

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
  def reset(), do: initial_state()

  @impl true
  def handle_info({__MODULE__, :stop_server}, %{configuration_status: :good} = state) do
    _ = Process.send_after(self(), {__MODULE__, :apply_config}, 1_000)
    {:noreply, state}
  end

  def handle_info({__MODULE__, :stop_server}, state) do
    _ = Process.send_after(self(), {__MODULE__, :apply_config}, 2_000)
    :ok = Endpoint.stop_server()
    {:noreply, state}
  end

  def handle_info({__MODULE__, :apply_config}, %{configuration_status: :good} = state) do
    {:noreply, state}
  end

  def handle_info({__MODULE__, :apply_config}, state) do
    {:ok, _} = Endpoint.start_server()
    {:noreply, %{state | configuration_status: :good}}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def configuration_status(%{configuration_status: configuration_status}) do
    configuration_status
  end

  @impl true
  def start_scan(state), do: state

  @impl true
  def stop_scan(state), do: state

  defp initial_state() do
    access_points = [
      %AccessPoint{
        band: :wifi_5_ghz,
        bssid: "8a:8a:20:88:7a:50",
        channel: 149,
        flags: [:wpa2_psk_ccmp, :ess],
        frequency: 5745,
        signal_dbm: -76,
        signal_percent: 57,
        ssid: "Let It Crash-5GHz"
      },
      %AccessPoint{
        band: :wifi_2_4_ghz,
        bssid: "04:18:d6:47:1a:6a",
        channel: 6,
        flags: [:wpa2_psk_ccmp, :ess],
        frequency: 2462,
        signal_dbm: -89,
        signal_percent: 10,
        ssid: "Let It Crash-2GHz"
      },
      %AccessPoint{
        band: :wifi_2_4_ghz,
        bssid: "16:18:d6:47:1a:6a",
        channel: 6,
        flags: [:wpa2_psk_ccmp, :ess],
        frequency: 2462,
        signal_dbm: -90,
        signal_percent: 9,
        ssid: "CIA"
      },
      %AccessPoint{
        band: :wifi_2_4_ghz,
        bssid: "06:18:d6:47:1a:6a",
        channel: 6,
        flags: [:wpa2_psk_ccmp, :ess],
        frequency: 2462,
        signal_dbm: -90,
        signal_percent: 9,
        ssid: "Red███ed W███"
      },
      %AccessPoint{
        band: :wifi_2_4_ghz,
        bssid: "26:9e:db:0d:4f:21",
        channel: 6,
        flags: [],
        frequency: 2462,
        signal_dbm: -61,
        signal_percent: 60,
        ssid: "Airport WiFi"
      },
      %AccessPoint{
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

    %{access_points: access_points, configuration_status: :not_configured}
  end
end
