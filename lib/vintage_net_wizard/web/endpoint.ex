defmodule VintageNetWizard.Web.Endpoint do
  @moduledoc """
  Supervisor for the Web part of the VintageNet Wizard.
  """
  alias VintageNetWizard.{Callbacks, Web.Router, Web.RedirectRouter}
  alias VintageNetWizard.TaskSupervisor, as: Tasks
  use DynamicSupervisor

  @type opt :: {:ssl, :ssl.tls_server_option()} | {:on_exit, {module(), atom(), list()}}

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

    use_captive_portal? =
      opts[:captive_portal] || Application.get_env(:vintage_net_wizard, :captive_portal, true)

    _ = set_callbacks(opts)

    with spec <- maybe_use_ssl(use_ssl?, opts),
         {:ok, _pid} <- DynamicSupervisor.start_child(__MODULE__, spec),
         {:ok, _pid} <- maybe_with_redirect(use_captive_portal?, use_ssl?) do
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
      [] ->
        {:error, :not_found}

      children ->
        Enum.each(children, fn {_, child, _, _} ->
          DynamicSupervisor.terminate_child(__MODULE__, child)
        end)

        _ = Callbacks.on_exit()
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

  defp get_port(use_ssl? \\ false) do
    default_port = if use_ssl?, do: 443, else: 80
    Application.get_env(:vintage_net_wizard, :port, default_port)
  end

  defp maybe_with_redirect(_use_captive_portal = true, use_ssl?) do
    # Captive Portal needs port 80. If we're not listening on that
    # then we start a RedirectRouter to forward port 80 traffic
    # to our defined port
    case get_port(use_ssl?) do
      80 ->
        {:ok, :ignore}

      port ->
        scheme = if use_ssl?, do: :https, else: :http
        dns_name = Application.get_env(:vintage_net_wizard, :dns_name, "wifi.config")

        redirect_spec =
          Plug.Cowboy.child_spec(
            plug: {RedirectRouter, [scheme: scheme, dns_name: dns_name, port: port]},
            scheme: :http,
            options: [port: 80]
          )

        DynamicSupervisor.start_child(__MODULE__, redirect_spec)
    end
  end

  defp maybe_with_redirect(_no_captive_portal, _), do: {:ok, :ignore}

  defp maybe_use_ssl(use_ssl = true, opts) do
    ssl_options = Keyword.get(opts, :ssl)
    options = [dispatch: dispatch(), port: get_port(use_ssl)]

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
        port: get_port()
      ]
    )
  end

  defp set_callbacks(opts) do
    on_complete =
      {Task.Supervisor, :start_child,
       [
         Tasks,
         fn ->
           # We don't want to stop the server before we
           # send the response back.
           :timer.sleep(3000)
           __MODULE__.stop_server()
         end
       ]}

    Keyword.take(opts, [:on_exit])
    |> Keyword.put(:on_complete, on_complete)
    |> Callbacks.set_callbacks()
  end
end
