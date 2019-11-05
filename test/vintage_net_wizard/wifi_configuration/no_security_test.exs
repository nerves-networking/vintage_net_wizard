defmodule VintageNetWizard.WiFiConfiguration.NoSecurityTest do
  use ExUnit.Case

  alias VintageNetWizard.WiFiConfiguration.NoSecurity

  test "makes a configuration from params" do
    config = %NoSecurity{ssid: "Free WIFI!"}

    assert {:ok, ^config} = NoSecurity.from_params(%{"ssid" => config.ssid})
  end

  test "generates a configuration for vintage net no priority" do
    config = %NoSecurity{ssid: "Free WIFI!"}

    expected_vintage_net_config = %{
      ssid: config.ssid,
      key_mgmt: :none,
      mode: :infrastructure
    }

    assert expected_vintage_net_config == NoSecurity.to_vintage_net_configuration(config)
  end

  test "generates a configuration for vintage net with a priority" do
    config = %NoSecurity{ssid: "Free WIFI!", priority: 1}

    expected_vintage_net_config = %{
      ssid: config.ssid,
      key_mgmt: :none,
      mode: :infrastructure,
      priority: 1
    }

    assert expected_vintage_net_config == NoSecurity.to_vintage_net_configuration(config)
  end

  test "can be made into JSON" do
    config = %NoSecurity{ssid: "Free WIFI!"}

    json = "{\"key_mgmt\":\"none\",\"ssid\":\"Free WIFI!\"}"

    assert {:ok, json} == Jason.encode(config)
  end
end
