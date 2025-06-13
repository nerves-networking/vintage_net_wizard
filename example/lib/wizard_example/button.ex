defmodule WizardExample.Button do
  use GenServer

  @moduledoc """
  This GenServer starts the wizard if a button is depressed for long enough.
  """

  alias Circuits.GPIO

  @doc """
  Start the button monitor

  Pass an index to the GPIO that's connected to the button.
  """
  @spec start_link(non_neg_integer()) :: GenServer.on_start()
  def start_link(gpio_pin) do
    GenServer.start_link(__MODULE__, gpio_pin)
  end

  @impl GenServer
  def init(gpio_pin) do
    {:ok, gpio} = GPIO.open(gpio_pin, :input)
    :ok = GPIO.set_interrupts(gpio, :both)
    {:ok, %{pin: gpio_pin, gpio: gpio}}
  end

  @impl GenServer
  def handle_info({:circuits_gpio, gpio_pin, _timestamp, 1}, %{pin: gpio_pin} = state) do
    # Button pressed. Start a timer to launch the wizard when it's long enough
    {:noreply, state, 5_000}
  end

  def handle_info({:circuits_gpio, gpio_pin, _timestamp, 0}, %{pin: gpio_pin} = state) do
    # Button released. The GenServer timer is implicitly cancelled by receiving this message.
    {:noreply, state}
  end

  def handle_info(:timeout, state) do
    :ok = VintageNetWizard.run_wizard(device_info: get_device_info())
    {:noreply, state}
  end

  defp get_device_info() do
    kv =
      Nerves.Runtime.KV.get_all_active()
      |> kv_to_map()

    mac_addr = VintageNet.get(["interface", "wlan0", "mac_address"])

    [
      {"WiFi Address", mac_addr},
      {"Serial number", serial_number()},
      {"Firmware", kv["nerves_fw_product"]},
      {"Firmware version", kv["nerves_fw_version"]},
      {"Firmware UUID", kv["nerves_fw_uuid"]}
    ]
  end

  defp kv_to_map(key_values) do
    for kv <- key_values, into: %{}, do: kv
  end

  defp serial_number() do
    with boardid_path when not is_nil(boardid_path) <- System.find_executable("boardid"),
         {id, 0} <- System.cmd(boardid_path, []) do
      String.trim(id)
    else
      _other -> "Unknown"
    end
  end
end
