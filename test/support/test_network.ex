defmodule VintageNetWizard.Test.Network do
  @behaviour VintageNetWizard.Network

  @impl true
  def init() do
    {:ok, nil}
  end

  @impl true
  def scan(), do: :ok

  @impl true
  def access_points(_), do: %{}

  @impl true
  def configured?(), do: true

  @impl true
  def apply(_cfgs, _state), do: :ok

  @impl true
  def handle_info(_, state), do: {:noreply, state}
end
