defmodule VintageNetWizard.WiFiConfigurationTest do
  use ExUnit.Case, async: true

  alias VintageNetWizard.WiFiConfiguration

  test "decode json" do
    json = """
    { "ssid": "test", "key_mgmt": "wpa_psk", "password": "asdf"}
    """

    result = WiFiConfiguration.new("test", key_mgmt: :wpa_psk, password: "asdf")

    assert {:ok, result} == WiFiConfiguration.decode(json)
  end

  test "take a map and turn it into a WiFiConfiguration" do
    map = %{
      "ssid" => "Hello",
      "key_mgmt" => "wpa_psk"
    }

    wifi_configuration = WiFiConfiguration.new("Hello", key_mgmt: :wpa_psk)

    assert {:ok, wifi_configuration} == WiFiConfiguration.from_map(map)
  end

  test "return error when invalid key_mgmt" do
    invalid_key_mgmt = "blue"

    map = %{
      "ssid" => "Hello",
      "key_mgmt" => invalid_key_mgmt
    }

    assert {:error, :invalid_key_mgmt, invalid_key_mgmt} == WiFiConfiguration.from_map(map)
  end

  test "from_map accepts a password too" do
    map = %{
      "ssid" => "Hello",
      "password" => "asdf",
      "key_mgmt" => "wpa_psk"
    }

    {:ok, wifi_configuration} = WiFiConfiguration.from_map(map)

    assert map["password"] == wifi_configuration.password
  end

  test "make a vintage_net configuration from a WiFiConfiguration" do
    wifi_configuration = WiFiConfiguration.new("Hello", password: "asdf", key_mgmt: :wpa_psk)

    expected_result = %{
      ssid: wifi_configuration.ssid,
      psk: wifi_configuration.password,
      key_mgmt: wifi_configuration.key_mgmt,
      mode: :client
    }

    assert expected_result == WiFiConfiguration.to_vintage_net_configuration(wifi_configuration)
  end

  test "make a vintage_net configuration when there is no password" do
    wifi_configuration = WiFiConfiguration.new("Hello", key_mgmt: :none)

    expected_result = %{
      ssid: wifi_configuration.ssid,
      key_mgmt: wifi_configuration.key_mgmt,
      mode: :client
    }

    assert expected_result == WiFiConfiguration.to_vintage_net_configuration(wifi_configuration)
  end
end
