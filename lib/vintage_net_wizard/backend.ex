defmodule VintageNetWizard.Backend do
  @moduledoc """
  Backends define the boundaries of getting access points,
  handling incoming messages, and scanning the network
  """
  use GenServer

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
  @callback access_points(state :: any()) :: map()

  @doc """
  Check if the WiFi network is configured
  """
  @callback configured?() :: boolean()

  @doc """
  Save the configuration
  """
  @callback save(cfg :: map(), state :: any()) :: {:ok, state :: any()} | {:error, any()}

  @doc """
  Configure the wifi network
  """
  @callback configure(state :: any()) :: :ok

  @doc """
  Handle any message the is recieved by another process

  If you want the socket to send data to the client
  return `{:reply, message, state}`, otherwise return
  `{:noreply, state}`
  """
  @callback handle_info(any(), state :: any()) ::
              {:reply, any(), state :: any()} | {:noreply, state :: any()}

  defmodule State do
    defstruct subscriber: nil, backend: nil, backend_state: nil
  end

  def start_link([backend]) do
    GenServer.start_link(__MODULE__, backend, name: __MODULE__)
  end

  @spec subscribe() :: :ok
  def subscribe() do
    GenServer.cast(__MODULE__, {:subscribe, self()})
  end

  @spec access_points() :: map()
  def access_points() do
    GenServer.call(__MODULE__, :access_points)
  end

  @spec save(map()) :: :ok | {:error, any()}
  def save(cfg) do
    GenServer.call(__MODULE__, {:save, cfg})
  end

  @spec configured?() :: boolean()
  def configured?() do
    GenServer.call(__MODULE__, :configured?)
  end

  @spec configure() :: :ok
  def configure() do
    GenServer.cast(__MODULE__, :configure)
  end

  @impl true
  def init(backend) do
    case apply(backend, :init, []) do
      {:ok, backend_state} ->
        {:ok, %State{backend: backend, backend_state: backend_state}}

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
        {:save, cfg},
        _from,
        %State{backend: backend, backend_state: backend_state} = state
      ) do
    case apply(backend, :save, [cfg, backend_state]) do
      {:ok, new_backend_state} ->
        {:reply, :ok, %{state | backend_state: new_backend_state}}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call(:configured?, _from, %State{backend: backend} = state) do
    {:reply, apply(backend, :configured?, []), state}
  end

  @impl true
  def handle_cast({:subscribe, subscriber}, state) do
    {:noreply, %{state | subscriber: subscriber}}
  end

  def handle_cast(:configure, %State{backend: backend, backend_state: backend_state} = state) do
    :ok = apply(backend, :configure, [backend_state])
    {:noreply, state}
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

  defp maybe_send(nil, _message), do: :ok
  defp maybe_send(pid, message), do: send(pid, message)
end
