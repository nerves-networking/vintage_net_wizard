defmodule VintageNetWizard.Web.Socket do
  @moduledoc false
  require Logger

  alias VintageNetWizard.{Backend, WiFiConfiguration}

  @behaviour :cowboy_websocket
  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  def websocket_init(_state) do
    send(self(), :after_connect)
    {:ok, %{}}
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
    {:ok, wifi_config} = WiFiConfiguration.from_map(data)

    case get_access_point_by_name(wifi_config.ssid) do
      nil ->
        {:ok, state}

      access_point ->
        payload = %{
          type: :wifi_cfg,
          data: %{
            ssid: access_point.ssid,
            frequency:
              frequency_text(access_point.frequency, access_point.band, access_point.channel),
            flags: access_point.flags,
            signal: access_point.signal_percent
          }
        }

        _ = Backend.save([wifi_config])

        {:reply, {:text, Jason.encode!(payload)}, state}
    end
  end

  # Message from JS indicating the data should be saved
  def websocket_handle({:json, %{"type" => "apply"}}, state) do
    _ = Backend.apply()
    {:ok, state}
  end

  def websocket_info(:after_connect, state) do
    :ok = Backend.subscribe()
    access_points = Backend.access_points()
    {:reply, scan_results_to_json(access_points), state}
  end

  def websocket_info({WizardNetWizard, {:access_points, access_points}}, state) do
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

  defp summarize_scan_results(%{
         ssid: ssid,
         frequency: frequency,
         band: band,
         channel: channel,
         flags: flags,
         signal_percent: signal_percent
       }) do
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

  defp get_access_point_by_name(ap_name) do
    Enum.find(Backend.access_points(), fn ap ->
      ap_name == ap.ssid
    end)
  end
end
