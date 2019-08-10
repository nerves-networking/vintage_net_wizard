defmodule VintageNetWizard.Backend.Default do
  @moduledoc """
  A default backend for target devices
  """
  @behaviour VintageNetWizard.Backend

  @impl true
  def init() do
    if configured?() do
      :stop
    else
      :ok = VintageNet.subscribe(["interface", "wlan0", "state"])
      :ok = VintageNet.subscribe(["interface", "wlan0", "wifi", "access_points"])
      :ok = VintageNetWizard.run_wizard()
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
  def device_info() do
    kv =
      Nerves.Runtime.KV.get_all_active()
      |> kv_to_map

    [
      {"Firmware", kv["nerves_fw_product"]},
      {"Firmware version", kv["nerves_fw_version"]},
      {"Firmware UUID", kv["nerves_fw_uuid"]},
      {"Device serial number", serial_number()}
    ]
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
    :ok =
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

    VintageNetWizard.stop_server()
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
end