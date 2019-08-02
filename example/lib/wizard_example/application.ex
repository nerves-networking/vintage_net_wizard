defmodule WizardExample.Application do
  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: WizardExample.Supervisor]

    gpio_pin = Application.get_env(:wizard_example, :gpio_pin, 17)

    children = [
      {WizardExample.Button, gpio_pin}
    ]

    Supervisor.start_link(children, opts)
  end
end
