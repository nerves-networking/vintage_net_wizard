defmodule VintageNet.Wizard.Web.Socket do
  require Logger

  @behaviour :cowboy_websocket
  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  def websocket_init(_state) do
    subscribe()

    send(self(), :scan)
    send(self(), :after_connect)

    {:ok, %{wifi_cfg: %{}, scan: %{}}}
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

  def websocket_handle({:json, %{"type" => "wifi_cfg", "data" => data}}, state) do
    if available = state.scan[data["bssid"]] do
      _ = Logger.info("data is in scan: #{inspect(data)}")

      payload = %{
        type: :wifi_cfg,
        data: available
      }

      {:reply, {:text, Jason.encode!(payload)}, %{state | wifi_cfg: data}}
    else
      _ = Logger.error("data is not in scan: #{inspect(data)}")

      {:ok, %{state | wifi_cfg: data}}
    end
  end

  def websocket_handle({:json, %{"type" => "save"}}, state) do
    save(state.wifi_cfg)
    {:ok, state}
  end

  def websocket_info(:after_connect, state) do
    payload =
      Enum.map(load(), fn %{
                            bssid: bssid,
                            ssid: ssid,
                            frequency: frequency,
                            flags: flags,
                            signal: signal
                          } ->
        json =
          Jason.encode!(%{
            type: :wifi_cfg,
            data: %{bssid: bssid, ssid: ssid, frequency: frequency, flags: flags, signal: signal}
          })

        {:text, json}
      end)

    {:reply, payload, state}
  end

  def websocket_info(:scan, state) do
    :ok = scan()
    Process.send_after(self(), :scan, 3000)

    {:ok, %{state | scan: %{}}}
  end

  def websocket_info(
        {VintageNet, ["interface", "wlan0", "access_points"], _old_value, scan_results, _meta},
        state
      ) do
    payload =
      Enum.map(scan_results, fn {bssid,
                                 %{
                                   ssid: ssid,
                                   frequency: frequency,
                                   flags: flags,
                                   signal: signal
                                 }} ->
        json =
          Jason.encode!(%{
            type: :wifi_scan,
            data: %{
              bssid: bssid,
              ssid: ssid,
              frequency: frequency,
              flags: flags,
              signal: signal
            }
          })

        {:text, json}
      end)

    {:reply, payload, %{state | scan: scan_results}}
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end

  def terminate(_reason, _req, _state) do
    :ok
  end

  if Mix.target() == :host do
    defp subscribe(), do: :ok

    defp scan do
      send(
        self(),
        {VintageNet, ["interface", "wlan0", "access_points"], %{},
         %{
           "04:18:d6:47:1a:6a" => %{
             bssid: "04:18:d6:47:1a:6a",
             flags: [:wpa2_psk_ccmp, :ess],
             frequency: 2462,
             signal: -89,
             ssid: "WirelessPCU"
           },
           "16:18:d6:47:1a:6a" => %{
             bssid: "16:18:d6:47:1a:6a",
             flags: [:wpa2_psk_ccmp, :ess],
             frequency: 2462,
             signal: -90,
             ssid: ""
           },
           "06:18:d6:47:1a:6a" => %{
             bssid: "06:18:d6:47:1a:6a",
             flags: [:wpa2_psk_ccmp, :ess],
             frequency: 2462,
             signal: -90,
             ssid: "WirelessPCU - Guest"
           },
           "26:9e:db:0d:4f:21" => %{
             bssid: "26:9e:db:0d:4f:21",
             flags: [],
             frequency: 2462,
             signal: -61,
             ssid: "SETUP"
           },
           "26:9e:db:0d:4f:22" => %{
             bssid: "26:9e:db:0d:4f:22",
             flags: [:wpa2_eap_ccmp, :ess],
             frequency: 2462,
             signal: -61,
             ssid: "enterprise"
           }
         }, %{}}
      )

      :ok
    end

    defp load do
      []
    end

    defp save(cfg) do
      IO.inspect(cfg, label: "CFG")
      :ok
    end
  else
    defp subscribe() do
      VintageNet.subscribe(["interface", "wlan0", "access_points"])
    end

    defp scan() do
      VintageNet.scan("wlan0")
    end

    defp load() do
      []
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
