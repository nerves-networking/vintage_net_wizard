defmodule VintageNetWizard.Test.Backend do
  @behaviour VintageNetWizard.Backend

  @impl VintageNetWizard.Backend
  def init(_ifname, _ap_ifname) do
    {:ok, nil}
  end

  @impl VintageNetWizard.Backend
  def access_points(_) do
    [
      %VintageNetWiFi.AccessPoint{
        band: :wifi_5_ghz,
        bssid: "8a:8a:20:88:7a:50",
        channel: 149,
        flags: [:wpa2, :psk, :ccmp, :ess],
        frequency: 5745,
        signal_dbm: -76,
        signal_percent: 57,
        ssid: "Testing all the things!"
      }
    ]
  end

  @impl VintageNetWizard.Backend
  def apply(_configs, state), do: {:ok, state}

  @impl VintageNetWizard.Backend
  def handle_info(_, state), do: {:noreply, state}

  @impl VintageNetWizard.Backend
  def reset(_args), do: %{}

  @impl VintageNetWizard.Backend
  def configuration_status(_state), do: :not_configured

  @impl VintageNetWizard.Backend
  def stop_scan(state) do
    state
  end

  @impl VintageNetWizard.Backend
  def start_scan(state) do
    state
  end

  @impl VintageNetWizard.Backend
  def complete(_configs, state), do: {:ok, state}
end
