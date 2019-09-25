defmodule VintageNetWizard do
  @moduledoc """
  Documentation for VintageNetWizard.
  """

  alias VintageNetWizard.Backend

  @doc """
  Run the wizard.

  This means the WiFi module will be put into access point
  mode and the web server will be started
  """
  @spec run_wizard() :: :ok
  def run_wizard() do
    with :ok <- Backend.load_configurations(),
         :ok <- into_ap_mode(),
         {:ok, _server} <- start_server() do
      :ok
    else
      # Already running is still ok
      {:error, :already_started} -> :ok
    end
  end

  @doc """
  Change the WiFi module into access point mode
  """
  def into_ap_mode() do
    ssid = get_hostname()

    config = %{
      type: VintageNet.Technology.WiFi,
      wifi: %{
        networks: [
          %{
            mode: :host,
            ssid: ssid,
            key_mgmt: :none
          }
        ]
      },
      ipv4: %{
        method: :static,
        address: {192, 168, 0, 1},
        prefix_length: 24
      },
      dhcpd: %{
        # These are defaults and are reproduced here as documentation
        start: {192, 168, 0, 20},
        end: {192, 168, 0, 254},
        max_leases: 235
      }
    }

    VintageNet.configure("wlan0", config)
  end

  defdelegate start_server(), to: VintageNetWizard.Web.Endpoint

  defdelegate stop_server(), to: VintageNetWizard.Web.Endpoint

  defp get_hostname() do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end
end
