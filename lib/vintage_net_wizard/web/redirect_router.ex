defmodule VintageNetWizard.Web.RedirectRouter do
  @moduledoc false
  import Plug.Conn

  def init(options) do
    # initialize options
    options
  end

  def call(conn, scheme: scheme, dns_name: dns_name, port: config_port) do
    port = if config_port == 443, do: "", else: ":#{config_port}"

    conn
    |> put_resp_header("location", "#{scheme}://#{dns_name}#{port}")
    |> send_resp(302, "")
  end
end
