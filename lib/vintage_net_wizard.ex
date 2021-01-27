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
    configurations = get_network_configs(ifname)
    opts = Keyword.put(opts, :configurations, configurations)

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
  Conditionally run the wizard if there is no configurations present

  This function is the same `VintageNetWizard.run_wizard/1` however it will
  first check if there are any configurations for the interface.

  This is useful if you want a device to start the wizard only if there are no
  configurations for the interface. When there are configurations found for the
  interface this function returns `:configured` to let the consuming application
  know that the wizard wasn't needed.

  If you want more control on how to start the wizard or if you want to force
  start the wizard you can call `VintageNetWizard.run_wizard/1`.
  """
  @spec run_if_unconfigured([Endpoint.opt()]) :: :ok | :configured | {:error, String.t()}
  def run_if_unconfigured(opts \\ []) do
    ifname = Keyword.get(opts, :ifname, "wlan0")

    if wifi_configured?(ifname) do
      :configured
    else
      run_wizard(opts)
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

  @doc """
  Check if an interface has a configuration
  """
  @spec wifi_configured?(VintageNet.ifname()) :: boolean()
  def wifi_configured?(ifname) do
    VintageNet.get(["interface", ifname, "config"])
    |> get_in([:vintage_net_wifi, :networks])
    |> has_networks?()
  end

  defp has_networks?(nil), do: false
  defp has_networks?([]), do: false
  defp has_networks?(_networks), do: true

  defp get_network_configs(ifname) do
    config = VintageNet.get(["interface", ifname, "config"])

    case get_in(config, [:vintage_net_wifi, :networks]) do
      nil -> []
      networks -> networks
    end
  end
end
