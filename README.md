# RecursiveSelectiveMatch

RecursiveSelectiveMatch is an Elixir library application enabling testing of
deeply nested Elixir data structures while selectively ignoring irrelevant data
elements and data structure subtrees you wish to exclude from your matching (like
primary & foreign key IDs, timestamps, and 3rd-party IDs).

This library is a clean reimplementation of SelectiveRecursiveMatch, a library I
wrote at Teladoc to solve the same problem. I am reimplementing it because I can
write cleaner code the second time through. (As Fred Brooks wrote, "plan to
throw one away; you will, anyhow"). While I wrote this library on my own time,
my inspiration to create it and the time to build my initial implementation
both came from Teladoc, so thank you, Teladoc.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `recursive_selective_match` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:recursive_selective_match, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/recursive_selective_match](https://hexdocs.pm/recursive_selective_match).

