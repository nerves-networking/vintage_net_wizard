defmodule VintageNetWizard.Web.Router do
  @moduledoc false

  use Plug.Router
  use Plug.Debugger, otp_app: :vintage_net_wizard

  plug(Plug.Logger, log: :debug)
  plug(Plug.Static, from: {:vintage_net_wizard, "priv/static"}, at: "/")
  plug(:match)
  plug(:dispatch)

  get "/" do
    render_page(conn, "index.html")
  end

  forward("/api/v1", to: VintageNetWizard.Web.Api)

  match _ do
    send_resp(conn, 404, "oops")
  end

  defp render_page(conn, page, info \\ []) do
    info = info ++ firmware_info() ++ serial_number_info()

    page
    |> template_file()
    |> EEx.eval_file(info, engine: Phoenix.HTML.Engine)
    |> (fn {:safe, contents} -> send_resp(conn, 200, contents) end).()
  end

  defp template_file(page) do
    Path.join([:code.priv_dir(:vintage_net_wizard), "templates", page <> ".eex"])
    # Application.app_dir(:vintage_net_wizard, ["priv", "templates", "#{page}.eex"])
  end

  defp firmware_info() do
    get_all_active_kv()
    |> Enum.filter(fn {k, _v} -> String.starts_with?(k, "nerves_fw_") end)
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp serial_number_info() do
    with boardid_path when not is_nil(boardid_path) <- System.find_executable("boardid"),
         {id, 0} <- System.cmd(boardid_path, []) do
      [serial_number: String.trim(id)]
    else
      _other -> [serial_number: "Unknown"]
    end
  end

  if Mix.target() == :host do
    defp get_all_active_kv() do
      [
        {"nerves_fw_uuid", "30abd1f4-0e87-5ec8-d1c8-425114a21eec"},
        {"nerves_fw_version", "0.1.0"},
        {"nerves_fw_product", "vintage_net_wizard"}
      ]
    end
  else
    defp get_all_active_kv() do
      Nerves.Runtime.KV.get_all_active()
    end
  end
end
