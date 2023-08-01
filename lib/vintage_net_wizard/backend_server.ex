defmodule VintageNetWizard.BackendServer do
  @moduledoc """
  Server for managing a VintageNet.Backend implementation
  """
  use GenServer
  require Logger

  alias VintageNetWiFi.AccessPoint
  alias VintageNetWizard.{APMode, Backend}

  defmodule State do
    @moduledoc false
    defstruct subscriber: nil,
              backend: nil,
              backend_state: nil,
              configurations: %{},
              device_info: [],
              ap_ifname: nil,
              ifname: nil,
              hw_check: %{},
              lock: false,
              door: %{},
              status_lock: %{},
              init_cam: false,
              stop_cam: false
  end

  @spec child_spec(any(), any(), keyword()) :: map()
  def child_spec(backend, ifname, opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [backend, ifname, opts]},
      restart: :transient
    }
  end

  @spec start_link(backend :: module(), VintageNet.ifname(), [Backend.opt()]) ::
          GenServer.on_start()
  def start_link(backend, ifname, opts \\ []) do
    GenServer.start_link(__MODULE__, [backend, ifname, opts], name: __MODULE__)
  end

  @doc """
  Subscribe to messages from the backend
  """
  @spec subscribe() :: :ok
  def subscribe() do
    GenServer.cast(__MODULE__, {:subscribe, self()})
  end

  @doc """
  Return information about the device for the web page's footer
  """
  @spec device_info() :: [{String.t(), String.t()}]
  def device_info() do
    GenServer.call(__MODULE__, :device_info)
  end

  @doc """
  Delete the configuration by `ssid`
  """
  @spec delete_configuration(String.t()) :: :ok
  def delete_configuration(ssid) do
    GenServer.call(__MODULE__, {:delete_configuration, ssid})
  end

  @doc """
  List out access points
  """
  @spec access_points() :: [AccessPoint.t()]
  def access_points() do
    GenServer.call(__MODULE__, :access_points)
  end

  @doc """
  Pass list of SSIDs (`priority_order`), sort the configurations
  to match that order.
  """
  @spec set_priority_order([String.t()]) :: :ok
  def set_priority_order(priority_order) do
    GenServer.call(__MODULE__, {:set_priority_order, priority_order})
  end

  @doc """
  Get the current state of the WiFi configuration
  """
  @spec configuration_state() :: map()
  def configuration_state() do
    GenServer.call(__MODULE__, :configuration_state)
  end

  @doc """
  Start scanning for WiFi access points
  """
  @spec start_scan() :: :ok
  def start_scan() do
    GenServer.call(__MODULE__, :start_scan)
  end

  @doc """
  Stop scanning for WiFi access points
  """
  @spec stop_scan() :: :ok
  def stop_scan() do
    GenServer.call(__MODULE__, :stop_scan)
  end

  @doc """
  Save a network configuration to the backend

  The network configuration is a map that can be included in the `:network`
  field of a `VintageNetWiFi` configuration.
  """
  @spec save(map()) :: :ok | {:error, any()}
  def save(config) do
    GenServer.call(__MODULE__, {:save, config})
  end

  @doc """
  Get a list of the current configurations
  """
  @spec configurations() :: [map()]
  def configurations() do
    GenServer.call(__MODULE__, :configurations)
  end

  @doc """
  Get the current configuration status
  """
  @spec configuration_status() :: any()
  def configuration_status() do
    GenServer.call(__MODULE__, :configuration_status)
  end

  @doc """
  Apply the configurations saved in the backend to
  the system.
  """
  @spec apply() :: :ok | {:error, :no_configurations}
  def apply() do
    GenServer.call(__MODULE__, :apply)
  end

  @doc """
  Reset the backend to an initial default state.
  """
  @spec reset() :: :ok
  def reset() do
    GenServer.call(__MODULE__, :reset)
  end

  @doc """
  """
  @spec complete() :: :ok
  def complete() do
    GenServer.call(__MODULE__, :complete)
  end

  def set_hw_check(hw_check) do
    GenServer.cast(__MODULE__, {:set_hw_check, hw_check})
  end

  def set_door(door) do
    GenServer.cast(__MODULE__, {:set_door, door})
  end

  def set_lock(lock) do
    GenServer.cast(__MODULE__, {:set_lock, lock})
  end

  def change_lock(value) do
    GenServer.cast(__MODULE__, {:change_lock, value})
  end

  def set_init_cam(value) do
    GenServer.cast(__MODULE__, {:set_init_cam, value})
  end

  def set_stop_cam(value) do
    GenServer.cast(__MODULE__, {:set_stop_cam, value})
  end

  def get_hwcheck() do
    GenServer.call(__MODULE__, :get_hwcheck)
  end

  def get_door() do
    GenServer.call(__MODULE__, :get_door)
  end

  def get_lock() do
    GenServer.call(__MODULE__, :get_lock)
  end

  def get_change_lock() do
    GenServer.call(__MODULE__, :get_change_lock)
  end

  def init_cam() do
    GenServer.call(__MODULE__, :init_cam)
  end

  def stop_cam() do
    GenServer.call(__MODULE__, :stop_cam)
  end

  @impl GenServer
  def init([backend, ifname, opts]) do
    device_info = Keyword.get(opts, :device_info, [])

    configurations =
      opts
      |> Keyword.get(:configurations, [])
      |> Enum.into(%{}, fn config -> {config.ssid, config} end)

    ap_ifname = Keyword.fetch!(opts, :ap_ifname)

    {:ok,
     %State{
       configurations: configurations,
       backend: backend,
       # Scanning is done by ifname
       backend_state: backend.init(ifname, ap_ifname),
       device_info: device_info,
       ifname: ifname,
       ap_ifname: ap_ifname
     }}
  end

  @impl GenServer
  def handle_call(
        :get_hwcheck,
        _from,
          state
      ) do

    {:reply, state.hw_check, state}
  end

  @impl GenServer
  def handle_call(
        :init_cam,
        _from,
          state
      ) do

        {:reply, state.init_cam, state}
  end

  @impl GenServer
  def handle_call(
        :stop_cam,
        _from,
          state
      ) do

        {:reply, state.stop_cam, state}
  end

  @impl GenServer
  def handle_call(
        :get_lock,
        _from,
          state
      ) do

    {:reply, state.status_lock, state}
  end

  @impl GenServer
  def handle_call(
        :get_change_lock,
        _from,
          state
      ) do

    {:reply, state.lock, state}
  end

  @impl GenServer
  def handle_call(
        :get_door,
        _from,
          state
      ) do

    {:reply, state.door, state}
  end

  @impl GenServer
  def handle_call(
        :get_open_lock,
        _from,
          state
      ) do

    {:reply, state.open_lock, state}
  end

  @impl GenServer
  def handle_call(
        :get_close_lock,
        _from,
          state
      ) do

    {:reply, state.close_lock, state}
  end

  @impl GenServer
  def handle_call(
        :access_points,
        _from,
        %State{backend: backend, backend_state: backend_state} = state
      ) do
    access_points = backend.access_points(backend_state)
    {:reply, access_points, state}
  end

  def handle_call(
        :start_scan,
        _from,
        %State{backend: backend, backend_state: backend_state} = state
      ) do
    new_backend_state = backend.start_scan(backend_state)

    {:reply, :ok, %{state | backend_state: new_backend_state}}
  end

  def handle_call(
        :stop_scan,
        _from,
        %State{backend: backend, backend_state: backend_state} = state
      ) do
    new_backend_state = backend.stop_scan(backend_state)

    {:reply, :ok, %{state | backend_state: new_backend_state}}
  end

  def handle_call(
        {:set_priority_order, priority_order},
        _from,
        %State{configurations: configurations} = state
      ) do
    indexed_priority_order = Enum.with_index(priority_order)

    new_configurations =
      Enum.map(configurations, fn {ssid, config} ->
        priority = get_priority_for_ssid(indexed_priority_order, ssid)

        {ssid, Map.put(config, :priority, priority)}
      end)
      |> Enum.into(%{})

    {:reply, :ok, %{state | configurations: new_configurations}}
  end

  def handle_call(
        :configuration_status,
        _from,
        %State{backend: backend, backend_state: backend_state} = state
      ) do
    status = backend.configuration_status(backend_state)
    {:reply, status, state}
  end

  def handle_call(
        {:save, config},
        _from,
        %{configurations: configs, backend: backend, backend_state: backend_state} = state
      ) do
    access_points = backend.access_points(backend_state)
    not_hidden? = Enum.any?(access_points, &(&1.ssid == config.ssid))
    # Scan if ssid is hidden
    full_config = if not_hidden?, do: config, else: Map.put(config, :scan_ssid, 1)

    {:reply, :ok, %{state | configurations: Map.put(configs, config.ssid, full_config)}}
  end

  def handle_call(
        :device_info,
        _from,
        state
      ) do
    {:reply, state.device_info, state}
  end

  def handle_call(:configurations, _from, %State{configurations: configs} = state) do
    cleaned_configs =
      configs
      |> build_config_list()
      |> Enum.map(&clean_config/1)

    {:reply, cleaned_configs, state}
  end

  def handle_call(
        :apply,
        _from,
        %State{configurations: wifi_configs} = state
      )
      when wifi_configs == %{} do
    {:reply, {:error, :no_configurations}, state}
  end

  def handle_call(
        :apply,
        _from,
        %State{
          backend: backend,
          configurations: wifi_configs,
          backend_state: backend_state,
          ifname: ifname
        } = state
      ) do
    old_connection = old_connection(ifname)

    case backend.apply(build_config_list(wifi_configs), backend_state) do
      {:ok, new_backend_state} ->
        updated_state = %{state | backend_state: new_backend_state}
        # If applying the new configuration does not change the connection,
        # send a message to that effect so the Wizard does not timeout
        # waiting for one from VintageNet
        maybe_send_connection_info(updated_state, old_connection)
        {:reply, :ok, updated_state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(:reset, _from, %State{backend: backend, backend_state: backend_state} = state) do
    new_state = backend.reset(backend_state)
    {:reply, :ok, %{state | configurations: %{}, backend_state: new_state}}
  end

  def handle_call({:delete_configuration, ssid}, _from, %State{configurations: configs} = state) do
    {:reply, :ok, %{state | configurations: Map.delete(configs, ssid)}}
  end

  def handle_call(:configuration_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(
        :complete,
        _from,
        %State{backend_state: %{data: %{configuration_status: :good}}} = state
      ) do
    # As the configuration status is good, we are already completed setup and the configurations
    # have been blanked in `handle_info/3` - calling complete on the backend will disconnect us and
    # write over the saved configuration. Do nothing.
    :ok = deconfigure_ap_ifname(state)
    {:reply, :ok, state}
  end

  def handle_call(
        :complete,
        _from,
        %State{backend: backend, configurations: wifi_configs, backend_state: backend_state} =
          state
      ) do
    {:ok, new_backend_state} =
      backend.complete(build_config_list(wifi_configs), backend_state)

    :ok = deconfigure_ap_ifname(state)
    {:reply, :ok, %{state | backend_state: new_backend_state}}
  end

  @impl GenServer
  def handle_cast({:set_hw_check, hw_check}, state) do
    {:noreply, %{state | hw_check: hw_check}}
  end

  @impl GenServer
  def handle_cast({:set_door, door}, state) do
    {:noreply, %{state | door: door}}
  end

  @impl GenServer
  def handle_cast({:set_lock, lock}, state) do
    {:noreply, %{state | status_lock: lock}}
  end

  @impl GenServer
  def handle_cast({:change_lock, value}, state) do
    {:noreply, %{state | lock: value}}
  end

  @impl GenServer
  def handle_cast({:set_stop_cam, value}, state) do

    {:noreply, %{state | stop_cam: value}}
  end

  @impl GenServer
  def handle_cast({:set_init_cam, value}, state) do

    {:noreply, %{state | init_cam: value}}
  end

  @impl GenServer
  def handle_cast({:subscribe, subscriber}, state) do
    {:noreply, %{state | subscriber: subscriber}}
  end

  @impl GenServer
  def handle_info(
        info,
        %State{
          subscriber: subscriber,
          backend: backend,
          backend_state: backend_state
        } = state
      ) do
    case backend.handle_info(info, backend_state) do
      {:reply, message, new_backend_state} ->
        maybe_send(subscriber, {VintageNetWizard, message})
        {:noreply, %{state | backend_state: new_backend_state}}

      {:noreply, %{state: :idle, data: %{configuration_status: :good}} = new_backend_state} ->
        # idle state with good configuration means we've completed setup
        # and wizard has been shut down. So let's clear configurations
        # so aren't hanging around in memory

        {:noreply, %{state | configurations: %{}, backend_state: new_backend_state}}

      {:noreply, new_backend_state} ->
        {:noreply, %{state | backend_state: new_backend_state}}
    end
  end

  defp build_config_list(configs) do
    configs
    |> Enum.into([], &elem(&1, 1))
    |> Enum.sort(fn config1, config2 ->
      config1_priority = get_in(config1, [:priority])
      config2_priority = get_in(config2, [:priority])

      case {config1_priority, config2_priority} do
        {nil, nil} -> false
        {nil, _} -> false
        {_, nil} -> true
        {p1, p2} -> p1 <= p2
      end
    end)
  end

  defp maybe_send(nil, _message), do: :ok
  defp maybe_send(pid, message), do: send(pid, message)

  defp get_priority_for_ssid(priority_order_list, ssid) do
    priority_index =
      Enum.find(priority_order_list, fn
        {^ssid, _} -> true
        _ -> false
      end)
      |> elem(1)

    priority_index + 1
  end

  defp clean_config(config) do
    Map.drop(config, [:psk, :password])
  end

  defp old_connection(ifname) do
    [{_, connection}] = VintageNet.get_by_prefix(["interface", ifname, "connection"])

    connection
  end

  defp maybe_send_connection_info(%State{ifname: ifname}, old_connection) do
    [{_, new_connection}] = VintageNet.get_by_prefix(["interface", ifname, "connection"])

    if old_connection == new_connection do
      info =
        {VintageNet, ["interface", ifname, "connection"], old_connection, new_connection, %{}}

      send(self(), info)
    else
      :ok
    end
  end

  defp deconfigure_ap_ifname(state) do
    if state.ifname != state.ap_ifname do
      VintageNet.deconfigure(state.ap_ifname)
    else
      if state.ifname do
        networks = build_config_list(state.configurations)
        APMode.exit_ap_mode(state.ifname, networks)
      else
        :ok
      end
    end
  end
end
