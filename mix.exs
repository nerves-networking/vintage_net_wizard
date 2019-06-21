defmodule VintageNet.Wizard.MixProject do
  use Mix.Project

  @all_targets [:rpi0, :rpi3, :rpi3a]

  def project do
    [
      app: :vintage_net_wizard,
      version: "0.1.0",
      elixir: "~> 1.8",
      archives: [nerves_bootstrap: "~> 1.5"],
      start_permanent: Mix.env() == :prod,
      build_embedded: false,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps()
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
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
      {:nerves, "~> 1.4", runtime: false},
      {:shoehorn, "~> 0.4"},
      {:ring_logger, "~> 0.6"},
      {:toolshed, "~> 0.2"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.6", targets: @all_targets},
      {:vintage_net, github: "nerves-networking/vintage_net", targets: @all_targets},
      {:busybox, "~> 0.1", targets: @all_targets},

      # Dependencies for specific targets
      {:farmbot_system_rpi0, "~> 1.7.2-farmbot.0", targets: :rpi0},
      {:farmbot_system_rpi3, "~> 1.7.2-farmbot.0", targets: :rpi3},
      {:nerves_system_rpi3a, "~> 1.7", targets: :rpi3a}
    ]
  end
end
