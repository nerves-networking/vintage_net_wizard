defmodule VintageNetWizard.Callbacks do
  @moduledoc false
  use Agent

  require Logger

  def start_link(callbacks) do
    callbacks = Enum.reduce(callbacks, [], &validate_callback/2)
    Agent.start_link(fn -> callbacks end, name: __MODULE__)
  end

  def list() do
    Agent.get(__MODULE__, & &1)
  end

  def on_exit() do
    list()
    |> Keyword.get(:on_exit)
    |> apply_callback()
  end

  defp apply_callback({mod, fun, args}) do
    apply(mod, fun, args)
  rescue
    err ->
      Logger.error("[VintageNetWizard] Failed to run callback: #{inspect(err)}")
  end

  defp apply_callback(invalid), do: {:error, "invalid callback: #{inspect(invalid)}"}

  defp validate_callback({_key, {mod, fun, args}} = callback, acc)
       when is_atom(mod) and is_atom(fun) and is_list(args) do
    [callback | acc]
  end

  defp validate_callback({key, invalid}, acc) do
    _ =
      Logger.warn(
        "Skipping invalid callback option for #{inspect(key)}\n\tgot: #{inspect(invalid)}\n\texpected: {module, function, [args]}"
      )

    acc
  end
end
