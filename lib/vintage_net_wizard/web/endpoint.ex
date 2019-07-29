defmodule VintageNetWizard.Web.Endpoint do
  @moduledoc """
  Supervisor for the Web part of the VintageNet Wizard.
  """
  alias VintageNetWizard.Web.{Router, Socket}
  alias VintageNetWizard.Network
  use Supervisor

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  @impl Supervisor
  def init([port]) do
    Supervisor.init(make_children(port), strategy: :one_for_one)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/socket", Socket, []},
         {:_, Plug.Cowboy.Handler, {Router, []}}
       ]}
    ]
  end

  defp make_children(port) do
    if Network.configured?() do
      []
    else
      [
        Plug.Cowboy.child_spec(
          scheme: :http,
          plug: Router,
          options: [port: port, dispatch: dispatch()]
        )
      ]
    end
  end
end
