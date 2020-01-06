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
          configuration_status: configuration_status_details(),
          format_security: &WiFiConfiguration.security_name/1,
          get_key_mgmt: &WiFiConfiguration.get_key_mgmt/1
        )
    end
  end

  post "/ssid/:ssid" do
    password = conn.body_params["password"]
    params = Map.put(conn.body_params, "ssid", ssid)

    case WiFiConfiguration.from_params(params) do
      {:ok, wifi_config} ->
        :ok = Backend.save(wifi_config)
        redirect(conn, "/")

      error ->
        {:ok, key_mgmt} = WiFiConfiguration.key_mgmt_from_string(conn.body_params["key_mgmt"])
        error_message = password_error_message(error)

        render_password_page(conn, key_mgmt,
          ssid: ssid,
          error: error_message,
          password: password,
          user: conn.body_params["user"]
        )
    end
  end

  get "/ssid/:ssid" do
    key_mgmt =
      Backend.access_points()
      |> Enum.find(&(&1.ssid == ssid))
      |> get_key_mgmt_from_ap()

    render_password_page(conn, key_mgmt, ssid: ssid, password: "", error: "", user: "")
  end

  get "/networks" do
    render_page(conn, "networks.html", configuration_status: configuration_status_details())
  end

  get "/networks/new" do
    render_page(conn, "network_new.html")
  end

  post "/networks/new" do
    ssid = Map.get(conn.body_params, "ssid")

    case Map.get(conn.body_params, "security") do
      "none" ->
        {:ok, config} = WiFiConfiguration.from_params(conn.body_params)
        :ok = Backend.save(config)

        redirect(conn, "/")

      "wpa_psk" ->
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

  defp render_password_page(conn, :wpa_psk, info) do
    render_page(conn, "configure_password.html", info)
  end

  defp render_password_page(conn, :wpa_eap, info) do
    render_page(conn, "configure_enterprise.html", info)
  end

  defp template_file(page) do
    Application.app_dir(:vintage_net_wizard, ["priv", "templates", "#{page}.eex"])
  end

  defp password_error_message({:error, :password_required}), do: "Password required."

  defp password_error_message({:error, :password_too_short}),
    do: "Password is too short, must be greater than or equal to 8 characters."

  defp password_error_message({:error, :password_too_long}),
    do: "Password is too long, must be less than or equal to 64 characters."

  defp password_error_message({:error, :invalid_characters}),
    do: "Password as invalid characters double check you typed it correctly."

  defp get_key_mgmt_from_ap(%{flags: []}) do
    :none
  end

  defp get_key_mgmt_from_ap(%{flags: flags}) do
    cond do
      :wpa2_eap_ccmp in flags ->
        :wpa_eap

      :wpa2_psk_ccmp in flags ->
        :wpa_psk

      :wpa2_psk_ccmp_tkip in flags ->
        :wpa_psk

      :wpa_psk_ccmp_tkip in flags ->
        :wpa_psk

      true ->
        :none
    end
  end

  defp configuration_status_details() do
    case status = Backend.configuration_status() do
      :good ->
        %{
          value: status,
          class: "text-success",
          title: "Device successfully connected to a network in the applied configuration"
        }

      :bad ->
        %{
          value: status,
          class: "text-danger",
          title:
            "Device was unable to connect to any network in the configuration due to bad password or a timeout while attempting."
        }

      _ ->
        %{value: status, class: "text-warning", title: "Device waiting to be configured."}
    end
  end
end
