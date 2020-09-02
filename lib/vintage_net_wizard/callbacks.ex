defmodule VintageNetWizard.Callbacks do
  use Agent

  require Logger

  def start_link(callbacks \\ []) do
    callbacks =
      starting_callbacks(callbacks)
      |> Enum.reduce([], &validate_callback/2)

    Agent.start_link(fn -> callbacks end, name: __MODULE__)
  end

  def list() do
    Agent.get(__MODULE__, & &1)
  end

  def on_complete() do
    list()
    |> Keyword.get(:on_complete)
    |> apply_callback()
  end

  def on_exit() do
    list()
    |> Keyword.get(:on_exit)
    |> apply_callback()
  end

  def set_callbacks(callbacks) do
    cbs = Enum.reduce(callbacks, [], &validate_callback/2)
    Agent.update(__MODULE__, &Keyword.merge(&1, cbs))
  end

  defp apply_callback({mod, fun, args}) do
    try do
      apply(mod, fun, args)
    rescue
      err ->
        Logger.error("[VintageNetWizard] Failed to run callback: #{inspect(err)}")
    end
  end

  defp apply_callback(invalid), do: {:error, "invalid callback: #{inspect(invalid)}"}

  defp starting_callbacks(initial) do
    cbs = Application.get_env(:vintage_net_wizard, :callbacks, [])

    if Keyword.keyword?(cbs) do
      Keyword.merge(cbs, initial)
    else
      Logger.warn("[VintageNetWizard] invalid callbacks defined in config:\n\t#{inspect(cbs)}\n")
      initial
    end
  end

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
