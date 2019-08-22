defmodule VintageNetWizard do
  @moduledoc """
  Documentation for VintageNetWizard.
  """

  @doc """
  Run the wizard.

  This means the WiFi module will be put into access point
  mode and the web server will be started
  """
  @spec run_wizard() :: :ok | {:error, any()}
  def run_wizard() do
    with :ok <- into_ap_mode(),
         {:ok, _server} <- start_server() do
      :ok
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
        mode: :host,
        ssid: ssid,
        key_mgmt: :none,
        scan_ssid: 1,
        ap_scan: 1,
        bgscan: :simple
      },
      ipv4: %{
        method: :static,
        address: "192.168.24.1",
        netmask: "255.255.255.0"
      },
      dhcpd: %{
        start: "192.168.24.2",
        end: "192.168.24.10"
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
