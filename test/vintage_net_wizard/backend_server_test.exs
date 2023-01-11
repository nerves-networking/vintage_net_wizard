defmodule VintageNetWizard.BackendServer.Test do
  use ExUnit.Case, async: true

  alias VintageNetWizard.BackendServer
  alias VintageNetWizard.BackendServer.State

  test "Can save a non-hidden WiFi configuration" do
    :ok = BackendServer.reset()

    configuration = %{ssid: "Testing all the things!"}

    :ok = BackendServer.save(configuration)

    assert [configuration] == BackendServer.configurations()
  end

  test "Can save a hidden WiFi configuration" do
    :ok = BackendServer.reset()

    configuration = %{ssid: "Test Network"}

    :ok = BackendServer.save(configuration)

    assert [Map.put(configuration, :scan_ssid, 1)] == BackendServer.configurations()
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

  test "delete a non-hidden configuration" do
    :ok = BackendServer.reset()
    configuration = %{ssid: "Testing all the things!"}
    :ok = BackendServer.save(configuration)

    assert [configuration] == BackendServer.configurations()
    assert :ok == BackendServer.delete_configuration(configuration.ssid)

    assert [] == BackendServer.configurations()
  end

  test "delete a hidden configuration" do
    :ok = BackendServer.reset()
    configuration = %{ssid: "Drop Me"}
    :ok = BackendServer.save(configuration)

    assert [Map.put(configuration, :scan_ssid, 1)] == BackendServer.configurations()
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

  describe "on completion" do
    defmodule FakeBackend do
      def complete(wifi_configurations, backend_state) do
        send(self(), {:complete_called, wifi_configurations, backend_state})
        {:ok, backend_state}
      end
    end

    test "if the configuration status is not `:good`, calls complete on the backend" do
      BackendServer.handle_call(:complete, :ignored, %State{
        backend: FakeBackend,
        backend_state: %{data: %{configuration_status: :not_configured}}
      })

      assert_received {:complete_called, [], _backend_state}
    end

    test "if the configuration status is `:good` then does not call complete on the backend" do
      BackendServer.handle_call(:complete, :ignored, %State{
        backend: FakeBackend,
        backend_state: %{data: %{configuration_status: :good}}
      })

      refute_received {:complete_called, _, _}
    end
  end
end
