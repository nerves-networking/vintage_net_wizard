defmodule VintageNetWizard.Application do
  @moduledoc false

  use Application

  @spec start(Application.start_type(), any()) :: {:error, any} | {:ok, pid()}
  def start(_type, _args) do
    backend = Application.get_env(:vintage_net_wizard, :backend, VintageNetWizard.Backend.Default)

    children = [
      VintageNetWizard.Web.Endpoint
    ]

    opts = [strategy: :one_for_one, name: VintageNetWizard.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
