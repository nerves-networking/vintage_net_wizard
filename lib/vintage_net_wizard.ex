defmodule VintageNetWizard do
  @moduledoc """
  Documentation for VintageNetWizard.
  """

  alias VintageNetWizard.{Backend, APMode, Web.Endpoint}

  @doc """
  Run the wizard.

  This means the WiFi module will be put into access point
  mode and the web server will be started.

  Options:

    - `:ssl` - A Keyword list of `:ssl.tls_server_options`

  See `Plug.SSL.configure/1` for more information about the
  SSL options.
  """
  @spec run_wizard([Endpoint.opt()]) :: :ok | {:error, String.t()}
  def run_wizard(opts \\ []) do
    with :ok <- Backend.reset(),
         :ok <- APMode.into_ap_mode(),
         {:ok, _server} <- Endpoint.start_server(opts),
         :ok <- Backend.start_scan() do
      :ok
    else
      # Already running is still ok
      {:error, :already_started} -> :ok
      error -> error
    end
  end
end
