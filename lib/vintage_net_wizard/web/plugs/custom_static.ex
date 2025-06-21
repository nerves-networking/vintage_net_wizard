defmodule VintageNetWizard.Plugs.CustomStatic do
  @moduledoc false

  @behaviour Plug

  @impl Plug
  @spec init(Plug.opts()) :: map()
  def init(_opts) do
    Plug.Static.init(from: {:vintage_net_wizard, "priv/static"}, at: "/")
  end

  @impl Plug
  @spec call(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def call(conn, opts) do
    runtime_opts =
      if from = Keyword.get(conn.assigns.init_opts, :static_files_path) do
        Map.put(opts, :from, from)
      else
        opts
      end

    Plug.Static.call(conn, runtime_opts)
  end
end
