defmodule VintageNet.Wizard.Web.Socket do
  require Logger

  @behaviour :cowboy_websocket
  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  def websocket_init(_state) do
    existing_scan = subscribe()
    send(self(), :after_connect)
    {:ok, %{wifi_cfg: %{}, scan: existing_scan}}
  end

  def websocket_handle({:text, message}, state) do
    case Jason.decode(message) do
      {:ok, json} ->
        websocket_handle({:json, json}, state)

      _ ->
        _ = Logger.debug("discarding info: #{message}")
        {:ok, state}
    end
  end

  # Message from JS trying to add a new network
  def websocket_handle({:json, %{"type" => "wifi_cfg", "data" => data}}, state) do
    if available = state.scan[data["bssid"]] do
      _ = Logger.info("data is in scan: #{inspect(data)}")

      payload = %{
        type: :wifi_cfg,
        data: %{
          bssid: data["bssid"],
          ssid: available.ssid,
          frequency: frequency_text(available.frequency, available.band, available.channel),
          flags: available.flags,
          signal: available.signal_percent
        }
      }

      {:reply, {:text, Jason.encode!(payload)}, %{state | wifi_cfg: data}}
    else
      _ = Logger.error("data is not in scan: #{inspect(data)}")

      {:ok, %{state | wifi_cfg: data}}
    end
  end

  # Message from JS indicating the data should be saved
  def websocket_handle({:json, %{"type" => "save"}}, state) do
    save(state.wifi_cfg)
    {:ok, state}
  end

  # Load currently configured networks
  def websocket_info(:after_connect, state) do
    :ok = scan()
    payload = scan_results_to_json(state.scan)
    {:reply, payload, state}
  end

  def websocket_info(
        {VintageNet, ["interface", "wlan0", "wifi", "access_points"], _old_value, scan_results,
         _meta},
        state
      ) do
    payload = scan_results_to_json(scan_results)
    {:reply, payload, %{state | scan: scan_results}}
  end

  def websocket_info(info, state) do
    Logger.info("Dropping #{inspect(info)}")
    {:ok, state}
  end

  def terminate(_reason, _req, _state) do
    :ok
  end

  defp scan_results_to_json(scan_results) do
    Enum.map(scan_results, fn {bssid,
                               %{
                                 ssid: ssid,
                                 frequency: frequency,
                                 band: band,
                                 channel: channel,
                                 flags: flags,
                                 signal_percent: signal_percent
                               }} ->
      json =
        Jason.encode!(%{
          type: :wifi_scan,
          data: %{
            bssid: bssid,
            ssid: ssid,
            frequency: frequency_text(frequency, band, channel),
            flags: flags,
            signal: signal_percent
          }
        })

      {:text, json}
    end)
  end

  defp frequency_text(_frequency, :wifi_2_4_ghz, channel) do
    "2.4 GHz channel #{channel}"
  end

  defp frequency_text(_frequency, :wifi_5_ghz, channel) do
    "5 GHz channel #{channel}"
  end

  defp frequency_text(frequency, _band, _channel) do
    "#{frequency} MHz"
  end

  # Mix.target() == :host do
  if false do
    defp subscribe() do
      # One existing AP...
      %{
        "04:18:d6:47:1a:6a" => %{
          band: :wifi_2_4_ghz,
          bssid: "04:18:d6:47:1a:6a",
          channel: 6,
          flags: [:wpa2_psk_ccmp, :ess],
          frequency: 2462,
          signal_dbm: -89,
          signal_percent: 40,
          ssid: "WirelessPCU"
        }
      }
    end

    defp scan do
      send(
        self(),
        {VintageNet, ["interface", "wlan0", "wifi", "access_points"], %{},
         %{
           "04:18:d6:47:1a:6a" => %{
             band: :wifi_2_4_ghz,
             bssid: "04:18:d6:47:1a:6a",
             channel: 6,
             flags: [:wpa2_psk_ccmp, :ess],
             frequency: 2462,
             signal_dbm: -89,
             signal_percent: 10,
             ssid: "WirelessPCU"
           },
           "16:18:d6:47:1a:6a" => %{
             band: :wifi_2_4_ghz,
             bssid: "16:18:d6:47:1a:6a",
             channel: 6,
             flags: [:wpa2_psk_ccmp, :ess],
             frequency: 2462,
             signal_dbm: -90,
             signal_percent: 9,
             ssid: ""
           },
           "06:18:d6:47:1a:6a" => %{
             band: :wifi_2_4_ghz,
             bssid: "06:18:d6:47:1a:6a",
             channel: 6,
             flags: [:wpa2_psk_ccmp, :ess],
             frequency: 2462,
             signal_dbm: -90,
             signal_percent: 9,
             ssid: "WirelessPCU - Guest"
           },
           "26:9e:db:0d:4f:21" => %{
             band: :wifi_2_4_ghz,
             bssid: "26:9e:db:0d:4f:21",
             channel: 6,
             flags: [],
             frequency: 2462,
             signal_dbm: -61,
             signal_percent: 60,
             ssid: "SETUP"
           },
           "26:9e:db:0d:4f:22" => %{
             band: :wifi_2_4_ghz,
             bssid: "26:9e:db:0d:4f:22",
             channel: 6,
             flags: [:wpa2_eap_ccmp, :ess],
             frequency: 2462,
             signal_dbm: -61,
             signal_percent: 80,
             ssid: "enterprise"
           }
         }, %{}}
      )

      :ok
    end

    defp save(cfg) do
      IO.inspect(cfg, label: "CFG")
      :ok
    end
  else
    defp subscribe() do
      existing_aps = VintageNet.get(["interface", "wlan0", "wifi", "access_points"], [])
      :ok = VintageNet.subscribe(["interface", "wlan0", "wifi", "access_points"])
      existing_aps
    end

    defp scan() do
      VintageNet.scan("wlan0")
    end

    defp save(%{"key_mgmt" => "wpa_psk"} = cfg) do
      VintageNet.configure("wlan0", %{
        type: VintageNet.Technology.WiFi,
        wifi: %{
          ssid: cfg["ssid"],
          mode: :client,
          key_mgmt: :wpa_psk,
          psk: cfg["psk"]
        },
        ipv4: %{method: :dhcp}
      })
    end

    defp save(%{"key_mgmt" => "wpa_eap"} = cfg) do
      VintageNet.configure("wlan0", %{
        type: VintageNet.Technology.WiFi,
        wifi: %{
          ssid: cfg["ssid"],
          mode: :client,
          key_mgmt: :wpa_eap,
          identity: cfg["identity"],
          password: cfg["password"]
        },
        ipv4: %{method: :dhcp}
      })
    end
  end
end
