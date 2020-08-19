defmodule VintageNetWizard.WatchDog do
  @moduledoc false

  # This server is used to watch for activity in the wizard. If the inactivity
  # timeout is triggered this server will shutdown the wizard. In order to keep
  # this server from shutting down the wizard call `pet/0` to reset the
  # timeout. The timeout should be in minutes.

  use GenServer

  require Logger

  @doc """
  Start the watcher
  """
  @spec start_link(timeout()) :: GenServer.on_start()
  def start_link(inactivity_timeout_seconds) do
    GenServer.start_link(__MODULE__, inactivity_timeout_seconds, name: __MODULE__)
  end

  @doc """
  Pet the watch dog to prevent it from shutting down the wizard
  """
  @spec pet() :: :ok
  def pet() do
    GenServer.call(__MODULE__, :pet)
  end

  @impl GenServer
  def init(inactivity_timeout_seconds) do
    inactivity_timeout = inactivity_timeout_seconds * 60_000
    {:ok, inactivity_timeout, inactivity_timeout}
  end

  @impl GenServer
  def handle_call(:pet, _from, inactivity_timeout) do
    {:reply, :ok, inactivity_timeout, inactivity_timeout}
  end

  @impl GenServer
  def handle_info(:timeout, inactivity_timeout) do
    Logger.info("[VintageNetWizard] inactivity timeout, shutting down wizard")
    :ok = VintageNetWizard.stop_wizard()
    {:stop, :normal, inactivity_timeout}
  end

  @impl GenServer
  def terminate(:normal, _), do: :ok
end
