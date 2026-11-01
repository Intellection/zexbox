defmodule Zexbox.MixProject do
  use Mix.Project

  def project do
    [
      app: :zexbox,
      version: "1.6.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      dialyzer: [plt_add_apps: [:mix, :ex_unit]],
      description: description(),
      package: package(),
      deps: deps(),
      name: "Zexbox",
      source_url: "https://github.com/Intellection/zexbox",
      test_coverage: [
        ignore_modules: [
          Mix.Tasks.Bump,
          Zexbox.Metrics.Connection
        ]
      ],
      hex: [
        ignore_advisories: [
          # cowlib cookie request header injection (low). No fixed release yet.
          "GHSA-g2wm-735q-3f56",
          # hackney: ignored package-wide. Its advisories are only fixed in 4.x, which
          # instream (pinned to ~> 1.x) does not allow.
          "EEF-CVE-2026-47075",
          "EEF-CVE-2026-47071",
          "EEF-CVE-2026-47076",
          "EEF-CVE-2026-47069",
          "EEF-CVE-2026-115693"
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
      {:credo, "~> 1.7.19", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.7", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.23.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.40.3", only: :dev, runtime: false},
      {:instream, "~> 2.2"},
      {:ldclient, "~> 3.11.0", hex: :launchdarkly_server_sdk},
      {:mock, "~> 0.3.0", only: :test},
      {:sobelow, "~> 0.8", only: [:dev, :test]},
      {:telemetry, "~> 1.3"}
    ]
  end

  defp description() do
    "Logging, Metrics and Feature Flagging in Elixir."
  end

  defp package() do
    [
      name: "zexbox",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Intellection/zexbox"}
    ]
  end
end
