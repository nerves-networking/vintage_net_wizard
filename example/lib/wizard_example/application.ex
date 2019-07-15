defmodule WizardExampleFw.Application do
  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: WizardExampleFw.Supervisor]

    Supervisor.start_link([], opts)
  end
end
