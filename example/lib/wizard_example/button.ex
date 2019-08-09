defmodule WizardExample.Button do
  use GenServer

  alias Circuits.GPIO

  @doc """
  Start the button monitor

  Pass an index to the GPIO that's connected to the button.
  """
  @spec start_link(non_neg_integer()) :: GenServer.on_start()
  def start_link(gpio_pin) do
    GenServer.start_link(__MODULE__, gpio_pin)
  end

  @impl true
  def init(gpio_pin) do
    {:ok, gpio} = GPIO.open(gpio_pin, :input)
    :ok = GPIO.set_interrupts(gpio, :both)
    {:ok, %{pin: gpio_pin, gpio: gpio}}
  end

  def handle_info({:circuits_gpio, gpio_pin, _, 1}, %{pin: gpio_pin} = state) do
    {:noreply, state, 5_000}
  end

  def handle_info(:timeout, state) do
    :ok = VintageNetWizard.run_wizard()
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
