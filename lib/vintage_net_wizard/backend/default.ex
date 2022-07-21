defmodule VintageNetWizard.Backend.Default do
  @moduledoc """
  The default backend implementation for target devices

  This backend will be used if no other backend is configured in the
  application configuration.
  """
  @behaviour VintageNetWizard.Backend

  alias VintageNetWizard.{APMode, WiFiConfiguration}

  @impl VintageNetWizard.Backend
  def init(ifname, ap_ifname) do
    # ["interface", ifname, "connection"] info never received when uap0 and wlan0
    VintageNet.subscribe(["interface", ifname, "connection"])
    VintageNet.subscribe(["interface", ifname, "wifi", "access_points"])

    initial_state(ifname, ap_ifname)
  end

  @impl VintageNetWizard.Backend
  def access_points(%{data: %{access_points: ap}}), do: ap

  @impl VintageNetWizard.Backend
  def apply(_, %{state: :idle}), do: {:error, :invalid_state}
  def apply(_, %{state: :applying} = state), do: {:ok, state}

  def apply(wifi_configurations, state) do
    :ok = apply_configurations(wifi_configurations, state)

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
    # When completing, we don't make assertions on the success
    # of the connection and only care that it was applied
    :ok = apply_configurations(wifi_configurations, state)

    {:ok, %{state | state: :complete}}
  end

  @impl VintageNetWizard.Backend
  def configuration_status(%{data: %{configuration_status: configuration_status}}) do
    configuration_status
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
  def reset(state), do: initial_state(state.ifname, state.ap_ifname)

  @impl VintageNetWizard.Backend
  def handle_info(:configuration_timeout, %{data: data, ap_ifname: ap_ifname} = state) do
    # If we get this timeout, something went wrong trying to apply
    # the configuration, i.e. bad password or faulty network
    :ok = APMode.into_ap_mode(ap_ifname)

    data =
      data
      |> Map.put(:configuration_status, :bad)
      |> Map.delete(:apply_configuration_timer)

    {:noreply, %{state | state: :configuring, data: data}}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], :disconnected, :lan, _},
        %{state: :configuring, ifname: ifname} = state
      ) do
    {:noreply, state}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], _, connectivity, _},
        %{state: :applying, data: %{configuration_status: :good} = data, ifname: ifname} = state
      )
      when connectivity in [:lan, :internet] do
    # Everything connected, so cancel our timeout
    _ = Process.cancel_timer(data.apply_configuration_timer)

    {:noreply, %{state | state: :idle, data: Map.delete(data, :apply_configuration_timer)}}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], _, connectivity, _},
        %{state: :applying, data: data, ifname: ifname, ap_ifname: ap_ifname} = state
      )
      when connectivity in [:lan, :internet] do
    # Everything connected, so cancel our timeout
    # NOTE - When entering the wrong password, status reported by VIntageNet alternates between :disconnected and :lan
    #        When :lan is seen, success is assumed though it might be immediately followed by a :disconnected
    _ = Process.cancel_timer(data.apply_configuration_timer)

    # sometimes writing configs and reloading and re-initializing
    # wifi runs into a race condition. So, we wait a little
    # before trying to re-initialize the interface.
    Process.sleep(4_000)
    :ok = APMode.into_ap_mode(ap_ifname)

    data =
      data
      |> Map.put(:configuration_status, :good)
      |> Map.delete(:apply_configuration_timer)

    {:noreply, %{state | state: :configuring, data: data}}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "wifi", "access_points"], _, access_points, _},
        %{data: data, ifname: ifname} = state
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

  def handle_info(_info, state) do
    {:noreply, state}
  end

  defp apply_configurations(wifi_configurations, state) do
    VintageNet.configure(state.ifname, %{
      type: VintageNetWiFi,
      vintage_net_wifi: %{
        networks: wifi_configurations
      },
      ipv4: %{method: :dhcp}
    })
  end

  defp start_scan_timer(), do: Process.send_after(self(), :run_scan, 20_000)

  defp scan(%{state: :configuring, ifname: ifname}), do: VintageNet.scan(ifname)
  defp scan(_), do: {:error, :invalid_state}

  defp initial_state(ifname, ap_ifname) do
    %{
      state: :configuring,
      scan_ref: nil,
      data: %{access_points: %{}, configuration_status: :not_configured},
      ifname: ifname,
      ap_ifname: ap_ifname
    }
  end
end
