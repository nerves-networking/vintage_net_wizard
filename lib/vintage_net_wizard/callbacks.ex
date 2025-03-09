# SPDX-FileCopyrightText: 2019 Jon Carstens
# SPDX-FileCopyrightText: 2023 Connor Rigby
# SPDX-FileCopyrightText: 2023 Frank Hunleth
# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetWizard.Callbacks do
  @moduledoc false
  use Agent

  require Logger

  @type callback :: {:on_exit, {module(), atom(), any()}}
  @type callbacks :: [callback]

  @spec start_link(callbacks) :: GenServer.on_start()
  def start_link(callbacks) do
    callbacks = Enum.reduce(callbacks, [], &validate_callback/2)
    Agent.start_link(fn -> callbacks end, name: __MODULE__)
  end

  @spec list() :: any()
  def list() do
    Agent.get(__MODULE__, & &1)
  end

  @spec on_exit() :: any()
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
      Logger.warning(
        "Skipping invalid callback option for #{inspect(key)}\n\tgot: #{inspect(invalid)}\n\texpected: {module, function, [args]}"
      )

    acc
  end
end
