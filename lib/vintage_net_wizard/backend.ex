defmodule VintageNetWizard.Backend do
  @moduledoc """
  Backends define the boundaries of getting access points,
  handling incoming messages, and scanning the network
  """
  use GenServer

  alias VintageNetWizard.WiFiConfiguration
  alias VintageNet.WiFi.AccessPoint

  @doc """
  Do any initialization work like subscribing to messages
  """
  @callback init() :: {:ok, state :: any()}

  @doc """
  Scan the network
  """
  @callback scan() :: :ok

  @doc """
  Get all the access points that the backend knowns about
  """
  @callback access_points(state :: any()) :: [AccessPoint.t()]

  @doc """
  Check if the WiFi network is configured
  """
  @callback configured?() :: boolean()

  @doc """
  Apply the WiFi configurations
  """
  @callback apply([WiFiConfiguration.t()], state :: any()) :: :ok

  @doc """
  Handle any message the is received by another process

  If you want the socket to send data to the client
  return `{:reply, message, state}`, otherwise return
  `{:noreply, state}`
  """
  @callback handle_info(any(), state :: any()) ::
              {:reply, any(), state :: any()} | {:noreply, state :: any()}

  @doc """
  Return information about the device for populating the web UI footer
  """
  @callback device_info() :: [{String.t(), String.t()}]

  defmodule State do
    @moduledoc false
    defstruct subscriber: nil, backend: nil, backend_state: nil, configurations: []
  end

  @spec start_link(backend :: module()) :: GenServer.on_start()
  def start_link(backend) do
    GenServer.start_link(__MODULE__, backend, name: __MODULE__)
  end

  @doc """
  Subscribe to messages from the backend
  """
  @spec subscribe() :: :ok
  def subscribe() do
    GenServer.cast(__MODULE__, {:subscribe, self()})
  end

  @doc """
  Scan the network for access points
  """
  @spec scan() :: :ok
  def scan() do
    GenServer.cast(__MODULE__, :scan)
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
    GenServer.cast(__MODULE__, {:delete_configuration, ssid})
  end

  @doc """
  List out access points found from the scan
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
  Save a `WiFiConfiguration` to the backend
  """
  @spec save(WiFiConfiguration.t()) :: :ok | {:error, any()}
  def save(config) do
    GenServer.call(__MODULE__, {:save, config})
  end

  @doc """
  Get a list of the current configurations
  """
  @spec configurations() :: [WiFiConfiguration.t()]
  def configurations() do
    GenServer.call(__MODULE__, :configurations)
  end

  @doc """
  Ask the backend if the WiFi is configured
  """
  @spec configured?() :: boolean()
  def configured?() do
    GenServer.call(__MODULE__, :configured?)
  end

  @doc """
  Apply the configurations saved in the backend to
  the system.
  """
  @spec apply() :: :ok
  def apply() do
    GenServer.cast(__MODULE__, :apply)
  end

  @impl true
  def init(backend) do
    case apply(backend, :init, []) do
      {:ok, backend_state} ->
        {:ok, %State{configurations: %{}, backend: backend, backend_state: backend_state}}

      :stop ->
        {:ok, %State{backend: backend}}
    end
  end

  @impl true
  def handle_call(
        :access_points,
        _from,
        %State{backend: backend, backend_state: backend_state} = state
      ) do
    access_points = apply(backend, :access_points, [backend_state])
    {:reply, access_points, state}
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

        {ssid, %{config | priority: priority}}
      end)
      |> Enum.into(%{})

    {:reply, :ok, %{state | configurations: new_configurations}}
  end

  def handle_call({:save, config}, _from, %{configurations: cfgs} = state) do
    {:reply, :ok, %{state | configurations: Map.put(cfgs, config.ssid, config)}}
  end

  def handle_call(:device_info, _from, %State{backend: backend} = state) do
    {:reply, apply(backend, :device_info, []), state}
  end

  def handle_call(:configurations, _from, %State{configurations: cfgs} = state) do
    {:reply, build_config_list(cfgs), state}
  end

  def handle_call(:configured?, _from, %State{backend: backend} = state) do
    {:reply, apply(backend, :configured?, []), state}
  end

  @impl true
  def handle_cast({:subscribe, subscriber}, state) do
    {:noreply, %{state | subscriber: subscriber}}
  end

  def handle_cast(
        :apply,
        %State{backend: backend, configurations: wifi_configs, backend_state: backend_state} =
          state
      ) do
    :ok = apply(backend, :apply, [build_config_list(wifi_configs), backend_state])
    {:noreply, state}
  end

  def handle_cast(:scan, %State{backend: backend} = state) do
    :ok = apply(backend, :scan, [])
    {:noreply, state}
  end

  def handle_cast({:delete_configuration, ssid}, %State{configurations: cfgs} = state) do
    {:noreply, %{state | configurations: Map.drop(cfgs, [ssid])}}
  end

  @impl true
  def handle_info(
        info,
        %State{subscriber: subscriber, backend: backend, backend_state: backend_state} = state
      ) do
    case apply(backend, :handle_info, [info, backend_state]) do
      {:reply, message, new_backend_state} ->
        maybe_send(subscriber, {VintageNetWizard, message})
        {:noreply, %{state | backend_state: new_backend_state}}

      {:noreply, new_backend_state} ->
        {:noreply, %{state | backend_state: new_backend_state}}
    end
  end

  defp build_config_list(cfgs) do
    cfgs
    |> Enum.into([], &elem(&1, 1))
    |> Enum.sort(&(&1.priority <= &2.priority))
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
end
