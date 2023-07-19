defmodule VintageNetWizard.Web.Api do
  @moduledoc false
  import Logger

  alias VintageNetWizard.{WiFiConfiguration, BackendServer}
  alias VintageNetWizard.Web.Endpoint
  alias Plug.Conn

  use Plug.Router

  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  get "/hw_check" do
    response = BackendServer.get_hwcheck()
    Logger.info("Response=> #{inspect(response)}")
    send_json(conn, 200, Jason.encode!(response))
  end

  get "/door" do
    #TODO: Call Backedn getting pin state
    response = %{door: "closed"}
    Logger.info("Response=> #{inspect(response)}")
    send_json(conn, 200, Jason.encode!(response))
  end

  get "/configuration/status" do
    with status <- BackendServer.configuration_status(),
         {:ok, json_status} <- Jason.encode(status) do
      send_json(conn, 200, json_status)
    end
  end

  get "/access_points" do
    {:ok, access_points} =
      BackendServer.access_points()
      |> to_json()

    send_json(conn, 200, access_points)
  end

  put "/lock" do
    body = 
      conn
      |> get_body()
    
    Logger.info("Lock body #{inspect(body)}")

    send_json(conn, 204, Jason.encode!(%{lock: "changed"}))
  end

  ## @phonnz: dunno why separated requests and 204 response 
  ## Can't be a state change? 
  put "/open_lock" do
    conn
    |> get_body()
    |> BackendServer.set_open_lock()

    send_json(conn, 204, "")
  end

  put "/closed_lock" do
    conn
    |> get_body()
    |> BackendServer.set_close_lock()

    send_json(conn, 204, "")
  end

  put "/ssids" do
    conn
    |> get_body()
    |> BackendServer.set_priority_order()

    send_json(conn, 204, "")
  end

  get "/complete" do
    :ok = BackendServer.complete()

    _ =
      Task.Supervisor.start_child(VintageNetWizard.TaskSupervisor, fn ->
        # We don't want to stop the server before we
        # send the response back.
        :timer.sleep(3000)
        Endpoint.stop_server(:shutdown)
      end)

    send_json(conn, 202, "")
  end

  get "/configurations" do
    {:ok, json} =
      BackendServer.configurations()
      |> Jason.encode()

    send_json(conn, 200, json)
  end

  post "/cam1" do

    BackendServer.set_cam(0, true)

    Process.sleep(3_000) # espera 2 segundo

    {:ok, binary} = File.read("/root/cam0.jpg")

    send_imagen(conn, 200, binary)
  end

  post "/cam2" do

    BackendServer.set_cam(1, true)

    Process.sleep(3_000) # espera 2 segundo

    {:ok, binary} = File.read("/root/cam1.jpg")

    send_imagen(conn, 200, binary)
  end

  post "/cam3" do

    BackendServer.set_cam(2, true)

    Process.sleep(3_000) # espera 2 segundo

    {:ok, binary} = File.read("/root/cam2.jpg")

    send_imagen(conn, 200, binary)
  end

  post "/apply" do
    case BackendServer.apply() do
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
         :ok <- BackendServer.save(cfg) do
      send_json(conn, 204, "")
    else
      error ->
        send_json(conn, 400, make_error_message(error))
    end
  end

  delete "/:ssid/configuration" do
    :ok = BackendServer.delete_configuration(ssid)

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
    |> Enum.map(&Map.from_struct/1)
    |> Jason.encode()
  end

  defp non_empty_ssid(%{ssid: ""}), do: false
  defp non_empty_ssid(_other), do: true

  defp configuration_from_params(conn, ssid) do
    conn
    |> get_body()
    |> Map.put("ssid", ssid)
    |> WiFiConfiguration.json_to_network_config()
  end

  defp make_error_message({:error, :password_required}) do
    Jason.encode!(%{
      error: "password_required",
      message: "A password is required."
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

  defp make_error_message({:error, :user_required}) do
    Jason.encode!(%{
      error: "user_required",
      message: "A user is required."
    })
  end

  defp send_imagen(conn, status_code, binary) do
    conn
    |> put_resp_content_type("image/jpeg")
    |> send_resp(status_code, binary)
  end

end
