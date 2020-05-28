defmodule VintageNetWizard.Web.Router do
  @moduledoc false

  use Plug.Router
  use Plug.Debugger, otp_app: :vintage_net_wizard

  alias VintageNetWizard.{
    BackendServer,
    Callbacks,
    WiFiConfiguration
  }

  plug(Plug.Logger, log: :debug)
  plug(Plug.Static, from: {:vintage_net_wizard, "priv/static"}, at: "/")
  plug(Plug.Parsers, parsers: [Plug.Parsers.URLENCODED, :json], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  get "/" do
    case BackendServer.configurations() do
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
        :ok = BackendServer.save(wifi_config)
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
      BackendServer.access_points()
      |> Enum.find(&(&1.ssid == ssid))
      |> get_key_mgmt_from_ap()

    render_password_page(conn, key_mgmt, ssid: ssid, password: "", error: "", user: "")
  end

  get "/redirect" do
    redirect_with_dnsname(conn)
  end

  get "/ncsi.txt" do
    redirect_with_dnsname(conn)
  end

  get "/connecttest.txt" do
    redirect_with_dnsname(conn)
  end

  get "/generate_204" do
    redirect_with_dnsname(conn)
  end

  get "/hotspot-detect.html" do
    render_page(conn, "apple_captive_portal.html", dns_name: get_redirect_dnsname(conn))
  end

  get "/library/test/success.html" do
    render_page(conn, "apple_captive_portal.html", dns_name: get_redirect_dnsname(conn))
  end

  get "/networks" do
    render_page(conn, "networks.html", configuration_status: configuration_status_details())
  end

  get "/networks/new" do
    render_page(conn, "network_new.html")
  end

  post "/networks/new" do
    ssid = Map.get(conn.body_params, "ssid")

    case Map.get(conn.body_params, "key_mgmt") do
      "none" ->
        {:ok, config} = WiFiConfiguration.from_params(conn.body_params)
        :ok = BackendServer.save(config)
        redirect(conn, "/")

      key_mgmt ->
        key_mgmt = String.to_existing_atom(key_mgmt)
        render_password_page(conn, key_mgmt, ssid: ssid, password: "", error: "", user: "")
    end
  end

  get "/apply" do
    render_page(conn, "apply.html", ssid: VintageNetWizard.APMode.ssid())
  end

  get "/complete" do
    :ok = BackendServer.complete()

    _ = Callbacks.on_complete()

    render_page(conn, "complete.html")
  end

  forward("/api/v1", to: VintageNetWizard.Web.Api)

  match _ do
    send_resp(conn, 404, "oops")
  end

  defp redirect_with_dnsname(conn) do
    conn
    |> put_resp_header("location", get_redirect_dnsname(conn))
    |> send_resp(302, "")
  end

  defp get_redirect_dnsname(conn, to \\ nil) do
    dns_name = Application.get_env(:vintage_net_wizard, :dns_name, "wifi.config")

    port = if conn.port != 80 and conn.port != 443, do: ":#{conn.port}", else: ""

    "#{conn.scheme}://#{dns_name}#{port}#{to}"
  end

  defp redirect(conn, to) do
    conn
    |> put_resp_header("location", to)
    |> send_resp(302, "")
  end

  defp render_page(conn, page, info \\ []) do
    info = [device_info: BackendServer.device_info()] ++ info

    resp =
      page
      |> template_file()
      |> EEx.eval_file(info, engine: Phoenix.HTML.Engine)
      |> Phoenix.HTML.Engine.encode_to_iodata!()

    send_resp(conn, 200, resp)
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
    case status = BackendServer.configuration_status() do
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
