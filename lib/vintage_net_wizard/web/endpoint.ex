defmodule VintageNetWizard.Web.Endpoint do
  @moduledoc """
  Supervisor for the Web part of the VintageNet Wizard.
  """
  alias VintageNetWizard.Web.{Router, Socket}

  use DynamicSupervisor

  @doc false
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Start the web server

  If the web server is started then `{:error, already_started}` is returned.

  Only one server can be running at a time.
  """
  @spec start_server() :: GenServer.on_start() | {:error, :already_started}
  def start_server() do
    port = Application.get_env(:vintage_net_wizard, :port, 80)

    spec =
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Router,
        options: [port: port, dispatch: dispatch()]
      )

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:error, :max_children} -> {:error, :already_started}
      ok -> ok
    end
  end

  @doc """
  Stop the web server
  """
  @spec stop_server() :: :ok | {:error, :not_found}
  def stop_server() do
    case DynamicSupervisor.which_children(__MODULE__) do
      [{_, server_pid, :supervisor, [:ranch_listener_sup]}] ->
        DynamicSupervisor.terminate_child(__MODULE__, server_pid)

      _ ->
        {:error, :not_found}
    end
  end

  @impl DynamicSupervisor
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 1)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/socket", Socket, []},
         {:_, Plug.Cowboy.Handler, {Router, []}}
       ]}
    ]
  end
end
