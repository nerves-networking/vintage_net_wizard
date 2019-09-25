defmodule VintageNetWizard.Application do
  @moduledoc false

  use Application

  alias VintageNetWizard.{Backend, Web.Endpoint}

  @spec start(Application.start_type(), any()) :: {:error, any} | {:ok, pid()}
  def start(_type, _args) do
    backend = Application.get_env(:vintage_net_wizard, :backend, VintageNetWizard.Backend.Default)

    children = [
      {Endpoint, []},
      {Backend, backend}
    ]

    opts = [strategy: :one_for_one, name: VintageNetWizard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_phase(:wizard_startup, _start_type, _phase_args) do
    unless Backend.configured?(), do: VintageNetWizard.run_wizard()
    :ok
  end
end
