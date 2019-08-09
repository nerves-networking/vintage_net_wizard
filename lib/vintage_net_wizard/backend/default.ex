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
      :ok = VintageNet.subscribe(["interface", "wlan0", "connection"])
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

  def handle_info({VintageNet, ["interface", "wlan0", "connection"], _, :lan, _}, state) do
    :ok = scan()
    {:noreply, state}
  end
end
