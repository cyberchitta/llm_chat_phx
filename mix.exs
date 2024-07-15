defmodule LlmChat.MixProject do
  use Mix.Project

  def project do
    [
      app: :llm_chat,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {LlmChat.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:bandit, "~> 1.2"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dns_cluster, "~> 0.1.1"},
      {:dotenvy, "~> 0.8.0"},
      {:earmark, "~> 1.4"},
      {:ecto_sql, "~> 3.0"},
      {:elixir_auth_google, "~> 1.6.9"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:exandra, "~> 0.10"},
      {:floki, ">= 0.30.0", only: :test},
      {:gettext, "~> 0.24"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:jason, "~> 1.2"},
      {:openai_ex, "~> 0.8.0"},
      {:phoenix, "~> 1.7.11"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.14"},
      {:postgrex, "~> 0.17.5"},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind llm_chat", "esbuild llm_chat"],
      "assets.deploy": [
        "tailwind llm_chat --minify",
        "esbuild llm_chat --minify",
        "phx.digest"
      ]
    ]
  end
end
