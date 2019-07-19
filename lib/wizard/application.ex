defmodule VintageNet.Wizard.Application do
  @moduledoc false

  @target Mix.target()

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: VintageNet.Wizard.Supervisor]
    Supervisor.start_link(children(@target), opts)
  end

  def children(:host) do
    [
      VintageNet.Wizard.Web.Endpoint,
      {VintageNet.Wizard.Backend, [VintageNet.Wizard.Backend.Host]}
    ]
  end

  def children(_target) do
    [
      VintageNet.Wizard.Web.Endpoint
    ]
  end
end
