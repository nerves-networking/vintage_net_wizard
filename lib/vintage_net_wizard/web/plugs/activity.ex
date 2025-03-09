# SPDX-FileCopyrightText: 2020 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetWizard.Plugs.Activity do
  @moduledoc false

  alias Plug.Conn
  alias VintageNetWizard.WatchDog

  @typedoc """
  Options for the plug:

  - `:excluding` - list of string paths to exclude from pinging the activity
    monitor
  """
  @type opt() :: {:excluding, [String.t()]}

  @spec init([opt()]) :: [opt()]
  def init(opts) do
    opts
  end

  @spec call(Conn.t(), [opt()]) :: Conn.t()
  def call(conn, opts) do
    excluded_paths = Keyword.get(opts, :excluding, [])
    uri = URI.parse(Conn.request_url(conn))

    if Enum.member?(excluded_paths, uri.path) do
      conn
    else
      :ok = WatchDog.pet()
      conn
    end
  end
end
