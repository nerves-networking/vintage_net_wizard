defmodule VintageNetWizard.Backend.Default do
  @behaviour VintageNetWizard.Backend

  require Logger

  @impl true
  def init() do
    if configured?() do
      :stop
    else
      :ok = VintageNet.subscribe(["interface", "wlan0", "state"])
      :ok = VintageNet.subscribe(["interface", "wlan0", "wifi", "access_points"])
      :ok = switch_to_ap_mode()
      {:ok, %{access_points: %{}}}
    end
  end

  @impl true
  def scan() do
    VintageNet.scan("wlan0")
  end

  @impl true
  def access_points(%{access_points: access_points}), do: access_points

  @impl true
  def configured?() do
    config = VintageNet.get_configuration("wlan0")

    with {:ok, wifi} <- Map.fetch(config, :wifi),
         {:ok, _} <- Map.fetch(wifi, :ssid) do
      true
    else
      :error -> false
    end
  end

  @impl true
  def apply([cfg], _) do
    VintageNet.configure("wlan0", %{
      type: VintageNet.Technology.WiFi,
      wifi: %{
        ssid: cfg.ssid,
        psk: cfg.password,
        mode: :client,
        key_mgmt: cfg.key_mgmt
      },
      ipv4: %{method: :dhcp}
    })
  end

  @impl true
  def handle_info(
        {VintageNet, ["interface", "wlan0", "wifi", "access_points"], _, access_points, _},
        state
      ) do
    {:reply, {:access_points, access_points}, %{state | access_points: access_points}}
  end

  def handle_info({VintageNet, ["interface", "wlan0", "state"], _, :configured, _meta}, state) do
    :ok = scan()

    {:noreply, state}
  end

  def handle_info({VintageNet, ["interface", "wlan0", "state"], _, _, _meta}, state) do
    {:noreply, state}
  end

  defp switch_to_ap_mode() do
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
