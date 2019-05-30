defmodule VintageNet.Wizard.Web.Endpoint do
  @moduledoc """
  Supervisor for the Web part of the VintageNet Wizard.
  """
  alias VintageNet.Wizard.Web.{Router, Socket}
  use Supervisor

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  @impl Supervisor
  def init(_args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Router,
        options: [port: 4001, dispatch: dispatch()]
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
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
end
