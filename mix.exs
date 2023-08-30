defmodule Exbox.MixProject do
  use Mix.Project

  def project do
    [
      app: :exbox,
      version: "0.3.3",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      dialyzer: [plt_add_apps: [:mix, :ex_unit]],
      description: description(),
      package: package(),
      deps: deps(),
      name: "Exbox",
      source_url: "https://github.com/Intellection/exbox",
      test_coverage: [
        ignore_modules: [
          Exbox.Metrics,
          Exbox.Metrics.MetricHandler,
          Exbox.Metrics.Connection,
          Exbox.Application,
          Mix.Tasks.Bump,
          Exbox.Metrics.Client,
          Exbox.Flags
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ldclient, "~> 2.0", hex: :launchdarkly_server_sdk},
      # https://elixirforum.com/t/compiling-eredis-with-elixir-1-15-breaks-compilation/56612/6
      # {:eredis, "~>1.4.0", manager: :rebar3},
      {:instream, "~> 2.2"},
      {:telemetry, "~> 1.2.1"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.21.0", only: [:dev, :test]},
      {:sobelow, "~> 0.8", only: [:dev, :test]}
    ]
  end

  defp description() do
    "Common tooling and functionality for our Elixir applications"
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README*),
      licenses: ["MIT"]
    ]
  end
end
