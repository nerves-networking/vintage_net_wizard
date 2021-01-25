defmodule VintageNetWizard.Web.ApiTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias VintageNetWizard.Web.Api
  alias VintageNetWizard.BackendServer

  @opts Api.init([])

  test "get a configuration status" do
    {_conn, status} = run_request(:get, "/configuration/status")
    assert Enum.member?(["not_configured", "good", "bad"], status)
  end

  test "list the access points" do
    {conn, [ap]} = run_request(:get, "/access_points")

    assert ap["ssid"] == "Testing all the things!"
    assert ap["band"] == "wifi_5_ghz"
    assert ap["flags"] == ["wpa2_psk_ccmp", "ess"]
    assert ap["signal_percent"] == 57
    assert ap["channel"] == 149
    assert ap["frequency"] == 5745

    assert conn.status == 200
  end

  test "configure a WPA Personal SSID" do
    json_body =
      Jason.encode!(%{
        key_mgmt: "wpa_psk",
        password: "password"
      })

    {conn, body} =
      run_request(:put, "/fake/configuration", body: json_body, content_type: "application/json")

    assert conn.status == 204
    assert body == ""

    BackendServer.delete_configuration("fake")
  end

  test "configure a WPA Enterprise SSID" do
    json_body =
      Jason.encode!(%{
        key_mgmt: "wpa_eap",
        password: "password",
        user: "user"
      })

    {conn, body} =
      run_request(:put, "/enterprise/configuration",
        body: json_body,
        content_type: "application/json"
      )

    assert conn.status == 204
    assert body == ""

    BackendServer.delete_configuration("enterprise")
  end

  test "errors when a WPA Enterprise is configured with no password" do
    json_body =
      Jason.encode!(%{
        key_mgmt: "wpa_eap",
        user: "user"
      })

    {conn, body} =
      run_request(:put, "/enterprise/configuration",
        body: json_body,
        content_type: "application/json"
      )

    assert conn.status == 400

    assert body == %{
             "error" => "password_required",
             "message" => "A password is required."
           }

    BackendServer.delete_configuration("enterprise")
  end

  test "errors when a WPA Enterprise is configured with no user" do
    json_body =
      Jason.encode!(%{
        key_mgmt: "wpa_eap",
        password: "password"
      })

    {conn, body} =
      run_request(:put, "/enterprise/configuration",
        body: json_body,
        content_type: "application/json"
      )

    assert conn.status == 400

    assert body == %{
             "error" => "user_required",
             "message" => "A user is required."
           }

    BackendServer.delete_configuration("enterprise")
  end

  test "errors when a WPA Personal is configured with no password" do
    :ok = BackendServer.reset()

    json_body =
      Jason.encode!(%{
        key_mgmt: "wpa_psk"
      })

    {conn, body} =
      run_request(:put, "/fake/configuration", body: json_body, content_type: "application/json")

    assert conn.status == 400

    assert body == %{
             "error" => "password_required",
             "message" => "A password is required."
           }
  end

  test "returns error if passed a password is too short" do
    :ok = BackendServer.reset()

    json_body =
      Jason.encode!(%{
        key_mgmt: "wpa_psk",
        password: "asdf"
      })

    {conn, body} =
      run_request(:put, "/fake/configuration", body: json_body, content_type: "application/json")

    assert conn.status == 400

    assert body == %{
             "error" => "password_too_short",
             "message" => "The minimum length for a password is 8."
           }
  end

  test "returns error if passed a password that has invalid characters" do
    :ok = BackendServer.reset()

    json_body =
      Jason.encode!(%{
        key_mgmt: "wpa_psk",
        password: <<1, 2, 3, 4, 5, 6, 7, 8, 9>>
      })

    {conn, body} =
      run_request(:put, "/fake/configuration", body: json_body, content_type: "application/json")

    assert conn.status == 400

    assert body == %{
             "error" => "invalid_characters",
             "message" => "The password provided has invalid characters."
           }
  end

  test "returns error if passed a password is too long" do
    :ok = BackendServer.reset()

    json_body =
      Jason.encode!(%{
        key_mgmt: "wpa_psk",
        password: "12345678901234567890123456789012345678901234567890123456789012345"
      })

    {conn, body} =
      run_request(:put, "/fake/configuration", body: json_body, content_type: "application/json")

    assert conn.status == 400

    assert body == %{
             "error" => "password_too_long",
             "message" => "The maximum length for a password is 63."
           }
  end

  test "update configuration priority order" do
    fake1 = %{ssid: "fake1", psk: "123123123", priority: 1}
    fake2 = %{ssid: "fake2", priority: 2}

    BackendServer.save(fake1)
    BackendServer.save(fake2)

    json_body =
      Jason.encode!([
        "fake2",
        "fake1",
        "Not real"
      ])

    {conn, body} = run_request(:put, "/ssids", body: json_body, content_type: "application/json")

    assert conn.status == 204
    assert body == ""

    fake2ssid = fake2.ssid
    fake1ssid = fake1.ssid

    assert [%{ssid: ^fake2ssid}, %{ssid: ^fake1ssid}] = BackendServer.configurations()

    :ok = BackendServer.reset()
  end

  test "get all the configurations, ensure passwords are not exposed" do
    :ok = BackendServer.reset()
    fake1 = %{ssid: "fake1", psk: "password", priority: 1, key_mgmt: :wpa_psk}
    fake2 = %{ssid: "fake2", psk: "password", priority: 2, key_mgmt: :wpa_psk}

    enterprise = %{
      ssid: "enterprise",
      password: "password",
      user: "user",
      priority: 3,
      key_mgmt: :wpa_eap
    }

    BackendServer.save(fake1)
    BackendServer.save(fake2)
    BackendServer.save(enterprise)

    {conn, body} = run_request(:get, "/configurations")

    assert conn.status == 200

    Enum.each(body, fn
      %{"password" => _} ->
        flunk("Configurations endpoint should not expose passwords")

      %{"key_mgmt" => _, "ssid" => ssid} when ssid in ["fake1", "fake2", "enterprise"] ->
        assert true

      payload ->
        flunk("Configuration endpoint returns bad payload: #{inspect(payload)}")
    end)

    :ok = BackendServer.reset()
  end

  test "delete an SSID configuration" do
    :ok = BackendServer.reset()

    fake1 = %{ssid: "fake1", psk: "password", priority: 1}
    BackendServer.save(fake1)

    {conn, body} = run_request(:delete, "/fake1/configuration")

    assert conn.status == 200
    assert body == ""

    refute Enum.any?(BackendServer.configurations(), &(&1.ssid == fake1.ssid))

    :ok = BackendServer.reset()
  end

  test "404 when trying to apply no configurations" do
    :ok = BackendServer.reset()
    {conn, body} = run_request(:post, "/apply", body: "", content_type: "application/json")

    assert conn.status == 404

    assert body == %{
             "error" => "no_configurations",
             "message" => "Please provide configurations to apply."
           }
  end

  test "apply configurations" do
    :ok = BackendServer.reset()

    fake1 = %{ssid: "fake1", psk: "password", priority: 1}
    BackendServer.save(fake1)

    {conn, body} = run_request(:post, "/apply", body: "", content_type: "application/json")

    assert conn.status == 202
    assert body == ""

    :ok = BackendServer.reset()
  end

  test "completes configuration" do
    :ok = BackendServer.reset()

    fake1 = %{ssid: "fake1", psk: "password", priority: 1}
    BackendServer.save(fake1)

    BackendServer.subscribe()

    {conn, body} = run_request(:get, "/complete")

    # Starts a task to kill the server after delivery
    assert length(Task.Supervisor.children(VintageNetWizard.TaskSupervisor)) == 1

    assert conn.status == 202
    assert body == ""
  end

  defp run_request(method, endpoint, opts \\ []) do
    body = Keyword.get(opts, :body)
    content_type = Keyword.get(opts, :content_type)

    req_conn =
      method
      |> conn(endpoint, body)
      |> maybe_put_content_type(content_type)
      |> Api.call(@opts)

    body = decode_body(req_conn)

    {req_conn, body}
  end

  defp maybe_put_content_type(conn, nil), do: conn

  defp maybe_put_content_type(conn, content_type) do
    put_req_header(conn, "content-type", content_type)
  end

  defp decode_body(conn) do
    case conn.resp_body do
      nil -> ""
      "" -> ""
      json -> Jason.decode!(json)
    end
  end
end
