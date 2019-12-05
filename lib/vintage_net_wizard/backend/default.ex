defmodule VintageNetWizard.Backend.Default do
  @behaviour VintageNetWizard.Backend

  alias VintageNetWizard.{APMode, WiFiConfiguration}

  @impl VintageNetWizard.Backend
  def init() do
    :ok = VintageNet.subscribe(["interface", "wlan0", "connection"])
    :ok = VintageNet.subscribe(["interface", "wlan0", "wifi", "access_points"])

    initial_state()
  end

  @impl VintageNetWizard.Backend
  def access_points(%{data: %{access_points: ap}}), do: ap

  @impl VintageNetWizard.Backend
  def apply(_, %{state: :idle}), do: {:error, :invalid_state}
  def apply(_, %{state: :applying} = state), do: {:ok, state}

  def apply(wifi_configurations, state) do
    :ok = apply_configurations(wifi_configurations)

    timeout =
      wifi_configurations
      |> Enum.max_by(&WiFiConfiguration.timeout/1)
      |> WiFiConfiguration.timeout()

    timer = Process.send_after(self(), :configuration_timeout, timeout)

    data =
      state.data
      |> Map.put(:apply_configuration_timer, timer)

    {:ok, %{state | state: :applying, data: data}}
  end

  @impl VintageNetWizard.Backend
  def complete(wifi_configurations, state) do
    # When completeing, we don't make assertions on the success
    # of the connection and only care that it was applied
    :ok = apply_configurations(wifi_configurations)

    {:ok, %{state | state: :complete}}
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
  def start_scan(state) do
    _ = scan(state)
    scan_ref = start_scan_timer()
    %{state | scan_ref: scan_ref}
  end

  @impl VintageNetWizard.Backend
  def stop_scan(%{scan_ref: nil} = state), do: state

  def stop_scan(%{scan_ref: ref} = state) do
    _ = Process.cancel_timer(ref)
    %{state | scan_ref: nil}
  end

  @impl VintageNetWizard.Backend
  def reset(), do: initial_state()

  @impl VintageNetWizard.Backend
  def handle_info(:configuration_timeout, %{data: data} = state) do
    # If we get this timeout, something went wrong trying to apply
    # the configuration, i.e. bad password or faulty network
    :ok = APMode.into_ap_mode()

    data =
      data
      |> Map.put(:configuration_status, :bad)
      |> Map.delete(:apply_configuration_timer)

    {:noreply, %{state | state: :configuring, data: data}}
  end

  def handle_info(
        {VintageNet, ["interface", "wlan0", "connection"], :disconnected, :lan, _},
        %{state: :configuring} = state
      ) do
    {:noreply, state}
  end

  def handle_info(
        {VintageNet, ["interface", "wlan0", "connection"], _, :internet, _},
        %{state: :applying, data: %{configuration_status: :good} = data} = state
      ) do
    # Everything connected, so cancel our timeout
    _ = Process.cancel_timer(data.apply_configuration_timer)

    {:noreply, %{state | state: :idle, data: Map.delete(data, :apply_configuration_timer)}}
  end

  def handle_info(
        {VintageNet, ["interface", "wlan0", "connection"], _, :internet, _},
        %{state: :applying, data: data} = state
      ) do
    # Everything connected, so cancel our timeout
    _ = Process.cancel_timer(data.apply_configuration_timer)

    # sometimes writing configs and reloading and re-initializing
    # wifi runs into a race condition. So, we wait a little
    # before trying to re-initialize the interface.
    Process.sleep(4_000)
    :ok = APMode.into_ap_mode()

    data =
      data
      |> Map.put(:configuration_status, :good)
      |> Map.delete(:apply_configuration_timer)

    {:noreply, %{state | state: :configuring, data: data}}
  end

  def handle_info(
        {VintageNet, ["interface", "wlan0", "wifi", "access_points"], _, access_points, _},
        %{data: data} = state
      ) do
    data = Map.put(data, :access_points, access_points)
    {:reply, {:access_points, access_points}, %{state | data: data}}
  end

  def handle_info(:run_scan, state) do
    case scan(state) do
      :ok ->
        {:noreply, %{state | scan_ref: start_scan_timer()}}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info(_, state), do: {:noreply, state}

  defp apply_configurations(wifi_configurations) do
    vintage_net_config =
      Enum.map(wifi_configurations, &WiFiConfiguration.to_vintage_net_configuration/1)

    VintageNet.configure("wlan0", %{
      type: VintageNetWiFi,
      vintage_net_wifi: %{
        networks: vintage_net_config
      },
      ipv4: %{method: :dhcp}
    })
  end

  defp start_scan_timer(), do: Process.send_after(self(), :run_scan, 20_000)

  defp scan(%{state: :configuring}), do: VintageNet.scan("wlan0")
  defp scan(_), do: {:error, :invalid_state}

  defp initial_state() do
    %{
      state: :configuring,
      scan_ref: nil,
      data: %{access_points: %{}, configuration_status: :not_configured}
    }
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
