defmodule VintageNetWizard.Web.Endpoint do
  @moduledoc """
  Supervisor for the Web part of the VintageNet Wizard.
  """
  alias VintageNetWizard.Web.{Router, Socket}
  use Supervisor

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  @impl Supervisor
  def init(_args) do
    Supervisor.init(make_children(), strategy: :one_for_one)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/socket", Socket, []},
         {:_, Plug.Cowboy.Handler, {Router, []}}
       ]}
    ]
  end

  defp make_children() do
    if should_start_ap_mode?() do
      :ok = switch_to_ap_mode()

      [
        Plug.Cowboy.child_spec(
          scheme: :http,
          plug: Router,
          options: [port: 4001, dispatch: dispatch()]
        )
      ]
    else
      []
    end
  end

  defp should_start_ap_mode?() do
    config = VintageNet.get_configuration("wlan0")

    with {:ok, wifi} <- Map.fetch(config, :wifi),
         {:ok, _} <- Map.fetch(wifi, :ssid) do
      false
    else
      :error -> true
    end
  end

  defp switch_to_ap_mode() do
    config = %{
      type: VintageNet.Technology.WiFi,
      wifi: %{
        mode: :host,
        ssid: "VintageNet Wizard",
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
end
