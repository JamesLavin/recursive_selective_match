defmodule RecursiveSelectiveMatch.MixProject do
  use Mix.Project

  def project do
    [
      name: "RecursiveSelectiveMatch",
      description: "Library enabling testing of deeply nested data structures while
      selectively ignoring irrelevant data elements / subtrees or testing just
      values' datatypes using :anything, :any_list, :any_map, :any_tuple,
      :any_integer, :any_binary, :any_atom, :any_boolean, :any_struct, etc.",
      package: package(),
      source_url: "https://github.com/JamesLavin/recursive_selective_match",
      app: :recursive_selective_match,
      docs: [main: "RecursiveSelectiveMatch",
             extras: ["README.md"]],
      version: "0.1.1",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:atomic_map, "~> 0.8"},
    ]
  end

  defp package() do
    [
      maintainers: ["James Lavin"],
      licenses: ["Apache 2.0"],
      links: %{"Github" => "https://github.com/JamesLavin/recursive_selective_match"}
    ]
  end
end
