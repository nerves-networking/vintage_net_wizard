defmodule VintageNetWizard do
  @moduledoc """
  Documentation for VintageNetWizard.
  """

  alias VintageNetWizard.{BackendServer, APMode, Web.Endpoint}

  @doc """
  Run the wizard.

  This means the WiFi module will be put into access point
  mode and the web server will be started.

  Options:

    - `:ssl` - A Keyword list of `:ssl.tls_server_options`
    - `:on_exit` - `{module, function, args}` tuple specifying
    callback to perform after stopping the server.

  See `Plug.SSL.configure/1` for more information about the
  SSL options.
  """
  @spec run_wizard([Endpoint.opt()]) :: :ok | {:error, String.t()}
  def run_wizard(opts \\ []) do
    with :ok <- APMode.into_ap_mode(),
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
