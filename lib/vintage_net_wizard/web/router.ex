defmodule VintageNetWizard.Web.Router do
  @moduledoc false


  use Plug.Router
  use Plug.Debugger, otp_app: :vintage_net_wizard
  import Logger

  # import Plug.BasicAuth
  # plug :basic_auth, username: "admin", password: "adminadmin"

  plug :auth

  alias VintageNetWizard.{
    BackendServer,
    Web.Endpoint,
    WiFiConfiguration
  }

  plug(Plug.Static, from: {:vintage_net_wizard, "priv/static"}, at: "/")
  plug(Plug.Parsers, parsers: [Plug.Parsers.URLENCODED, :json], json_decoder: Jason)
  # This route is polled by the front end to update its list of access points.
  # This can mean the user could potentially have the page open without knowing
  # it just polling this endpoint but still be inactive.
  plug(VintageNetWizard.Plugs.Activity, excluding: ["/api/v1/access_points"])
  plug(:match)
  plug(:dispatch, builder_opts())

  ## Plug Auth usgin Plug.BasicAuth custom
  defp auth(conn, _opts) do
    with {user, pass} <- Plug.BasicAuth.parse_basic_auth(conn) do
      ##process to authorize
      #Logger.info("Authorizing #{user} with #{pass}")
      assign(conn, :current_user, :admin)
    else
      _ -> conn |> Plug.BasicAuth.request_basic_auth() |> halt()
    end
  end

  get "/" do
    case BackendServer.configurations() do
      [] ->
        redirect(conn, "/networks")

      configs ->
        render_page(conn, "index.html", opts,
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

    case WiFiConfiguration.json_to_network_config(params) do
      {:ok, wifi_config} ->
        :ok = BackendServer.save(wifi_config)
        redirect(conn, "/")

      error ->
        {:ok, key_mgmt} = WiFiConfiguration.key_mgmt_from_string(conn.body_params["key_mgmt"])
        error_message = password_error_message(error)

        render_password_page(conn, key_mgmt, opts,
          ssid: ssid,
          error: error_message,
          password: password,
          user: conn.body_params["user"]
        )
    end
  end

  get "/ssid/:ssid" do

      key_mgmt =
                case BackendServer.access_points()
                     |> Enum.find(&(&1.ssid == ssid)) do
                  nil ->    BackendServer.configurations()
                            |> Enum.find(&(&1.ssid == ssid))
                            |> Map.get(:key_mgmt)
                  result -> get_key_mgmt_from_ap(result)
                end

    render_password_page(conn, key_mgmt, opts, ssid: ssid, password: "", error: "", user: "")
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
    render_page(conn, "apple_captive_portal.html", opts, dns_name: get_redirect_dnsname(conn))
  end

  get "/library/test/success.html" do
    render_page(conn, "apple_captive_portal.html", opts, dns_name: get_redirect_dnsname(conn))
  end

  get "/networks" do
    config = configuration_status_details()
    render_page(conn, "networks.html", opts, configuration_status: config)
  end

  get "/networks/new" do
    render_page(conn, "network_new.html", opts)
  end

  post "/networks/new" do
    ssid = Map.get(conn.body_params, "ssid")

    case Map.get(conn.body_params, "key_mgmt") do
      "none" ->
        {:ok, config} = WiFiConfiguration.json_to_network_config(conn.body_params)
        :ok = BackendServer.save(config)

        redirect(conn, "/")

      key_mgmt ->
        key_mgmt = String.to_existing_atom(key_mgmt)
        render_password_page(conn, key_mgmt, opts, ssid: ssid, password: "", error: "", user: "")
    end
  end

  get "/apply" do
    render_page(conn, "apply.html", opts, ssid: VintageNetWizard.APMode.ssid())
  end

  get "/complete" do
    #:ok = BackendServer.complete()

    _ =
      Task.Supervisor.start_child(VintageNetWizard.TaskSupervisor, fn ->
        # We don't want to stop the server before we
        # send the response back.
        :timer.sleep(3000)
        #Endpoint.stop_server(:shutdown)
      end)

    render_page(conn, "complete.html", opts)
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

  defp render_page(conn, page, opts, info \\ []) do
    info = [device_info: BackendServer.device_info(), ui: get_ui_config(opts)] ++ info
    resp =
      page
      |> template_file()
      |> EEx.eval_file(info, engine: Phoenix.HTML.Engine)
      # credo:disable-for-next-line
      |> Phoenix.HTML.Engine.encode_to_iodata!()

    send_resp(conn, 200, resp)
  end

  defp get_ui_config(opts) do
    default_ui_config = %{
      title: "Intuitivo Setup",
      title_color: "#11151A",
      button_color: "#007bff"
    }

    ui =
      opts
      |> Keyword.get(:ui, [])
      |> Enum.into(%{})

    Map.merge(default_ui_config, ui)
  end

  defp render_password_page(conn, :wpa_psk, opts, info) do
    render_page(conn, "configure_password.html", opts, info)
  end

  defp render_password_page(conn, :wpa_eap, opts, info) do
    render_page(conn, "configure_enterprise.html", opts, info)
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
      :psk in flags ->
        :wpa_psk

      :eap in flags ->
        :wpa_eap

      true ->
        :none
    end
  end

  defp configuration_status_details() do
    case BackendServer.configuration_status() do
      :good ->
        %{
          value: "Working",
          class: "text-success",
          title: "Device successfully connected to a network in the applied configuration"
        }

      :bad ->
        %{
          value: "Not Working",
          class: "text-danger",
          title:
            "Device was unable to connect to any network in the configuration due to bad password or a timeout while attempting."
        }

      :not_configured ->
        %{
          value: "Not configured yet",
          class: "text-warning",
          title: "Device waiting to be configured."
        }
    end
  end
end
