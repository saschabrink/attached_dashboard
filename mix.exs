defmodule AttachedDashboard.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/saschabrink/attached_dashboard"

  def project do
    [
      app: :attached_dashboard,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      config_path: "config/config.exs",
      description: description(),
      package: package(),
      name: "AttachedDashboard",
      source_url: @source_url,
      docs: [
        main: "readme",
        source_ref: "v#{@version}",
        extras: ["README.md", "CHANGELOG.md"],
        skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
      ]
    ]
  end

  def cli do
    [
      preferred_envs: [
        precommit: :test,
        screenshots: :screenshots,
        "attached_dashboard.screenshots": :screenshots
      ]
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:attached, "~> 0.1.0"},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.0"},
      {:ecto, "~> 3.10"},
      {:ecto_sql, "~> 3.10"},
      {:jason, "~> 1.4"},
      {:oban, "~> 2.17"},
      # dev/test
      {:tailwind, "~> 0.3", only: :dev, runtime: false},
      {:esbuild, "~> 0.7", only: :dev, runtime: false},
      {:ecto_sqlite3, "~> 0.22", only: [:test, :screenshots]},
      {:lazy_html, ">= 0.1.0", only: :test},
      # Screenshot generation only — see `mix attached_dashboard.screenshots`
      {:wallaby, "~> 0.30", only: :screenshots, runtime: false},
      {:plug_cowboy, "~> 2.7", only: :screenshots},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:heroicons, "~> 0.5", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      precommit: [
        "compile --warning-as-errors",
        "deps.unlock --unused",
        "format --check-formatted",
        "test"
      ],
      "assets.build": ["attached_dashboard.build_assets"],
      screenshots: ["attached_dashboard.screenshots"]
    ]
  end

  defp description, do: "Phoenix LiveView dashboard for the attached file-attachment library."

  defp package do
    [
      maintainers: ["Sascha Brink"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "https://hexdocs.pm/attached_dashboard/changelog.html"
      },
      files: ~w(lib priv/static mix.exs README.md CHANGELOG.md LICENSE)
    ]
  end
end
