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

  def subscribe() do
    GenServer.cast(__MODULE__, {:subscribe, self()})
  end

  def access_points() do
    GenServer.call(__MODULE__, :access_points)
  end

  def save(cfg) do
    IO.inspect(cfg, label: "CFG")
    :ok
  end

  def init(backend) do
    {:ok, backend_state} = apply(backend, :init, [])
    {:ok, %State{backend: backend, backend_state: backend_state}, {:continue, :scan}}
  end

  def handle_continue(:scan, %State{backend: backend} = state) do
    :ok = apply(backend, :scan, [])
    {:noreply, state}
  end

  def handle_call(
        :access_points,
        _from,
        %State{backend: backend, backend_state: backend_state} = state
      ) do
    access_points = apply(backend, :access_points, [backend_state])
    {:reply, access_points, state}
  end

  def handle_cast({:subscribe, subscriber}, state) do
    {:noreply, %{state | subscriber: subscriber}}
  end

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
