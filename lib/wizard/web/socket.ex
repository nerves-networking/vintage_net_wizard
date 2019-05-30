defmodule VintageNet.Wizard.Web.Socket do
  require Logger

  @behaviour :cowboy_websocket
  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  def websocket_init(_state) do
    send(self(), :scan)
    send(self(), :after_connect)
    IO.inspect(self(), label: "WS PID")
    {:ok, %{wifi_cfg: %{}, scan: %{}}}
  end

  def websocket_handle({:text, message}, state) do
    case Jason.decode(message) do
      {:ok, json} ->
        websocket_handle({:json, json}, state)

      _ ->
        Logger.debug("discarding info: #{message}")
        {:ok, state}
    end
  end

  def websocket_handle({:json, %{"type" => "wifi_cfg", "data" => data}}, state) do
    if available = state.scan[data["bssid"]] do
      Logger.info("data is in scan: #{data["bssid"]}")

      payload = %{
        type: :wifi_cfg,
        data: available
      }

      {:reply, {:text, Jason.encode!(payload)}, %{state | wifi_cfg: data}}
    else
      Logger.error("data is not in scan: #{inspect(data)}")

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
    case scan() do
      {:ok, ssids} ->
        payload =
          Enum.map(ssids, fn %{
                               bssid: bssid,
                               ssid: ssid,
                               frequency: frequency,
                               flags: flags,
                               signal: signal
                             } ->
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

        scan =
          Map.new(ssids, fn %{
                              bssid: bssid,
                              ssid: ssid,
                              frequency: frequency,
                              flags: flags,
                              signal: signal
                            } ->
            {bssid,
             %{bssid: bssid, ssid: ssid, frequency: frequency, flags: flags, signal: signal}}
          end)

        # Process.send_after(self(), :scan, 1000)
        {:reply, payload, %{state | scan: scan}}

      error ->
        Logger.error("Could not scan for ssids: #{inspect(error)}")
        Process.send_after(self(), :scan, 3000)
        {:ok, %{state | scan: %{}}}
    end
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end

  def terminate(_reason, _req, _state) do
    :ok
  end

  if Mix.target() == :host do
    defp scan do
      {:ok,
       [
         %{
           bssid: "04:18:d6:47:1a:6a",
           flags: [:wpa2_psk_ccmp, :ess],
           frequency: 2462,
           signal: -89,
           ssid: "WirelessorPCU"
         },
         %{
           bssid: "16:18:d6:47:1a:6a",
           flags: [:wpa2_psk_ccmp, :ess],
           frequency: 2462,
           signal: -90,
           ssid: ""
         },
         %{
           bssid: "06:18:d6:47:1a:6a",
           flags: [:wpa2_psk_ccmp, :ess],
           frequency: 2462,
           signal: -90,
           ssid: "WirelessorPCU - Guest"
         },
         %{
           bssid: "26:9e:db:0d:4f:21",
           flags: [],
           frequency: 2462,
           signal: -61,
           ssid: "SETUP"
         },
         %{
           bssid: "26:9e:db:0d:4f:22",
           flags: [:wpa2_eap_ccmp, :ess],
           frequency: 2462,
           signal: -61,
           ssid: "enterprise"
         }
       ]}
    end

    defp load do
      []
    end

    defp save(cfg) do
      IO.inspect(cfg, label: "CFG")
      :ok
    end
  else
    defp scan do
      VintageNet.scan("wlan0")
    end

    defp load do
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
          password: cfg["identity"]
        },
        ipv4: %{method: :dhcp}
      })
    end
  end
end
