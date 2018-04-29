defmodule RecursiveSelectiveMatch.MixProject do
  use Mix.Project

  def project do
    [
      name: "RecursiveSelectiveMatch",
      source_url: "https://github.com/JamesLavin/recursive_selective_match",
      app: :recursive_selective_match,
      docs: [main: "RecursiveSelectiveMatch",
             extras: ["README.md"]],
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
    ]
  end
end
