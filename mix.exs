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
      aliases: aliases(),
      name: "Zexbox",
      source_url: "https://github.com/Intellection/zexbox",
      test_coverage: [
        ignore_modules: [
          Mix.Tasks.Bump,
          Zexbox.Metrics.Connection
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
      # instream hard-depends on hackney "~> 1.1", whose 1.x line has open
      # advisories fixed only in 4.x. Override to a patched 4.x (drop-in for the
      # request/5 + body/1 API instream uses). Consuming apps must repeat this
      # top-level override — Mix ignores :override in nested deps.
      {:hackney, "~> 4.0", override: true},
      {:instream, "~> 2.2"},
      {:ldclient, "~> 3.11.0", hex: :launchdarkly_server_sdk},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:mock, "~> 0.3.0", only: :test},
      {:sobelow, "~> 0.8", only: [:dev, :test]},
      {:telemetry, "~> 1.3"}
    ]
  end

  defp aliases() do
    [
      # Security advisory audit. No-upstream-fix advisories are ignored
      # per-advisory in the ignore file.
      audit: ["deps.audit --ignore-file .mix_audit_ignore"]
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
