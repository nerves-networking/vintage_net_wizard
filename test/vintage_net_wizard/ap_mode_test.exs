defmodule VintageNetWizard.APModeTest do
  use ExUnit.Case, async: true

  alias VintageNetWizard.APMode

  test "AP mode configuration has expected content" do
    config = APMode.ap_mode_configuration("hostname", "our_name")

    expected = %{
      type: VintageNet.Technology.WiFi,
      ipv4: %{address: {192, 168, 0, 1}, method: :static, prefix_length: 24},
      wifi: %{networks: [%{key_mgmt: :none, mode: :host, ssid: "hostname"}]},
      dhcpd: %{
        end: {192, 168, 0, 254},
        max_leases: 235,
        options: %{
          dns: [{192, 168, 0, 1}],
          domain: "our_name",
          router: [{192, 168, 0, 1}],
          search: ["our_name"],
          subnet: {255, 255, 255, 0}
        },
        start: {192, 168, 0, 20}
      },
      dnsd: %{records: [{"our_name", {192, 168, 0, 1}}]}
    }

    assert expected == config
  end
end
