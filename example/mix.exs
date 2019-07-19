defmodule WizardExample.MixProject do
  use Mix.Project

  @app :wizard_example
  @version "0.1.0"

  @all_targets [:rpi0, :rpi3, :rpi3a]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.9",
      archives: [nerves_bootstrap: "~> 1.6"],
      start_permanent: Mix.env() == :prod,
      build_embedded: false,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
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
      mod: {WizardExample.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.5.0", runtime: false},
      {:shoehorn, "~> 0.6"},
      {:ring_logger, "~> 0.6"},
      {:toolshed, "~> 0.2"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.10", targets: @all_targets},
      {:busybox, "~> 0.1", targets: @all_targets},
      {:vintage_net_wizard, path: "../", targets: @all_targets},
      {:vintage_net, "~> 0.3", targets: @all_targets},
      {:nerves_system_rpi0, "~> 1.8", targets: :rpi0},
      {:nerves_system_rpi3, "~> 1.8", targets: :rpi3},
      {:nerves_system_rpi3a, "~> 1.8", targets: :rpi3a}
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble]
    ]
  end
end
