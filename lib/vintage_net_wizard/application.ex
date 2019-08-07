defmodule VintageNetWizard.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    backend = Application.get_env(:vintage_net_wizard, :backend, VintageNetWizard.Backend.Default)

    children = [
      {VintageNetWizard.Web.Endpoint, []},
      {VintageNetWizard.Backend, backend}
    ]

    opts = [strategy: :one_for_one, name: VintageNetWizard.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
