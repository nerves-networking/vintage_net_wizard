defmodule VintageNetWizard.APModeTest do
  use ExUnit.Case, async: true

  alias VintageNetWizard.APMode

  test "AP mode configuration has expected content" do
    config = APMode.ap_mode_configuration("hostname", "our_name")

    expected = %{
      type: VintageNetWiFi,
      ipv4: %{address: {172, 16, 61, 0}, method: :static, prefix_length: 24},
      vintage_net_wifi: %{networks: [%{key_mgmt: :none, mode: :ap, ssid: "hostname"}]},
      dhcpd: %{
        end: {172, 16, 61, 254},
        max_leases: 235,
        options: %{
          dns: [{172, 16, 61, 0}],
          domain: "our_name",
          router: [{172, 16, 61, 0}],
          search: ["our_name"],
          subnet: {255, 255, 255, 0}
        },
        start: {172, 16, 61, 20}
      },
      dnsd: %{records: [{"our_name", {172, 16, 61, 0}}]}
    }

    assert expected == config
  end

  test "empty hostname gets changed to a valid ssid" do
    config = APMode.ap_mode_configuration("", "our_name")

    %{vintage_net_wifi: %{networks: [%{ssid: ssid}]}} = config

    assert ssid == "vintage_net_wizard"
  end

  test "long hostname gets trimmed" do
    config = APMode.ap_mode_configuration("1234567890123456789012345678901234567890", "our_name")

    %{vintage_net_wifi: %{networks: [%{ssid: ssid}]}} = config

    assert byte_size(ssid) <= 32
  end
end
