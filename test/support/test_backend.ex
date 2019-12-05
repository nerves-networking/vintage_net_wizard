defmodule VintageNetWizard.Test.Backend do
  @behaviour VintageNetWizard.Backend

  @impl true
  def init() do
    {:ok, nil}
  end

  @impl true
  def access_points(_) do
    [
      %VintageNetWiFi.AccessPoint{
        band: :wifi_5_ghz,
        bssid: "8a:8a:20:88:7a:50",
        channel: 149,
        flags: [:wpa2_psk_ccmp, :ess],
        frequency: 5745,
        signal_dbm: -76,
        signal_percent: 57,
        ssid: "Testing all the things!"
      }
    ]
  end

  @impl true
  def apply(_configs, state), do: {:ok, state}

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  @impl true
  def device_info(), do: []

  @impl true
  def reset(), do: %{}

  @impl true
  def configuration_status(_state), do: :not_configured

  @impl true
  def stop_scan(state) do
    state
  end

  @impl true
  def start_scan(state) do
    state
  end

  @impl true
  def complete(_configs, state), do: {:ok, state}
end
