defmodule VintageNetWizard.WiFiConfigurationTest do
  use ExUnit.Case, async: true

  alias VintageNetWizard.WiFiConfiguration
  alias VintageNetWizard.WiFiConfiguration.{NoSecurity, WPAPersonal, PEAPEnterprise}

  test "get the :none key_mgmt from NoSecurity config" do
    config = %NoSecurity{ssid: "Free WIFI"}

    assert :none == WiFiConfiguration.get_key_mgmt(config)
  end

  test "get the :wpa_psk key_mgmt from WPAPersonal config" do
    config = %WPAPersonal{ssid: "Home", psk: "123123123"}

    assert :wpa_psk == WiFiConfiguration.get_key_mgmt(config)
  end

  test "makes the right WiFi from params: NoSecurity" do
    params = %{
      "ssid" => "Free WiFi",
      "key_mgmt" => "none"
    }

    assert {:ok, %NoSecurity{}} = WiFiConfiguration.from_params(params)
  end

  test "makes the right WiFi from params: WPAPersonal" do
    params = %{
      "ssid" => "Home",
      "password" => "123123123",
      "key_mgmt" => "wpa_psk"
    }

    assert {:ok, %WPAPersonal{}} = WiFiConfiguration.from_params(params)
  end

  test "supports no security wifi config to be made into a vintage net config" do
    config = %NoSecurity{ssid: "Free WIFI!", priority: 1}

    expected_vintage_net_config = %{
      ssid: config.ssid,
      key_mgmt: :none,
      mode: :infrastructure,
      priority: 1
    }

    assert expected_vintage_net_config == WiFiConfiguration.to_vintage_net_configuration(config)
  end

  test "supports wpa personal wifi config to be made into a vintage net config" do
    config = %WPAPersonal{ssid: "Home", priority: 1, psk: "password"}

    expected_vintage_net_config = %{
      ssid: config.ssid,
      key_mgmt: :wpa_psk,
      mode: :infrastructure,
      psk: config.psk,
      priority: 1
    }

    assert expected_vintage_net_config == WiFiConfiguration.to_vintage_net_configuration(config)
  end

  describe "Get a key_mgmt from a string" do
    test "wpa_eap" do
      assert {:ok, :wpa_eap} == WiFiConfiguration.key_mgmt_from_string("wpa_eap")
    end

    test "wpa_psk" do
      assert {:ok, :wpa_psk} == WiFiConfiguration.key_mgmt_from_string("wpa_psk")
    end

    test "none" do
      assert {:ok, :none} == WiFiConfiguration.key_mgmt_from_string("none")
    end

    test "invalid" do
      assert {:error, :invalid_key_mgmt} == WiFiConfiguration.key_mgmt_from_string("blue")
    end
  end

  describe "Get a human friendly name from a particular WiFiConfiguration" do
    test "NoSecurity" do
      assert "None" == WiFiConfiguration.security_name(%NoSecurity{})
    end

    test "WPAPersonal" do
      assert "WPA Personal" == WiFiConfiguration.security_name(%WPAPersonal{})
    end

    test "PEAPEnterprise" do
      assert "WPA Enterprise" == WiFiConfiguration.security_name(%PEAPEnterprise{})
    end
  end

  describe "get expected timeouts" do
    test "NoSecurity" do
      assert 30_000 == WiFiConfiguration.timeout(%NoSecurity{})
    end

    test "WPAPersonal" do
      assert 30_000 == WiFiConfiguration.timeout(%WPAPersonal{})
    end

    test "PEAPEnterprise" do
      assert 75_000 == WiFiConfiguration.timeout(%PEAPEnterprise{})
    end
  end
end
