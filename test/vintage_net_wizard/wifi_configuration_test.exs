defmodule VintageNetWizard.WiFiConfigurationTest do
  use ExUnit.Case, async: true

  alias VintageNetWizard.WiFiConfiguration

  @too_long "12345678901234567890123456789012345678901234567890123456789012345"
  @too_short "1234"
  @invalid_characters <<1, 2, 3, 4, 5, 6, 7, 8>>

  test "decode json" do
    json = """
    { "ssid": "test", "key_mgmt": "wpa_psk", "password": "secret12"}
    """

    result = WiFiConfiguration.new("test", key_mgmt: :wpa_psk, password: "secret12")

    assert {:ok, result} == WiFiConfiguration.decode(json)
  end

  test "password validation" do
    assert {:error, :password_too_short} ==
             WiFiConfiguration.new("hello", key_mgmt: :wpa_psk, password: @too_short)
             |> WiFiConfiguration.validate_password()

    assert {:error, :password_too_long} ==
             WiFiConfiguration.new("hello",
               key_mgmt: :wpa_psk,
               password: @too_long
             )
             |> WiFiConfiguration.validate_password()

    assert {:error, :invalid_characters} ==
             WiFiConfiguration.new("hello",
               key_mgmt: :wpa_psk,
               password: @invalid_characters
             )
             |> WiFiConfiguration.validate_password()

    assert {:error, :password_required, :wpa_psk} ==
             WiFiConfiguration.new("hello", key_mgmt: :wpa_psk)
             |> WiFiConfiguration.validate_password()
  end

  test "take a map and turn it into a WiFiConfiguration" do
    map = %{
      "ssid" => "Hello",
      "key_mgmt" => "wpa_psk",
      "password" => "secret12"
    }

    wifi_configuration = WiFiConfiguration.new("Hello", key_mgmt: :wpa_psk, password: "secret12")

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
      "password" => "secret12",
      "key_mgmt" => "wpa_psk"
    }

    {:ok, wifi_configuration} = WiFiConfiguration.from_map(map)

    assert map["password"] == wifi_configuration.password
  end

  test "from_map errors when there is an invalid password" do
    map = %{
      "ssid" => "Hello",
      "password" => "",
      "key_mgmt" => "wpa_psk"
    }

    assert {:error, :password_too_short} == WiFiConfiguration.from_map(map)

    map =
      Map.put(
        map,
        "password",
        @too_long
      )

    assert {:error, :password_too_long} = WiFiConfiguration.from_map(map)

    map = Map.put(map, "password", @invalid_characters)

    assert {:error, :invalid_characters} == WiFiConfiguration.from_map(map)
  end

  test "make a vintage_net configuration from a WiFiConfiguration" do
    wifi_configuration = WiFiConfiguration.new("Hello", password: "secret12", key_mgmt: :wpa_psk)

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

  test "don't make a vintage_net configuration with a too long password" do
    configuration_wifi =
      struct(WiFiConfiguration,
        ssid: "hello",
        password: @too_long,
        key_mgmt: :wpa_psk
      )

    assert {:error, :password_too_long} ==
             WiFiConfiguration.to_vintage_net_configuration(configuration_wifi)
  end

  test "don't make a vintage_net configuration with a too short password" do
    configuration_wifi =
      struct(WiFiConfiguration, ssid: "hello", password: @too_short, key_mgmt: :wpa_psk)

    assert {:error, :password_too_short} ==
             WiFiConfiguration.to_vintage_net_configuration(configuration_wifi)
  end

  test "don't make a vintage_net configuration with invalid characters in the password" do
    configuration_wifi =
      struct(WiFiConfiguration,
        ssid: "hello",
        password: @invalid_characters,
        key_mgmt: :wpa_psk
      )

    assert {:error, :invalid_characters} ==
             WiFiConfiguration.to_vintage_net_configuration(configuration_wifi)
  end

  test "don't make a vintage_net configuration when a password is required" do
    configuration_wifi =
      struct(WiFiConfiguration,
        ssid: "hello",
        key_mgmt: :wpa_psk
      )

    assert {:error, :password_required, :wpa_psk} ==
             WiFiConfiguration.to_vintage_net_configuration(configuration_wifi)
  end
end
