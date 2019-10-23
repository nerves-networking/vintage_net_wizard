defmodule VintageNetWizard.Web.ApiTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias VintageNetWizard.Web.Api
  alias VintageNetWizard.Backend
  alias VintageNetWizard.WiFiConfiguration.{WPAPersonal, NoSecurity}

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

  test "configure an SSID" do
    json_body =
      Jason.encode!(%{
        key_mgmt: "wpa_psk",
        password: "password"
      })

    {conn, body} =
      run_request(:put, "/fake/configuration", body: json_body, content_type: "application/json")

    assert conn.status == 204
    assert body == ""

    Backend.delete_configuration("fake")
  end

  test "returns error if passed a password is required" do
    :ok = Backend.reset()

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
    :ok = Backend.reset()

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
    :ok = Backend.reset()

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
    :ok = Backend.reset()

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
    fake1 = %WPAPersonal{ssid: "fake1", psk: "123123123", priority: 1}
    fake2 = %NoSecurity{ssid: "fake2", priority: 2}

    Backend.save(fake1)
    Backend.save(fake2)

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

    assert [%NoSecurity{ssid: ^fake2ssid}, %WPAPersonal{ssid: ^fake1ssid}] =
             Backend.configurations()

    :ok = Backend.reset()
  end

  test "get all the configurations, ensure passwords are not exposed" do
    :ok = Backend.reset()
    fake1 = %WPAPersonal{ssid: "fake1", psk: "password", priority: 1}
    fake2 = %WPAPersonal{ssid: "fake2", psk: "password", priority: 2}

    Backend.save(fake1)
    Backend.save(fake2)

    {conn, body} = run_request(:get, "/configurations")

    assert conn.status == 200

    Enum.each(body, fn
      %{"password" => _} -> flunk("Configurations endpoint should not expose passwords")
      %{"key_mgmt" => _, "ssid" => ssid} when ssid in ["fake1", "fake2"] -> assert true
      payload -> flunk("Configuration endpoint returns bad payload: #{inspect(payload)}")
    end)

    :ok = Backend.reset()
  end

  test "delete an SSID configuration" do
    :ok = Backend.reset()

    fake1 = %WPAPersonal{ssid: "fake1", psk: "password", priority: 1}
    Backend.save(fake1)

    {conn, body} = run_request(:delete, "/fake1/configuration")

    assert conn.status == 200
    assert body == ""

    refute Enum.any?(Backend.configurations(), &(&1.ssid == fake1.ssid))

    :ok = Backend.reset()
  end

  test "404 when trying to apply no configurations" do
    :ok = Backend.reset()
    {conn, body} = run_request(:post, "/apply", body: "", content_type: "application/json")

    assert conn.status == 404

    assert body == %{
             "error" => "no_configurations",
             "message" => "Please provide configurations to apply."
           }
  end

  test "apply configurations" do
    :ok = Backend.reset()

    fake1 = %WPAPersonal{ssid: "fake1", psk: "password", priority: 1}
    Backend.save(fake1)

    {conn, body} = run_request(:post, "/apply", body: "", content_type: "application/json")

    assert conn.status == 202
    assert body == ""

    :ok = Backend.reset()
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
      "" -> ""
      json -> Jason.decode!(json)
    end
  end
end
