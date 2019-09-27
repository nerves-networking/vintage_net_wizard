defmodule VintageNetWizard.Test.Backend do
  @behaviour VintageNetWizard.Backend

  @impl true
  def init() do
    {:ok, nil}
  end

  @impl true
  def access_points(_), do: []

  @impl true
  def apply(_cfgs, _state), do: :ok

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  @impl true
  def device_info(), do: []

  @impl true
  def reset(), do: %{}

  @impl true
  def configuration_status(_state), do: :not_configured
end
