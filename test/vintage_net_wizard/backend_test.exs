defmodule VintageNetWizard.Backend.Test do
  use ExUnit.Case, async: true

  alias VintageNetWizard.{WiFiConfiguration, Backend}

  test "Can save a WiFi configuration" do
    :ok = Backend.reset()

    configuration =
      WiFiConfiguration.new("Test Network", key_mgmt: :wpa_psk, password: "12341234")

    :ok = Backend.save(configuration)

    assert [configuration] == Backend.configurations()
  end

  test "sets the priority order of configurations" do
    :ok = Backend.reset()

    configuration1 =
      WiFiConfiguration.new("Test Network", key_mgmt: :wpa_psk, password: "12341234")

    configuration2 =
      WiFiConfiguration.new("Test Network 2", key_mgmt: :wpa_psk, password: "12341234")

    :ok = Backend.save(configuration1)
    :ok = Backend.save(configuration2)

    :ok = Backend.set_priority_order([configuration2.ssid, configuration1.ssid])

    [c2, c1] = Backend.configurations()

    assert c2.ssid == configuration2.ssid
    assert c2.priority == 1

    assert c1.ssid == configuration1.ssid
    assert c1.priority == 2

    :ok = Backend.reset()
  end

  test "delete a configuration" do
    :ok = Backend.reset()
    configuration = WiFiConfiguration.new("Drop Me", key_mgmt: :wpa_psk, password: "12341234")
    :ok = Backend.save(configuration)

    assert [configuration] == Backend.configurations()
    assert :ok == Backend.delete_configuration(configuration.ssid)

    assert [] == Backend.configurations()
  end

  test "don't apply when there are no configurations" do
    :ok = Backend.reset()

    [] = Backend.configurations()

    assert {:error, :no_configurations} = Backend.apply()
  end
end
