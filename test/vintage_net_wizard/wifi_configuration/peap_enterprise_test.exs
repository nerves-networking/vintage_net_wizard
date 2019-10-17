defmodule VintageNetWizard.WiFiConfiguration.PEAPEnterpriseTest do
  use ExUnit.Case, async: true

  alias VintageNetWizard.WiFiConfiguration.PEAPEnterprise

  test "makes a configuration from good params" do
    config = %PEAPEnterprise{ssid: "Enterprise", password: "123123123", user: "user"}

    assert {:ok, ^config} =
             PEAPEnterprise.from_params(%{
               "ssid" => config.ssid,
               "password" => config.password,
               "user" => config.user
             })
  end

  test "wont make a configuration from params with no password" do
    assert {:error, :password_required} ==
             PEAPEnterprise.from_params(%{
               "ssid" => "Enterprise",
               "user" => "user"
             })
  end

  test "wont make a configuration from params with no user" do
    assert {:error, :user_required} ==
             PEAPEnterprise.from_params(%{
               "ssid" => "Enterprise",
               "password" => "password"
             })
  end

  test "generates a configuration for vintage net no priority" do
    config = %PEAPEnterprise{ssid: "Enterprise", password: "123123123", user: "user"}

    expected_vintage_net_config = %{
      mode: :client,
      key_mgmt: :wpa_eap,
      eap: "PEAP",
      phase2: "auth=MSCHAPV2",
      ssid: config.ssid,
      identity: config.user,
      password: config.password
    }

    assert expected_vintage_net_config == PEAPEnterprise.to_vintage_net_configuration(config)
  end

  test "generates a configuration for vintage net with a priority" do
    config = %PEAPEnterprise{ssid: "Enterprise", password: "123123123", user: "user", priority: 1}

    expected_vintage_net_config = %{
      mode: :client,
      key_mgmt: :wpa_eap,
      eap: "PEAP",
      phase2: "auth=MSCHAPV2",
      ssid: config.ssid,
      identity: config.user,
      password: config.password,
      priority: 1
    }

    assert expected_vintage_net_config == PEAPEnterprise.to_vintage_net_configuration(config)
  end

  test "can be made into JSON" do
    config = %PEAPEnterprise{ssid: "Enterprise", password: "password", user: "user"}

    json = "{\"key_mgmt\":\"wpa_eap\",\"ssid\":\"Enterprise\"}"

    assert {:ok, json} == Jason.encode(config)
  end
end
