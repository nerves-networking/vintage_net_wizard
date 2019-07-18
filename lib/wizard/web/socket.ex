defmodule VintageNet.Wizard.Web.Socket do
  require Logger

  @behaviour :cowboy_websocket
  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  def websocket_init([%{access_points: access_points, scan_mode: scan_mode}]) do
    send(self(), :after_connect)

    {:ok, %{access_points: access_points, wifi_cfg: nil, scan_mode: scan_mode}}
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

  def websocket_handle(
        {:json, %{"type" => "wifi_cfg", "data" => data}},
        %{access_points: access_points} = state
      ) do
    if Map.has_key?(access_points, data["bssid"]) do
      available = access_points[data["bssid"]]

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
  def websocket_handle(
        {:json, %{"type" => "save"}},
        state
      ) do
    save(state.wifi_cfg)
    {:ok, state}
  end

  def websocket_handle(_, state) do
    {:ok, state}
  end

  def websocket_info(
        :after_connect,
        %{scan_mode: :continuous} = state
      ) do
    access_points = subscribe()
    payload = scan_results_to_json(access_points)

    {:reply, payload, %{state | access_points: access_points}}
  end

  def websocket_info(:after_connect, state) do
    payload = scan_results_to_json(state.access_points)
    {:reply, payload, state}
  end

  # Load currently configured networks

  def websocket_info(
        {VintageNet, ["interface", "wlan0", "wifi", "access_points"], _old_value, scan_results,
         _meta},
        state
      ) do
    payload = scan_results_to_json(scan_results)

    {:reply, payload, %{state | access_points: scan_results}}
  end

  def websocket_info(info, state) do
    Logger.info("Dropping #{inspect(info)}")
    {:ok, state}
  end

  def terminate(_reason, _req, _state) do
    :ok
  end

  defp subscribe() do
    property = ["interface", "wlan0", "wifi", "access_points"]
    existing_aps = VintageNet.get(property, [])
    :ok = VintageNet.subscribe(property)
    existing_aps
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

  # defp load_results_to_json(load_results) do
  #   Enum.map(load_results, fn %{
  #                               bssid: bssid,
  #                               ssid: ssid,
  #                               frequency: frequency,
  #                               flags: flags,
  #                               signal: signal
  #                             } ->
  #     json =
  #       Jason.encode!(%{
  #         type: :wifi_cfg,
  #         data: %{bssid: bssid, ssid: ssid, frequency: frequency, flags: flags, signal: signal}
  #       })

  #     {:text, json}
  #   end)
  # end

  defp frequency_text(_frequency, :wifi_2_4_ghz, channel) do
    "2.4 GHz channel #{channel}"
  end

  defp frequency_text(_frequency, :wifi_5_ghz, channel) do
    "5 GHz channel #{channel}"
  end

  defp frequency_text(frequency, _band, _channel) do
    "#{frequency} MHz"
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
