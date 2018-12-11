# RecursiveSelectiveMatch

`RecursiveSelectiveMatch` is an Elixir library application enabling testing of deeply nested Elixir data structures. It includes several powerful features:

1) It selectively ignores irrelevant data elements and data structure subtrees you wish to exclude from your matching (like primary & foreign key IDs, timestamps, and 3rd-party IDs), so you can specify what must match and ignore everything else
2) By default, it allows testing actual structs with expected maps, but you can enable :strict_struct_matching
3) By default, it requires that keys be of the same type, but you can ignore differences between string and atom keys by enabling :standardize_keys
4) Rather than testing only values, you can also test values' datatypes using any of the following:
    * :anything
    * :any_date
    * :any_time
    * :any_list
    * :any_map
    * :any_tuple
    * :any_integer
    * :any_binary
    * :any_atom
    * :any_boolean
    * :any_struct
5) Rather than test only values, you can test against arbitrary anonymous functions, for example: `fname: &(Regex.match?(~r/[A-Z][a-z]{2,}/,&1))`
6) You can test multiple criteria for a single value using a `{:multi, [...]}` tuple

`RecursiveSelectiveMatch` currently provides two functions:

1) `matches?(expected, actual, opts \\ %{})`
2) `includes?(expected, actual_list, opts \\ %{})`.

Most of this documentation covers `matches?(expected, actual, opts \\ %{})`, which is for matching entire data structures.

`includes?(expected, actual_list, opts \\ %{})` is similar but used to test whether `expected` matches _any list item_ inside the list `actual_list`.

For example, imagine you want to test a function that returns a nested data structure like this:

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

Imagine further that each time you call this function, some details vary. Maybe each time you
call the function, you get a random team, not always the NBA's greatest team of all time (only
team with 17 championships... #boston_strong!) and you don't care about specific ids or the
data_fetched_at time stamp or maybe even details about the players or team. But you want to
test that the structure of the data is correct and possibly confirm some of the values.

With `RecursiveSelectiveMatch`, you can create a generic test by specifying an _expected_ data structure,
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

If you assign the actual data structure (in this case a map) to the variable `actual` and the
expected data structure to the variable `expected`, you can test whether they match using:

    defmodule MyTest do
      use ExUnit.Case
    
      alias RecursiveSelectiveMatch, as: RSM
    
      test "actual matches expected" do
        expected = %{ players: :any_list, ... }
    
        actual = %{ ... }
    
        assert RSM.matches?(expected, actual)
      end
    end

Please note that the order matters. The first parameter is for _expected_ and the second is for _actual_. This successfully matches (you can see the test in [test/recursive_selective_match_test.exs](test/recursive_selective_match_test.exs)).

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

`RecursiveSelectiveMatch` currently works (at least sort of) with Elixir maps, lists,
tuples, and structs (which it begins comparing based on struct type and then treats as maps).

You can also specify multiple expectations for a single value using a `{:multi, ...}` tuple.
The following will check that: 1) there are exactly three items in the `:players` list; and,
2) every player has an `lname` field which is a string of at least four bytes:

    %{
       players: {:multi, [&(length(&1) == 3),
                          &(Enum.all?(&1, fn(player) -> (player.lname |> byte_size()) >= 4 end))
                         ]
                }
     }

After adding `RecursiveSelectiveMatch` to your project as a dependency, you can pass
an expected and an actual data structure to `RecursiveSelectiveMatch.matches?()` as follows.
If every element in `expected` also exists in `actual`, `matches?()` should return `true`.
If any element of `expected` is not in `actual`, `matches?()` should return `false`.

By default, when `matches?()` returns `false`, it should also display a message indicating
what data structure or element failed to match. It will not display all missing data
structures or elements but only the first it finds.

`RecursiveSelectiveMatch.matches?()` take an optional third argument, which is a map of
options:

* _To disable warnings_: You can disable the default behavior of displaying the reason for any match failure by passing an options map (as a third argument) containing `%{suppress_warnings: true}`.

* _To treat string & atom keys as equivalent when evaluating maps_: You can override the default behavior of requiring that maps' expected and actual keys be of the same type and instead ignore differences between string and atom keys in maps by passing an options map (as a third argument) containing `%{standardize_keys: true}`.

* _To prevent expected maps from matching actual structs_: If you expect a map and attempt to match it against an actual struct, by default `RecursiveSelectiveMatch` treats the struct as a map for matching purposes. You can override this default behavior and prevent expected maps from matching actual structs by passing an options map (as a third argument) containing `%{strict_struct_matching: true}`, which will prevent ordinary maps from matching structs.

* _To require that lists match exactly (i.e., all expected list elements are present & in the expected order)_: The default behavior is to consider lists to match if all expected list elements are found in the actual list. If you want to consider lists to match only if the lists are identical, you can pass an options map (as a third argument) containing `%{exact_lists: true}`. This will cause lists to match only if they match exactly.

* _To require that actual lists contain all expected list elements but ignore order_: The default behavior is to consider lists to match if all expected list elements are found in the actual list. If you want to consider lists to match only if all expected list items are present and no additional list items are present in the actual list (and you don't care about the ordering of these elements), you can pass an options map (as a third argument) containing `%{full_lists: true}`. This will cause lists to match only if all expected list elements are present and no unexpected list elements are present.

If you wanted to change the earlier example by overriding all three default options, just add
a third argument, like this:

    defmodule MyTest do
      use ExUnit.Case
    
      alias RecursiveSelectiveMatch, as: RSM
    
      assert RSM.matches?(expected,
                          actual,
                          %{suppress_warnings: true,
                            standardize_keys: true,
                            strict_struct_matching: true})
    end

`RecursiveSelectiveMatch` module originally printed failure messages. I've rewritten it to log error messages,
but you can override this to keep the original behavior by passing `io_errors: true` inside
the opts map.

You can test that the correct error messages are generated (and prevent those error messages from
leaking through) by using ExUnit's `capture_log()`:

    defmodule MyTest do
      use ExUnit.Case
      import ExUnit.CaptureLog

      alias RecursiveSelectiveMatch, as: RSM

      expected = {:a, :b, :c}
      actual = {:a, :b, :d}
      assert capture_log(fn -> RSM.matches?(expected, actual) end) =~
        "[error] :d does not match :c"
      assert capture_log(fn -> RSM.matches?(expected, actual) end) =~
        "[error] {:a, :b, :d} does not match {:a, :b, :c}"
    end

If you don't care about the error messages and just want to ensure that the test fails when the actual data structure doesn't match the expected data structure, you can instead use ExUnit's `refute` and pass `%{suppress_warnings: true}` in the opts hash:

    defmodule MyTest do
      use ExUnit.Case

      alias RecursiveSelectiveMatch, as: RSM

      expected = {:a, :b, :c}
      actual = {:a, :b, :d}
      refute RSM.matches?(expected, actual, %{suppress_warnings: true})
    end

`RecursiveSelectiveMatch` is a clean reimplementation and extension of `SelectiveRecursiveMatch`, a
library I wrote at Teladoc to solve the same problem. I have reimplemented it to
write cleaner code on my second attempt. (As Fred Brooks wrote, "plan to throw
one away; you will, anyhow.") While I wrote this library on my own time and have added
features not present in the original, my inspiration to create this and the time spent
building my initial implementation both came from Teladoc, so thank you, Teladoc!

## Changelog

To see how `RecursiveSelectiveMatch` has changed over time, please see the [CHANGELOG](CHANGELOG.md).

## Installation

`RecursiveSelectiveMatch` is [available in Hex](https://hex.pm/packages/recursive_selective_match) and can be installed
by adding `recursive_selective_match` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:recursive_selective_match, "~> 0.2.2"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Docs can also
be found at [https://hexdocs.pm/recursive_selective_match](https://hexdocs.pm/recursive_selective_match).

## TODO

I have not yet reimplemented several features of my original `SelectiveRecursiveMatch` but plan to do so:

* `:debug_mode` - Option to display every step in the `RecursiveSelectiveMatch` process

I want :debug_mode to intelligently display all levels of information for the first failing path it encounters but not display any information for dead-ends it encounters that are not actually failing paths. These can be different if, for example, we're searching through a list of items for one that matches, in which case we would want to ignore items that don't match until we fail to match the expected item against the very last item in the corresponding actual list.

I also hope to allow you to use your expected data structures as a template for generating concrete data structures for testing purposes.

I want to add an option to require that list elements be in the order specified in the expected list. (By default, the order of list items is ignored.)
