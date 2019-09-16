defmodule VintageNetWizard.Web.Endpoint do
  @moduledoc """
  Supervisor for the Web part of the VintageNet Wizard.
  """
  alias VintageNetWizard.Web.Router

  use DynamicSupervisor

  @ssl_dir Path.join(:code.priv_dir(:vintage_net_wizard), "ssl")

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
    use_ssl? = Application.get_env(:vintage_net_wizard, :ssl)

    spec = maybe_use_ssl(use_ssl?)

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
         {:_, Plug.Cowboy.Handler, {Router, []}}
       ]}
    ]
  end

  defp maybe_use_ssl(_use_ssl = true) do
    Plug.Cowboy.child_spec(
      plug: Router,
      scheme: :https,
      options: [
        dispatch: dispatch(),
        certfile: Application.get_env(:vintage_net_wizard, :certfile, "#{@ssl_dir}/cert.pem"),
        keyfile: Application.get_env(:vintage_net_wizard, :keyfile, "#{@ssl_dir}/key.pem"),
        port: Application.get_env(:vintage_net_wizard, :port, 443)
      ]
    )
  end

  defp maybe_use_ssl(_no_ssl) do
    Plug.Cowboy.child_spec(
      plug: Router,
      scheme: :http,
      options: [
        dispatch: dispatch(),
        port: Application.get_env(:vintage_net_wizard, :port, 80)
      ]
    )
  end
end
