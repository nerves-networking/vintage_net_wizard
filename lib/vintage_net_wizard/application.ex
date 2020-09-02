defmodule VintageNetWizard.Application do
  @moduledoc false

  use Application

  alias VintageNetWizard.{Backend, BackendServer, Callbacks}

  @spec start(Application.start_type(), any()) :: {:error, any} | {:ok, pid()}
  def start(_type, _args) do
    backend = Application.get_env(:vintage_net_wizard, :backend, Backend.Default)

    children = [
      {Task.Supervisor, name: VintageNetWizard.TaskSupervisor},
      VintageNetWizard.Web.Endpoint,
      {BackendServer, backend},
      Callbacks
    ]

    opts = [strategy: :one_for_one, name: VintageNetWizard.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
