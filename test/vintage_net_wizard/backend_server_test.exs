defmodule VintageNetWizard.BackendServer.Test do
  use ExUnit.Case, async: true

  alias VintageNetWizard.BackendServer

  test "Can save a WiFi configuration" do
    :ok = BackendServer.reset()

    configuration = %{ssid: "Test Network"}

    :ok = BackendServer.save(configuration)

    assert [configuration] == BackendServer.configurations()
  end

  test "sets the priority order of configurations" do
    :ok = BackendServer.reset()

    configuration1 = %{ssid: "Test Network", psk: "12341234", priority: nil}

    configuration2 = %{ssid: "Test Network2", psk: "12341234", priority: nil}

    :ok = BackendServer.save(configuration1)
    :ok = BackendServer.save(configuration2)

    :ok = BackendServer.set_priority_order([configuration2.ssid, configuration1.ssid])

    [c2, c1] = BackendServer.configurations()

    assert c2.ssid == configuration2.ssid
    assert c2.priority == 1

    assert c1.ssid == configuration1.ssid
    assert c1.priority == 2

    :ok = BackendServer.reset()
  end

  test "delete a configuration" do
    :ok = BackendServer.reset()
    configuration = %{ssid: "Drop Me"}
    :ok = BackendServer.save(configuration)

    assert [configuration] == BackendServer.configurations()
    assert :ok == BackendServer.delete_configuration(configuration.ssid)

    assert [] == BackendServer.configurations()
  end

  test "don't apply when there are no configurations" do
    :ok = BackendServer.reset()

    [] = BackendServer.configurations()

    assert {:error, :no_configurations} = BackendServer.apply()
  end

  test "can complete with no configurations" do
    :ok = BackendServer.reset()
    assert :ok = BackendServer.complete()
  end
end
