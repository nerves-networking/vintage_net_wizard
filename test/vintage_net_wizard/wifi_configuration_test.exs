# SPDX-FileCopyrightText: 2019 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetWizard.WiFiConfigurationTest do
  use ExUnit.Case, async: true

  alias VintageNetWizard.WiFiConfiguration

  test "get the :none key_mgmt from NoSecurity config" do
    config = %{ssid: "Free WIFI", key_mgmt: :none}

    assert :none == WiFiConfiguration.get_key_mgmt(config)
  end

  test "get the :wpa_psk key_mgmt from WPAPersonal config" do
    config = %{ssid: "Home", psk: "123123123", key_mgmt: :wpa_psk}

    assert :wpa_psk == WiFiConfiguration.get_key_mgmt(config)
  end

  test "makes the right WiFi from params: NoSecurity" do
    params = %{
      "ssid" => "Free WiFi",
      "key_mgmt" => "none"
    }

    assert {:ok, %{ssid: "Free WiFi", key_mgmt: :none}} =
             WiFiConfiguration.json_to_network_config(params)
  end

  test "makes the right WiFi from params: WPAPersonal" do
    params = %{
      "ssid" => "Home",
      "password" => "123123123",
      "key_mgmt" => "wpa_psk"
    }

    assert {:ok, %{ssid: "Home", psk: "123123123", key_mgmt: :wpa_psk}} =
             WiFiConfiguration.json_to_network_config(params)
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
      assert "None" == WiFiConfiguration.security_name(%{key_mgmt: :none})
    end

    test "WPAPersonal" do
      assert "WPA Personal" == WiFiConfiguration.security_name(%{key_mgmt: :wpa_psk})
    end

    test "PEAPEnterprise" do
      assert "WPA Enterprise" == WiFiConfiguration.security_name(%{key_mgmt: :wpa_eap})
    end
  end

  describe "get expected timeouts" do
    test "NoSecurity" do
      assert 30_000 == WiFiConfiguration.timeout(%{key_mgmt: :none})
    end

    test "WPAPersonal" do
      assert 30_000 == WiFiConfiguration.timeout(%{key_mgmt: :wpa_psk})
    end

    test "PEAPEnterprise" do
      assert 75_000 == WiFiConfiguration.timeout(%{key_mgmt: :wpa_eap})
    end
  end
end
