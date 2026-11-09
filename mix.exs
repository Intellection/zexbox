defmodule Zexbox.MixProject do
  use Mix.Project

  def project do
    [
      app: :zexbox,
      version: "1.8.0",
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
          # cowlib structured-header CR/LF injection: no fixed release, and nothing in the
          # dependency tree calls cow_http_struct_hd.
          "EEF-CVE-2026-43966",
          # cowlib HTTP/2 HPACK amplification: no fixed release yet. Only reachable via gun in
          # ldclient's streaming client, whose only peer is LaunchDarkly.
          "EEF-CVE-2026-113431",
          # gun: false positive. The advisory records cowboy's fixed version (2.16.0) for gun
          # too, so every gun release matches, although gun was patched in 2.4.0.
          "GHSA-w4f7-4cxr-rv3c"
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
      {:hackney, "~> 1.1 or ~> 4.9", override: true, only: [:dev, :test]},
      {:instream, "~> 2.2"},
      {:ldclient, "~> 3.11.0", hex: :launchdarkly_server_sdk},
      {:logger_json, "~> 7.0", optional: true},
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
