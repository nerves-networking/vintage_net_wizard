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
    case Backend.configurations() do
      [] ->
        redirect(conn, "/networks")

      configs ->
        render_page(conn, "index.html",
          configs: configs,
          format_security: &display_security_from_key_mgmt/1
        )
    end
  end

  post "/ssid/:ssid" do
    password = conn.body_params["password"]

    wifi_config =
      WiFiConfiguration.new(
        ssid,
        password: password,
        key_mgmt: :wpa_psk
      )

    case WiFiConfiguration.validate_password(wifi_config) do
      :ok ->
        :ok = Backend.save(wifi_config)
        redirect(conn, "/")

      error ->
        render_page(conn, "configure_password.html",
          ssid: ssid,
          error: password_error_message(error),
          password: password
        )
    end
  end

  get "/ssid/:ssid" do
    render_page(conn, "configure_password.html", ssid: ssid, password: "", error: "")
  end

  get "/networks" do
    render_page(conn, "networks.html")
  end

  get "/networks/new" do
    render_page(conn, "network_new.html")
  end

  post "/networks/new" do
    ssid = Map.get(conn.body_params, "ssid")

    case Map.get(conn.body_params, "security") do
      "none" ->
        :ok =
          ssid
          |> WiFiConfiguration.new(key_mgmt: :none)
          |> Backend.save()

        redirect(conn, "/")

      "wpa" ->
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

  defp display_security_from_key_mgmt(:none), do: "None"
  defp display_security_from_key_mgmt(:wpa_psk), do: "WPA2 Personal"
  defp display_security_from_key_mgmt(:wpa_eap), do: "WPA Enterprise"

  defp password_error_message({:error, :password_required, _}), do: "Password required."

  defp password_error_message({:error, :password_too_short}),
    do: "Password is too short, must be greater than or equal to 8 characters."

  defp password_error_message({:error, :password_too_long}),
    do: "Password is too short, must be greater than or equal to 8 characters."

  defp password_error_message({:error, :invalid_characters}),
    do: "Password as invalid characters double check you typed it correctly."
end
