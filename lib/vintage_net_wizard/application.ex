defmodule VintageNetWizard.Application do
  @moduledoc false

  @target Mix.target()

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: VintageNetWizard.Supervisor]
    Supervisor.start_link(children(@target), opts)
  end

  def children(:host) do
    [
      {VintageNetWizard.Backend, [Application.get_env(:vintage_net_wizard, :backend)]},
      VintageNetWizard.Web.Endpoint
    ]
  end

  def children(_target) do
    [
      VintageNetWizard.Web.Endpoint
    ]
  end
end
