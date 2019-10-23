defmodule VintageNetWizard.Backend.Test do
  use ExUnit.Case, async: true

  alias VintageNetWizard.Backend
  alias VintageNetWizard.WiFiConfiguration.WPAPersonal

  test "Can save a WiFi configuration" do
    :ok = Backend.reset()

    configuration = %WPAPersonal{ssid: "Test Network", psk: "12341234"}

    :ok = Backend.save(configuration)

    assert [configuration] == Backend.configurations()
  end

  test "sets the priority order of configurations" do
    :ok = Backend.reset()

    configuration1 = %WPAPersonal{ssid: "Test Network", psk: "12341234"}

    configuration2 = %WPAPersonal{ssid: "Test Network2", psk: "12341234"}

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
    configuration = %WPAPersonal{ssid: "Drop Me", psk: "12341234"}
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
