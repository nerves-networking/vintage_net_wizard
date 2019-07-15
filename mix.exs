defmodule VintageNet.Wizard.MixProject do
  use Mix.Project

  def project do
    [
      app: :vintage_net_wizard,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {VintageNet.Wizard.Application, []},
      extra_applications: [:logger, :runtime_tools, :eex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:plug_cowboy, "~> 2.0"},
      {:phoenix_html, "~> 2.13"},
      {:jason, "~> 1.0"},
      {:vintage_net, "~> 0.3"},
      {:nerves_runtime, "~> 0.10"}
    ]
  end
end
