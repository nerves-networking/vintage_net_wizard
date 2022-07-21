defmodule VintageNetWizard.Backend.Mock do
  @moduledoc """
  A default backend for host machines.

  This is useful for testing and local JavaScript development.
  """
  @behaviour VintageNetWizard.Backend

  alias VintageNetWiFi.AccessPoint

  require Logger

  @impl VintageNetWizard.Backend
  def init(_ifname, _ap_ifname) do
    Logger.info("Go to http://localhost:#{Application.get_env(:vintage_net_wizard, :port)}/")

    initial_state()
  end

  @impl VintageNetWizard.Backend
  def apply(_configs, state) do
    Process.send_after(self(), {__MODULE__, :stop_server}, 2_000)
    {:ok, state}
  end

  @impl VintageNetWizard.Backend
  def access_points(%{access_points: access_points}), do: access_points

  @impl VintageNetWizard.Backend
  def reset(_state), do: initial_state()

  @impl VintageNetWizard.Backend
  def complete(_configs, state), do: {:ok, state}

  @impl VintageNetWizard.Backend
  def handle_info({__MODULE__, :stop_server}, %{configuration_status: :good} = state) do
    _ = Process.send_after(self(), {__MODULE__, :apply_config}, 1_000)
    {:noreply, state}
  end

  def handle_info({__MODULE__, :stop_server}, state) do
    _ = Process.send_after(self(), {__MODULE__, :apply_config}, 2_000)
    {:noreply, state}
  end

  def handle_info({__MODULE__, :apply_config}, %{configuration_status: :good} = state) do
    {:noreply, state}
  end

  def handle_info({__MODULE__, :apply_config}, state) do
    {:noreply, %{state | configuration_status: :good}}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl VintageNetWizard.Backend
  def configuration_status(%{configuration_status: configuration_status}) do
    configuration_status
  end

  @impl VintageNetWizard.Backend
  def start_scan(state), do: state

  @impl VintageNetWizard.Backend
  def stop_scan(state), do: state

  defp initial_state() do
    access_points = [
      %AccessPoint{
        band: :wifi_5_ghz,
        bssid: "8a:8a:20:88:7a:50",
        channel: 149,
        flags: [:wpa2, :psk, :ccmp, :ess],
        frequency: 5745,
        signal_dbm: -76,
        signal_percent: 57,
        ssid: "Let It Crash-5GHz"
      },
      %AccessPoint{
        band: :wifi_2_4_ghz,
        bssid: "04:18:d6:47:1a:6a",
        channel: 6,
        flags: [:wpa2, :psk, :ccmp, :ess],
        frequency: 2462,
        signal_dbm: -89,
        signal_percent: 10,
        ssid: "Let It Crash-2GHz"
      },
      %AccessPoint{
        band: :wifi_2_4_ghz,
        bssid: "16:18:d6:47:1a:6a",
        channel: 6,
        flags: [:wpa2, :psk, :ccmp, :ess],
        frequency: 2462,
        signal_dbm: -90,
        signal_percent: 9,
        ssid: "CIA"
      },
      %AccessPoint{
        band: :wifi_2_4_ghz,
        bssid: "06:18:d6:47:1a:6a",
        channel: 6,
        flags: [:wpa2, :psk, :ccmp, :ess],
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
        bssid: "26:9e:db:0d:4f:23",
        channel: 6,
        flags: [:ess],
        frequency: 2462,
        signal_dbm: -20,
        signal_percent: 99,
        ssid: "Open WiFi"
      },
      %AccessPoint{
        band: :wifi_2_4_ghz,
        bssid: "26:9e:db:0d:4f:22",
        channel: 6,
        flags: [:wpa2, :eap, :ccmp, :ess],
        frequency: 2462,
        signal_dbm: -61,
        signal_percent: 80,
        ssid: "Wayne Enterprises"
      }
    ]

    %{access_points: access_points, configuration_status: :not_configured}
  end
end
