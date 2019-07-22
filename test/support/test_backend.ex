defmodule VintageNetWizard.Test.Backend do
  @behaviour VintageNetWizard.Backend

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
  def save(_cfg, state), do: {:ok, state}

  @impl true
  def configure(_state), do: :ok

  @impl true
  def handle_info(_, state), do: {:noreply, state}
end
