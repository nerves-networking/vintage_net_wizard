defmodule VintageNetWizard.Backend.Default do
  @behaviour VintageNetWizard.Backend

  alias VintageNetWizard.WiFiConfiguration

  @impl VintageNetWizard.Backend
  def init() do
    if configured?() do
      %{state: :idle, data: %{access_points: %{}, configuration_status: :good}}
    else
      :ok = VintageNet.subscribe(["interface", "wlan0", "connection"])
      :ok = VintageNet.subscribe(["interface", "wlan0", "wifi", "access_points"])
      :ok = VintageNetWizard.run_wizard()

      %{
        state: :configuring,
        data: %{access_points: %{}, configuration_status: :not_configured}
      }
    end
  end

  @impl VintageNetWizard.Backend
  def access_points(%{data: %{access_points: ap}}), do: ap

  @impl VintageNetWizard.Backend
  def apply(_, %{state: :idle}), do: {:error, :invalid_state}
  def apply(_, %{state: :applying} = state), do: {:ok, state}

  def apply(wifi_configurations, state) do
    vintage_net_config =
      Enum.map(wifi_configurations, &WiFiConfiguration.to_vintage_net_configuration/1)

    :ok =
      VintageNet.configure("wlan0", %{
        type: VintageNet.Technology.WiFi,
        wifi: %{
          networks: vintage_net_config
        }
      })

    {:ok, %{state | state: :applying}}
  end

  @impl VintageNetWizard.Backend
  def configuration_status(%{data: %{configuration_status: configuration_status}}) do
    configuration_status
  end

  @impl VintageNetWizard.Backend
  def device_info() do
    kv =
      Nerves.Runtime.KV.get_all_active()
      |> kv_to_map

    mac_addr = VintageNet.get(["interface", "wlan0", "mac_address"])

    [
      {"Wi-Fi Address", mac_addr},
      {"Serial number", serial_number()},
      {"Firmware", kv["nerves_fw_product"]},
      {"Firmware version", kv["nerves_fw_version"]},
      {"Firmware UUID", kv["nerves_fw_uuid"]}
    ]
  end

  @impl VintageNetWizard.Backend
  def handle_info(
        {VintageNet, ["interface", "wlan0", "connection"], :disconnected, :lan, _},
        %{state: :configuring, data: %{configuration_status: :not_configured}} = state
      ) do
    _ = scan(state)
    {:noreply, state}
  end

  def handle_info(
        {VintageNet, ["interface", "wlan0", "connection"], :disconnected, :lan, _},
        %{state: :configuring} = state
      ) do
    {:noreply, state}
  end

  def handle_info(
        {VintageNet, ["interface", "wlan0", "connection"], _, :internet, _},
        %{state: :applying, data: %{configuration_status: :good}} = state
      ) do
    {:noreply, %{state | state: :idle}}
  end

  def handle_info(
        {VintageNet, ["interface", "wlan0", "connection"], _, :internet, _},
        %{state: :applying, data: data} = state
      ) do
    # sometimes writing configs and reloading and re-initializing
    # wifi runs into a race condition. So, we wait a little
    # before trying to re-initialize the interface.
    Process.sleep(4_000)
    :ok = VintageNetWizard.into_ap_mode()
    data = Map.put(data, :configuration_status, :good)
    {:noreply, %{state | state: :configuring, data: data}}
  end

  def handle_info(
        {VintageNet, ["interface", "wlan0", "wifi", "access_points"], _, access_points, _},
        %{data: data} = state
      ) do
    access_points = Enum.map(access_points, &Map.from_struct/1)
    data = Map.put(data, :access_points, access_points)
    {:reply, {:access_points, access_points}, %{state | data: data}}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp scan(%{state: :configuring}), do: :ok

  defp configured?() do
    config = VintageNet.get_configuration("wlan0")
    get_in(config, [:wifi, :ssid]) != nil and get_in(config, [:wifi, :mode]) != :host
  end

  defp kv_to_map(key_values) do
    for kv <- key_values, into: %{}, do: kv
  end

  defp serial_number() do
    with boardid_path when not is_nil(boardid_path) <- System.find_executable("boardid"),
         {id, 0} <- System.cmd(boardid_path, []) do
      String.trim(id)
    else
      _other -> "Unknown"
    end
  end
end
