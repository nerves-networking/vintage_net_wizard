defmodule VintageNetWizard.Plugs.CustomStatic do
  @moduledoc false

  def init(_opts) do
    Plug.Static.init(from: {:vintage_net_wizard, "priv/static"}, at: "/")
  end

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
