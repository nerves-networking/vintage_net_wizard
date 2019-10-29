defmodule VintageNetWizard.Web.Endpoint do
  @moduledoc """
  Supervisor for the Web part of the VintageNet Wizard.
  """
  alias VintageNetWizard.{Backend, Web.Router}
  use DynamicSupervisor

  @type opt :: {:ssl, :ssl.tls_server_option()}

  @doc false
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Start the web server

  If the web server is started then `{:error, already_started}` is returned.

  Only one server can be running at a time.
  """
  @spec start_server([opt]) ::
          :ok | {:error, :already_started | :no_keyfile | :no_certfile}
  def start_server(opts \\ []) do
    use_ssl? = Keyword.has_key?(opts, :ssl)
    backend = Application.get_env(:vintage_net_wizard, :backend, VintageNetWizard.Backend.Default)

    with spec <- maybe_use_ssl(use_ssl?, opts),
         {:ok, _pid} <- DynamicSupervisor.start_child(__MODULE__, spec),
         {:ok, _pid} <- DynamicSupervisor.start_child(__MODULE__, {Backend, backend}) do
      :ok
    else
      {:error, :max_children} -> {:error, :already_started}
      error -> error
    end
  end

  @doc """
  Stop the web server
  """
  @spec stop_server() :: :ok | {:error, :not_found}
  def stop_server() do
    case DynamicSupervisor.which_children(__MODULE__) do
      [{_, cowboy, _, _}, {_, backend, _, _}] ->
        _ = DynamicSupervisor.terminate_child(__MODULE__, cowboy)
        _ = DynamicSupervisor.terminate_child(__MODULE__, backend)
        :ok

      _ ->
        {:error, :not_found}
    end
  end

  @impl DynamicSupervisor
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 2)
  end

  defp dispatch do
    [
      {:_,
       [
         {:_, Plug.Cowboy.Handler, {Router, []}}
       ]}
    ]
  end

  defp maybe_use_ssl(_use_ssl = true, opts) do
    port = Application.get_env(:vintage_net_wizard, :port, 443)
    ssl_options = Keyword.get(opts, :ssl)
    options = [dispatch: dispatch(), port: port]

    Plug.Cowboy.child_spec(
      plug: Router,
      scheme: :https,
      options: Keyword.merge(ssl_options, options)
    )
  end

  defp maybe_use_ssl(_no_ssl, _opts) do
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
