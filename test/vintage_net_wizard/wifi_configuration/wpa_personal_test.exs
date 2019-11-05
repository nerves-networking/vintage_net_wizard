defmodule VintageNetWizard.WiFiConfiguration.WPAPersonalTest do
  use ExUnit.Case, async: true

  alias VintageNetWizard.WiFiConfiguration.WPAPersonal

  test "makes a configuration from good params" do
    config = %WPAPersonal{ssid: "Home", psk: "123123123"}

    assert {:ok, ^config} =
             WPAPersonal.from_params(%{"ssid" => config.ssid, "password" => config.psk})
  end

  test "make a configuration from too short password" do
    params = %{"ssid" => "Home", "password" => "123"}

    assert {:error, :password_too_short} == WPAPersonal.from_params(params)
  end

  test "make a configuration from too long password" do
    params = %{
      "ssid" => "Home",
      "password" => "12345678901234567890123456789012345678901234567890123456789012345"
    }

    assert {:error, :password_too_long} == WPAPersonal.from_params(params)
  end

  test "make a configuration from invalid password" do
    params = %{
      "ssid" => "Home",
      "password" => <<1, 2, 3, 4, 5, 6, 7, 8>>
    }

    assert {:error, :invalid_characters} == WPAPersonal.from_params(params)
  end

  test "generates a configuration for vintage net no priority" do
    config = %WPAPersonal{ssid: "Home", psk: "123123123"}

    expected_vintage_net_config = %{
      ssid: config.ssid,
      key_mgmt: :wpa_psk,
      psk: config.psk,
      mode: :infrastructure
    }

    assert expected_vintage_net_config == WPAPersonal.to_vintage_net_configuration(config)
  end

  test "generates a configuration for vintage net with a priority" do
    config = %WPAPersonal{ssid: "Home", psk: "123123123", priority: 1}

    expected_vintage_net_config = %{
      ssid: config.ssid,
      key_mgmt: :wpa_psk,
      psk: config.psk,
      mode: :infrastructure,
      priority: 1
    }

    assert expected_vintage_net_config == WPAPersonal.to_vintage_net_configuration(config)
  end

  test "can be made into JSON" do
    config = %WPAPersonal{ssid: "home", psk: "password"}

    json = "{\"key_mgmt\":\"wpa_psk\",\"ssid\":\"home\"}"

    assert {:ok, json} == Jason.encode(config)
  end
end
