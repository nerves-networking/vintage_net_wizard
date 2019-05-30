defmodule VintageNet.Wizard.Web.Router do
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

  match _ do
    send_resp(conn, 404, "oops")
  end

  defp render_page(conn, page, info \\ []) do
    page
    |> template_file()
    |> EEx.eval_file(info, engine: Phoenix.HTML.Engine)
    |> (fn {:safe, contents} -> send_resp(conn, 200, contents) end).()
  rescue
    e -> send_resp(conn, 500, "Failed to render page: #{page} inspect: #{Exception.message(e)}")
  end

  defp template_file(page) do
    Path.join([:code.priv_dir(:vintage_net_wizard), "templates", "#{page}.eex"])
    # Application.app_dir(:vintage_net_wizard, ["priv", "templates", "#{page}.eex"])
  end
end
