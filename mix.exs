defmodule VintageNetWizard.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :vintage_net_wizard,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs(),
      package: package(),
      description: description()
    ]
  end

  def application do
    [
      mod: {VintageNetWizard.Application, []},
      extra_applications: [:logger, :runtime_tools, :eex]
    ]
  end

  defp description do
    "WiFi Setup Wizard that uses VintageNet"
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/nerves-networking/vintage_net_wizard"}
    }
  end

  defp deps do
    [
      # Dependencies for all targets
      {:plug_cowboy, "~> 2.0"},
      {:phoenix_html, "~> 2.13"},
      {:jason, "~> 1.0"},
      {:vintage_net, "~> 0.3"},
      # {:vintage_net, github: "nerves-networking/vintage_net", branch: "force-wifi-scan"},
      {:nerves_runtime, "~> 0.10"},
      {:ex_doc, "~> 0.19", only: :docs, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp dialyzer() do
    [
      flags: [:race_conditions, :unmatched_returns, :error_handling, :underspecs],
      list_unused_filters: true
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: "https://github.com/nerves-networking/vintage_net_wizard"
    ]
  end
end
