defmodule VintageNetWizard.Web.Endpoint do
  @moduledoc """
  Supervisor for the Web part of the VintageNet Wizard.
  """
  alias VintageNetWizard.{
    Backend,
    BackendServer,
    Callbacks,
    WatchDog,
    Web.Router,
    Web.RedirectRouter
  }

  use DynamicSupervisor

  @typedoc """
  UI specific configuration

  * `:title` - the title of the HTML pages that will be displayed to the user.
  * `:title_color` - color of the title for branding purposes
  * `:button_color` - color of the buttons for branding purposes
  """
  @type ui_opt :: {:title, String.t()} | {:title_color, String.t()} | {:button_color, String.t()}

  @type opt ::
          {:ssl, :ssl.tls_server_option()}
          | {:on_exit, {module(), atom(), list()}}
          | {:ifname, VintageNet.ifname()}
          | {:ap_ifname, VintageNet.ifname()}
          | {:ui, [ui_opt()]}
          | Backend.opt()

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
    use_captive_portal? = Application.get_env(:vintage_net_wizard, :captive_portal, true)
    inactivity_timeout = Application.get_env(:vintage_net_wizard, :inactivity_timeout, 10)
    callbacks = Keyword.take(opts, [:on_exit])

    with spec <- maybe_use_ssl(use_ssl?, opts),
         {:ok, _pid} <- DynamicSupervisor.start_child(__MODULE__, spec),
         {:ok, _pid} <- maybe_with_redirect(use_captive_portal?, use_ssl?),
         {:ok, _pid} <- DynamicSupervisor.start_child(__MODULE__, get_backend_spec(opts)),
         {:ok, _pid} <- DynamicSupervisor.start_child(__MODULE__, {Callbacks, callbacks}),
         {:ok, _pid} <-
           DynamicSupervisor.start_child(__MODULE__, {WatchDog, inactivity_timeout}) do
      :ok
    else
      {:error, :max_children} -> {:error, :already_started}
      error -> error
    end
  end

  @doc """
  Stop the web server
  """
  @spec stop_server(VintageNetWizard.stop_reason()) :: :ok
  def stop_server(stop_reason) do
    _ =
      get_children()
      |> stop_some_children()
      |> handle_watchdog(stop_reason)
      |> handle_callbacks()

    :ok
  end

  defp stop_some_children(children) do
    to_stop = Map.drop(children, [WatchDog, Callbacks])

    _ =
      for {_mod, child} <- to_stop do
        :ok = DynamicSupervisor.terminate_child(__MODULE__, child)
      end

    children
  end

  # if the reason for stopping is a timeout then we don't try to stop
  # the WatchDog as it will stop itself.
  defp handle_watchdog(children, :timeout), do: children

  defp handle_watchdog(children, _other) do
    :ok = DynamicSupervisor.terminate_child(__MODULE__, children[WatchDog])
    children
  end

  defp handle_callbacks(children) do
    _ = Callbacks.on_exit()

    _ = DynamicSupervisor.terminate_child(__MODULE__, children[Callbacks])
    children
  end

  defp get_children() do
    __MODULE__
    |> DynamicSupervisor.which_children()
    |> Enum.reduce(%{}, fn {_, child, _, [mod]}, acc ->
      Map.put(acc, mod, child)
    end)
  end

  @impl DynamicSupervisor
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 4)
  end

  defp dispatch(opts) do
    [
      {:_,
       [
         {:_, Plug.Cowboy.Handler, {Router, opts}}
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
    options = [dispatch: dispatch(opts), port: get_port(use_ssl)]

    Plug.Cowboy.child_spec(
      plug: Router,
      scheme: :https,
      options: Keyword.merge(ssl_options, options)
    )
  end

  defp maybe_use_ssl(_no_ssl, opts) do
    Plug.Cowboy.child_spec(
      plug: Router,
      scheme: :http,
      options: [
        dispatch: dispatch(opts),
        port: get_port()
      ]
    )
  end

  defp get_backend_spec(opts) do
    ifname = Keyword.get(opts, :ifname, "wlan0")
    ap_ifname = Keyword.get(opts, :ap_ifname, ifname)
    device_info = Keyword.get(opts, :device_info, [])
    configurations = Keyword.get(opts, :configurations, [])

    backend = Application.get_env(:vintage_net_wizard, :backend, VintageNetWizard.Backend.Default)

    BackendServer.child_spec(backend, ifname,
      ap_ifname: ap_ifname,
      device_info: device_info,
      configurations: configurations
    )
  end
end
