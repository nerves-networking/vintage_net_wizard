defmodule Mix.Tasks.Wizard.Copy.Assets do
  @shortdoc "Copies templates and static files for easy customization"

  @moduledoc """
  Copies templates and static files for easy customization.

      $ mix wizard.copy.assets
      $ mix wizard.copy.assets priv/wizard

  The first argument is the directory to use in `priv`, where the static files are copied to.

  If no path is given, it will use `vintage_net_wizard`, eg. `priv/vintage_net_wizard`.
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    dir =
      case args do
        [] -> Path.expand("./priv/vintage_net_wizard")
        [path] -> Path.expand("./priv/#{path}")
        [_ | _] -> Mix.raise("Only one argument is supported for the path to use")
      end

    :ok = File.mkdir_p(dir)

    Mix.shell().info("\n")
    Mix.shell().info("Copying EEx templates to #{dir}/templates")

    {:ok, _} =
      Application.app_dir(:vintage_net_wizard, ["priv", "templates"])
      |> File.cp_r(dir <> "/templates")

    Mix.shell().info("Copying JS and CSS files to #{dir}/static")

    {:ok, _} =
      Application.app_dir(:vintage_net_wizard, ["priv", "static"])
      |> File.cp_r(dir <> "/static")

    Mix.shell().info("""

    Web templates and static files copied to #{dir}.

    To use these in your project please specify `templates_path` and `static_files_path`
    when calling `VintageNetWizard.run_wizard/1`.

    If you are copying the files to the default path, you can use the following config:

        opts = [
          templates_path: Application.app_dir(:my_app, ["priv", "vintage_net_wizard", "templates"]),
          static_files_path: Application.app_dir(:my_app, ["priv", "vintage_net_wizard", "static"])
        ]

        VintageNetWizard.run_wizard(opts)
    """)
  end
end
