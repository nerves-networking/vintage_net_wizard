defmodule VintageNetWizard.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    network = Application.get_env(:vintage_net_wizard, :backend, VintageNetWizard.Network.Default)
    port = Application.get_env(:vintage_net_wizard, :port, 80)

    children = [
      {VintageNetWizard.Network, [network]},
      {VintageNetWizard.Web.Endpoint, [port]}
    ]

    opts = [strategy: :one_for_one, name: VintageNetWizard.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
