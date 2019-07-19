defmodule VintageNet.Wizard.Web.Socket do
  require Logger

  alias VintageNet.Wizard.Backend

  @behaviour :cowboy_websocket
  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  def websocket_init(_state) do
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
    Backend.save(state.wifi_cfg)
    {:ok, state}
  end

  # Load currently configured networks
  def websocket_info(:after_connect, state) do
    :ok = Backend.subscribe()
    access_points = Backend.access_points()

    payload = scan_results_to_json(access_points)
    {:reply, payload, %{state | scan: access_points}}
  end

  def websocket_info({WizardNet.Wizard, {:access_points, access_points}}, state) do
    payload = scan_results_to_json(access_points)
    {:reply, payload, %{state | scan: access_points}}
  end

  def websocket_info(info, state) do
    _ = Logger.info("Dropping #{inspect(info)}")
    {:ok, state}
  end

  def terminate(_reason, _req, _state) do
    :ok
  end

  defp scan_results_to_json(scan_results) do
    scan_results
    |> Enum.map(&summarize_scan_results/1)
    |> Enum.filter(&non_empty_ssid/1)
    |> Enum.sort(fn %{signal_percent: a}, %{signal_percent: b} -> a >= b end)
    |> Enum.uniq_by(fn %{ssid: ssid} -> ssid end)
    |> Enum.map(&to_json/1)
  end

  defp summarize_scan_results(
         {_bssid,
          %{
            ssid: ssid,
            frequency: frequency,
            band: band,
            channel: channel,
            flags: flags,
            signal_percent: signal_percent
          }}
       ) do
    %{
      ssid: ssid,
      frequency: frequency_text(frequency, band, channel),
      flags: flags,
      signal_percent: signal_percent
    }
  end

  defp non_empty_ssid(%{ssid: ""}), do: false
  defp non_empty_ssid(_other), do: true

  defp to_json(%{
         ssid: ssid,
         frequency: frequency,
         flags: flags,
         signal_percent: signal_percent
       }) do
    json =
      Jason.encode!(%{
        type: :wifi_scan,
        data: %{
          ssid: ssid,
          frequency: frequency,
          flags: flags,
          signal: signal_percent
        }
      })

    {:text, json}
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
end
