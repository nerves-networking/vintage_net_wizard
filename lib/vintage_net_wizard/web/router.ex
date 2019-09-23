defmodule VintageNetWizard.Web.Router do
  @moduledoc false

  use Plug.Router
  use Plug.Debugger, otp_app: :vintage_net_wizard

  alias VintageNetWizard.{
    Backend,
    WiFiConfiguration
  }

  plug(Plug.Logger, log: :debug)
  plug(Plug.Static, from: {:vintage_net_wizard, "priv/static"}, at: "/")
  plug(Plug.Parsers, parsers: [Plug.Parsers.URLENCODED, :json], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  get "/" do
    render_page(conn, "index.html",
      configs: Backend.configurations(),
      format_security: &display_security_from_key_mgmt/1
    )
  end

  post "/ssid/:ssid" do
    wifi_config =
      WiFiConfiguration.new(
        ssid,
        password: conn.body_params["password"],
        key_mgmt: :wpa_psk
      )

    :ok = Backend.save(wifi_config)

    redirect(conn, "/")
  end

  get "/ssid/:ssid" do
    render_page(conn, "configure_password.html", ssid: ssid)
  end

  get "/networks" do
    render_page(conn, "networks.html")
  end

  get "/networks/new" do
    render_page(conn, "network_new.html")
  end

  post "/networks/new" do
    case Map.get(conn.body_params, "security") do
      "none" ->
        redirect(conn, "/")

      "wpa" ->
        ssid = Map.get(conn.body_params, "ssid")
        redirect(conn, "/ssid/#{ssid}")
    end
  end

  get "/apply" do
    render_page(conn, "apply.html")
  end

  forward("/api/v1", to: VintageNetWizard.Web.Api)

  match _ do
    send_resp(conn, 404, "oops")
  end

  defp redirect(conn, to) do
    conn
    |> put_resp_header("location", to)
    |> send_resp(302, "")
  end

  defp render_page(conn, page, info \\ []) do
    info = [device_info: Backend.device_info()] ++ info

    page
    |> template_file()
    |> EEx.eval_file(info, engine: Phoenix.HTML.Engine)
    |> (fn {:safe, contents} -> send_resp(conn, 200, contents) end).()
  end

  defp template_file(page) do
    Application.app_dir(:vintage_net_wizard, ["priv", "templates", "#{page}.eex"])
  end

  defp display_security_from_key_mgmt(:none), do: ""
  defp display_security_from_key_mgmt(:wpa_psk), do: "WPA2 Personal"
end
