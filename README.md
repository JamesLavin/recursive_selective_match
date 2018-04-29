# RecursiveSelectiveMatch

RecursiveSelectiveMatch is an Elixir library application enabling testing of
deeply nested Elixir data structures while selectively ignoring irrelevant data
elements and data structure subtrees you wish to exclude from your matching (like
primary & foreign key IDs, timestamps, and 3rd-party IDs) or testing just values'
datatypes using any of the following:

* :anything
* :any_list
* :any_map
* :any_tuple
* :any_integer
* :any_binary
* :any_atom
* :any_boolean
* :any_struct

RecursiveSelectiveMatch currently works (at least sort of) with Elixir maps, lists,
tuples, and structs (which it begins comparing based on struct type and then treats as maps).

After adding RecursiveSelectiveMatch to your project as a dependency, you can pass
an expected and an actual data structure to `RecursiveSelectiveMatch.matches?()` as follows.
If every element in `expected` also exists in `actual`, `matches?()` should return `true`.
If any element of `expected` is not in `actual`, `matches?()` should return `false`.

By default, when `matches?()` returns `false`, it should also display a message indicating
what data structure or element failed to match. It will not display all missing data
structures or elements but only the first it finds.

`RecursiveSelectiveMatch.matches?()` take an optional third argument, which is a map of
options:

* You can disable the default behavior of displaying the reason for the match failure by passing an options map (as a third argument) containing `%{suppress_warnings: true}`.

* You can override the default behavior of requiring that map keys be the same type and instead ignore differences between string and atom keys in maps by passing an options map (as a third argument) containing `%{standardize_keys: true}`.

This library is a clean reimplementation and extension of SelectiveRecursiveMatch, a
library I wrote at Teladoc to solve the same problem. I have reimplemented it to
write cleaner code on my second attempt. (As Fred Brooks wrote, "plan to throw
one away; you will, anyhow.") While I wrote this library on my own time and have added
features not present in the original, my inspiration to create this and the time spent
building my initial implementation both came from Teladoc, so thank you, Teladoc!

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

