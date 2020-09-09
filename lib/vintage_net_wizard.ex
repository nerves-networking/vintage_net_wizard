defmodule VintageNetWizard do
  @moduledoc """
  Documentation for VintageNetWizard.
  """

  alias VintageNetWizard.{BackendServer, APMode, Web.Endpoint}

  @doc """
  Run the wizard.

  This means the WiFi module will be put into access point mode and the web
  server will be started.

  Options:

    * `:backend` - Implementation for communicating with the network drivers (defaults to `VintageNetWizard.Backend.Default`)
    * `:captive_portal` - Whether to run in captive portal mode (defaults to `true`)
    * `:device_info` - A list of string tuples to render in a table in the footer (see `README.md`)
    * `:ifname` - The network interface to use (defaults to `"wlan0"`)
    * `:inactivity_timeout` - Minutes to run before automatically stopping (defaults to 10 minutes)
    * `:on_exit` - `{module, function, args}` tuple specifying callback to perform after stopping the server.
    * `:ssl` - A Keyword list of `:ssl.tls_server_options`. See `Plug.SSL.configure/1`.
  """
  @spec run_wizard([Endpoint.opt()]) :: :ok | {:error, String.t()}
  def run_wizard(opts \\ []) do
    ifname = Keyword.get(opts, :ifname, "wlan0")

    with :ok <- APMode.into_ap_mode(ifname),
         :ok <- Endpoint.start_server(opts),
         :ok <- BackendServer.start_scan() do
      :ok
    else
      # Already running is still ok
      {:error, :already_started} -> :ok
      error -> error
    end
  end

  @doc """
  Stop the wizard.

  This will apply the current configuration in memory and completely
  stop the web and backend processes.
  """
  @spec stop_wizard() :: :ok | {:error, String.t()}
  def stop_wizard() do
    with :ok <- BackendServer.complete(),
         :ok <- Endpoint.stop_server() do
      :ok
    else
      error -> error
    end
  end
end
