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

For example, imagine you have a function that returns a nested data structure like this:

    %{
      players: [
        %Person{id: 1187, fname: "Robert", lname: "Parrish", position: :center, jersey_num: "00"},
        %Person{id: 979, fname: "Kevin", lname: "McHale", position: :forward, jersey_num: "32"},
        %Person{id: 1033, fname: "Larry", lname: "Bird", position: :forward, jersey_num: "33"},
      ],
      team: %{name: "Celtics",
              nba_id: 13,
              greatest_player: %Person{id: 4, fname: "Bill", lname: "Russell", position: :center, jersey_num: "6"},
              plays_at: %{arena: %{name: "Boston Garden",
                                   location: %{"city" => "Boston", "state" => "MA"}}}},
      data_fetched_at: "2018-04-17 11:14:53"
    }

Imagine further that each time you call this function, some details may vary. Maybe each time you
call the function, you get a random team, not always the NBA's greatest team of all time (only
team with 17 championships... #boston_strong!) and you don't care about specific ids or the data_fetched_at
time stamp or maybe even details about the players or team. But you want to test that the structure
of the data is correct and possibly confirm some of the values.

With RecursiveSelectiveMatch, you can create a generic test by specifying an expected data structure
like this:

    %{
      players: :any_list,
      team: %{name: :any_binary,
              nba_id: :any_integer,
              greatest_player: :any_struct,
              plays_at: %{arena: %{name: :any_binary,
                                   location: %{"city" => :any_binary,
                                               "state" => :any_binary}}}},
      data_fetched_at: :any_binary
    }

This successfully matches (you can see the test in test/recursive_selective_match_test.exs).

Alternatively, you can pass in any function as a matcher. The above can be rewritten as the
following (notice that both approaches can be used interchangeably):

    %{
      players: &is_list/1,
      team: %{name: &is_binary/1,
              nba_id: &is_integer/1,
              greatest_player: :any_struct,
              plays_at: %{arena: %{name: &is_binary/1,
                                   location: %{"city" => &is_binary/1,
                                               "state" => &is_binary/1}}}},
      data_fetched_at: &is_binary/1
    }

Even better, you can pass in a one-argument anonymous function and it will pass the actual
value in for testing. The following expectation will also pass with the example above:

    %{
      players: &(length(&1) == 3),
      team: %{name: &(&1 in ["Bucks","Celtics", "76ers", "Lakers", "Rockets", "Warriors"]),
              nba_id: &(&1 >= 1 && &1 <= 30),
              greatest_player: %Person{id: &(&1 >= 0 && &1 <= 99),
                                       fname: &(Regex.match?(~r/[A-Z][a-z]{2,}/,&1)),
                                       lname: &(Regex.match?(~r/[A-Z][a-z]{2,}/,&1)),
                                       position: &(&1 in [:center, :guard, :forward]),
                                       jersey_num: &(Regex.match?(~r/\d{1,2}/,&1))},
              plays_at: %{arena: %{name: &(String.length(&1) > 3),
                                   location: %{"city" => &is_binary/1,
                                               "state" => &(Regex.match?(~r/[A-Z]{2}/, &1))}}}},
      data_fetched_at: &(Regex.match?(~r/2018-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/, &1))
    }

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

