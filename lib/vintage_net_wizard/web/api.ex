defmodule VintageNetWizard.Web.Api do
  @moduledoc false

  alias VintageNetWizard.{WiFiConfiguration, Backend}
  alias Plug.Conn

  use Plug.Router

  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  get "/configuration/status" do
    with status <- Backend.configuration_status(),
         {:ok, json_status} <- Jason.encode(status) do
      send_json(conn, 200, json_status)
    end
  end

  get "/access_points" do
    {:ok, access_points} =
      Backend.access_points()
      |> to_json()

    send_json(conn, 200, access_points)
  end

  put "/ssids" do
    conn
    |> get_body()
    |> Backend.set_priority_order()

    send_json(conn, 204, "")
  end

  get "/complete" do
    _ = send_json(conn, 202, "")
    :ok = Backend.stop_scan()
    :ok = Backend.apply()
    :ok = VintageNetWizard.stop_server()

    conn
  end

  get "/configurations" do
    {:ok, json} =
      Backend.configurations()
      |> Jason.encode()

    send_json(conn, 200, json)
  end

  post "/apply" do
    case Backend.apply() do
      :ok ->
        send_json(conn, 202, "")

      {:error, :no_configurations} ->
        json =
          %{
            error: "no_configurations",
            message: "Please provide configurations to apply."
          }
          |> Jason.encode!()

        send_json(conn, 404, json)
    end
  end

  put "/:ssid/configuration" do
    with {:ok, cfg} <- configuration_from_params(conn, ssid),
         :ok <- Backend.save(cfg) do
      send_json(conn, 204, "")
    else
      error ->
        send_json(conn, 400, make_error_message(error))
    end
  end

  delete "/:ssid/configuration" do
    :ok = Backend.delete_configuration(ssid)

    send_json(conn, 200, "")
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
    |> Enum.filter(&non_empty_ssid/1)
    |> Enum.sort(fn %{signal_percent: a}, %{signal_percent: b} -> a >= b end)
    |> Enum.uniq_by(fn %{ssid: ssid} -> ssid end)
    |> Jason.encode()
  end

  defp non_empty_ssid(%{ssid: ""}), do: false
  defp non_empty_ssid(_other), do: true

  defp configuration_from_params(conn, ssid) do
    conn
    |> get_body()
    |> Map.put("ssid", ssid)
    |> WiFiConfiguration.from_map()
  end

  defp make_error_message({:error, :password_required, key_mgmt}) do
    Jason.encode!(%{
      error: "password_required",
      message: "A password is required for #{key_mgmt} access points."
    })
  end

  defp make_error_message({:error, :password_too_short}) do
    Jason.encode!(%{
      error: "password_too_short",
      message: "The minimum length for a password is 8."
    })
  end

  defp make_error_message({:error, :password_too_long}) do
    Jason.encode!(%{
      error: "password_too_long",
      message: "The maximum length for a password is 63."
    })
  end

  defp make_error_message({:error, :invalid_characters}) do
    Jason.encode!(%{
      error: "invalid_characters",
      message: "The password provided has invalid characters."
    })
  end
end
