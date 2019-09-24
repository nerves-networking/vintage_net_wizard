defmodule VintageNetWizard.Backend do
  @moduledoc """
  Backends define the boundaries of getting access points,
  handling incoming messages, and scanning the network
  """
  use GenServer

  alias VintageNetWizard.WiFiConfiguration
  alias VintageNet.WiFi.AccessPoint

  @type configuration_status :: :not_configured | :good | :bad

  @doc """
  Do any initialization work like subscribing to messages
  """
  @callback init() :: state :: any()

  @doc """
  Get all the access points that the backend knowns about
  """
  @callback access_points(state :: any()) :: [AccessPoint.t()]

  @doc """
  Apply the WiFi configurations
  """
  @callback apply([WiFiConfiguration.t()], state :: any()) ::
              {:ok, state :: any()} | {:error, :invalid_state}

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

  @doc """
  Return the configuration status of a configuration that has been applied
  """
  @callback configuration_status(state :: any()) :: configuration_status()

  @doc """
  Apply any actions required to set the backend back to an
  initial default state
  """
  @callback reset() :: state :: any()

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
  def configuration_state() do
    GenServer.call(__MODULE__, :configuration_state)
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
  Get the current configuration status
  """
  def configuration_status() do
    GenServer.call(__MODULE__, :configuration_status)
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
    GenServer.call(__MODULE__, :apply)
  end

  @doc """
  Reset the backend to an initial default state.
  """
  @spec reset() :: :ok
  def reset() do
    GenServer.call(__MODULE__, :reset)
  end

  @impl true
  def init(backend) do
    {:ok,
     %State{
       configurations: %{},
       backend: backend,
       backend_state: apply(backend, :init, [])
     }}
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

  def handle_call(
        :configuration_status,
        _from,
        %State{backend: backend, backend_state: backend_state} = state
      ) do
    status = apply(backend, :configuration_status, [backend_state])
    {:reply, status, state}
  end

  def handle_call({:save, config}, _from, %{configurations: cfgs} = state) do
    {:reply, :ok, %{state | configurations: Map.put(cfgs, config.ssid, config)}}
  end

  def handle_call(
        :device_info,
        _from,
        %State{backend: backend} = state
      ) do
    {:reply, apply(backend, :device_info, []), state}
  end

  def handle_call(:configurations, _from, %State{configurations: cfgs} = state) do
    {:reply, build_config_list(cfgs), state}
  end

  def handle_call(
        :apply,
        _from,
        %State{backend: backend, configurations: wifi_configs, backend_state: backend_state} =
          state
      ) do
    case apply(backend, :apply, [build_config_list(wifi_configs), backend_state]) do
      {:ok, new_backend_state} ->
        {:reply, :ok, %{state | backend_state: new_backend_state}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(:reset, _from, %State{backend: backend} = state) do
    new_state = apply(backend, :reset, [])
    {:reply, :ok, %{state | configurations: %{}, backend_state: new_state}}
  end

  @impl true
  def handle_cast({:subscribe, subscriber}, state) do
    {:noreply, %{state | subscriber: subscriber}}
  end

  def handle_cast({:delete_configuration, ssid}, %State{configurations: cfgs} = state) do
    {:noreply, %{state | configurations: Map.drop(cfgs, [ssid])}}
  end

  @impl true
  def handle_info(
        info,
        %State{
          subscriber: subscriber,
          backend: backend,
          backend_state: backend_state
        } = state
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
