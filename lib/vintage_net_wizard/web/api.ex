defmodule VintageNetWizard.Web.Api do
  @moduledoc false

  alias VintageNetWizard.{WiFiConfiguration, Backend}
  alias Plug.Conn

  use Plug.Router

  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  get "/access_points" do
    {:ok, access_points} =
      Backend.access_points()
      |> to_json()

    send_json(conn, 200, access_points)
  end

  get "/configurations" do
    {:ok, json} =
      Backend.configurations()
      |> Jason.encode()

    send_json(conn, 200, json)
  end

  put "/configurations" do
    :ok =
      conn
      |> get_body()
      |> Enum.map(fn cfg ->
        {:ok, cfg} = WiFiConfiguration.from_map(cfg)
        cfg
      end)
      |> Backend.save()

    send_json(conn, 204, "")
  end

  post "/apply" do
    :ok = Backend.apply()
    send_json(conn, 202, "")
  end

  defp send_json(conn, status_code, json) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status_code, json)
  end

  defp get_body(%Conn{body_params: %{"_json" => body}}) do
    body
  end

  defp get_body(%Conn{body_params: body}), do: body

  defp to_json(access_points) do
    access_points
    |> Enum.map(fn {_, ap} -> summarize(ap) end)
    |> Enum.filter(&non_empty_ssid/1)
    |> Enum.sort(fn %{signal_percent: a}, %{signal_percent: b} -> a >= b end)
    |> Enum.uniq_by(fn %{ssid: ssid} -> ssid end)
    |> Jason.encode()
  end

  defp summarize(%{
         ssid: ssid,
         frequency: frequency,
         band: band,
         channel: channel,
         flags: flags,
         signal_percent: signal_percent
       }) do
    %{
      ssid: ssid,
      signal_percent: signal_percent,
      frequency: frequency,
      band: band,
      channel: channel,
      flags: flags
    }
  end

  defp non_empty_ssid(%{ssid: ""}), do: false
  defp non_empty_ssid(_other), do: true
end
