defmodule Exbox.MixProject do
  use Mix.Project

  def project do
    [
      app: :exbox,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Exbox",
      source_url: "https://github.com/Intellection/exbox"
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
      {:ldclient, "~> 2.0", hex: :launchdarkly_server_sdk}
    ]
  end

  defp description() do
    "Common tooling and functionality for our Elixir applications"
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README*),
      licenses: ["Apache-2.0"],
      organization: "zappi"
    ]
  end
end
