defmodule VintageNetWizard.Test.Backend do
  @behaviour VintageNetWizard.Backend

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def scan(), do: :ok

  @impl true
  def access_points(_), do: []

  @impl true
  def configured?(_), do: true

  @impl true
  def apply(_cfgs, _state), do: :ok

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  @impl true
  def device_info(), do: []

  @impl true
  def configuration_status(_), do: :not_configured

  @impl true
  def reset(), do: nil

  @impl true
  def load_configurations(), do: []

  @impl true
  def configured?(_), do: false
end
