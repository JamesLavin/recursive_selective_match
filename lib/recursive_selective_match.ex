defmodule RecursiveSelectiveMatch do
  require Logger

  @moduledoc """
  RecursiveSelectiveMatch lets you specify a deeply nested test data structure and check
  whether another actual data structure contains all keys and values specified in the
  test data strucure. The actual data structure can include extra keys not mentioned in
  the tes data structure. And actual data structure values will be ignored whenever the
  corresponding test data structure value is :anything.

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

  Even better, you can pass in a one-argument anonymous function and it will pass the
  actual value in for testing. The following expectation will also pass with the example above:

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
  tuples, and structs. (When comparing an expected struct against an actual struct, it begins
  first compares based on struct type and then compares keys & values. When comparing an expected
  map against an actual struct, by default, it only compares keys & values. To prevent expected
  maps from matching actual structs, pass `strict_struct_matching: true` in your options map)

  You can also pass in multiple expectations for a single value using a {:multi, ...} tuple.
  The following will check that: 1) there are exactly three items in the `:players` list; and,
  2) every player has an `lname` field that is a string with at least four bytes:

     %{
        players: {:multi, [&(length(&1) == 3),
                           &(Enum.all?(&1, fn(player) -> (player.lname |> byte_size()) >= 4 end))
                          ]
                 }
      }

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

  * You can override the default behavior of allowing maps to match structs, and instead prevent maps from matching structs by passing an options map (as a third argument) containing `%{strict_struct_matching: true}`.

  * You can override the default behavior of calling Logger.error() on errors to instead call IO.inspect() by passing an options map (as a third argument) containing `%{io_errors: true}`.

  This library is a clean reimplementation and extension of SelectiveRecursiveMatch, a
  library I wrote at Teladoc to solve the same problem. I have reimplemented it to
  write cleaner code on my second attempt. (As Fred Brooks wrote, "plan to throw
  one away; you will, anyhow.") While I wrote this library on my own time and have added
  features not present in the original, my inspiration to create this and the time spent
  building my initial implementation both came from Teladoc, so thank you, Teladoc!
  """

  @doc """
  `RecursiveSelectiveMatch.includes?(expected, actual)` tests whether `expected` exists as a member of `actual`,
  where inclusion is tested using RecursiveSelectiveMatch.matches?()

  """
  def includes?(expected, actual_list, _opts \\ %{})

  def includes?(expected, actual_list, _opts) when is_list(actual_list) do
    Enum.any?(actual_list,
              fn(actual_val) ->
                matches?(expected, actual_val, %{suppress_warnings: true})
              end)
  end

  def includes?(_expected, _actual, _opts), do: false

  @doc """
  matches?()

  ## Examples

      iex> RecursiveSelectiveMatch.matches?(%{what: :ever}, %{what: :ever, not: :checked})
      true

      iex> RecursiveSelectiveMatch.matches?(%{what: :ever, is: :checked}, %{what: :ever}, %{suppress_warnings: true})
      false

  """
  def matches?(expected, actual, opts \\ %{})

  def matches?({:multi, list}, actual, opts) when is_list(list) do
    Enum.all?(list, fn(expectation) -> matches?(expectation, actual, opts) end)
  end

  def matches?(%{__struct__: exp_struct} = expected, %{__struct__: act_struct} = actual, opts) do
    matches?(exp_struct, act_struct, opts) &&
      matches?(expected |> Map.from_struct(), actual |> Map.from_struct(), opts)
  end

  # Default behavior allows maps to match structs
  # To prevent maps from matching structs, include `stict_struct_matching: true` in your opts map
  def matches?(%{} = expected, %{__struct__: _act_struct} = actual, opts) do
    case opts[:strict_struct_matching] do
      true ->
        false
      false ->
        matches?(expected, actual |> convert_struct_to_map(), opts)
      nil ->
        matches?(expected, actual |> convert_struct_to_map(), opts)
    end
  end

  def matches?(expected, actual, opts) when is_map(expected) and is_map(actual) do
    {expected, actual} =
      cond do
        opts[:standardize_keys] ->
          standardize_keys(expected, actual)
        true ->
          {expected, actual}
      end
    success = Enum.reduce(Map.keys(expected), true, fn key, acc ->
      has_key = Map.has_key?(actual, key)
      has_correct_value = matches?(Map.get(expected, key), Map.get(actual, key), Map.merge(opts, %{suppress_warnings: true}))
      if !has_key do
        log_missing_map_key_warning(key, expected, actual, opts)
      end
      if has_key && !has_correct_value do
        log_incorrect_map_value_warning(key, expected, actual, opts)
      end
      acc && has_key && has_correct_value
    end)
    log_unequal_warning(expected, actual, success, opts)
  end

  def matches?(expected, actual, opts) when is_tuple(expected) and is_tuple(actual) do
    cond do
      tuple_size(expected) > tuple_size(actual) ->
        log_unequal_warning(expected, actual, false, Map.put(opts, :warning_message, "Expected tuple is larger than actual tuple"))
      tuple_size(expected) < tuple_size(actual) ->
        log_unequal_warning(expected, actual, false, Map.put(opts, :warning_message, "Actual tuple is larger than expected tuple"))
      tuple_size(expected) >= 1 ->
        is_equal = Enum.zip(expected |> Tuple.to_list(),
                            actual |> Tuple.to_list())
                   |> Enum.map(fn {exp, act} -> matches?(exp, act, opts) end)
                   |> Enum.all?(fn(x) -> x == true end)
        if is_equal do
          true
        else
          log_unequal_warning(expected, actual, false, opts)
          false
        end
      true ->
        true
    end
  end

  # Look for each expected list element
  # Report expected list element not in actual list
  def matches?(expected, actual, opts) when is_list(expected) and is_list(actual) do
    success = Enum.all?(expected, fn expected_element ->
      Enum.any?(actual,
                fn(actual_element) ->
                  matches?(expected_element,
                           actual_element,
                           Map.merge(opts, %{suppress_warnings: true}))
                end)
    end)
    log_unequal_warning(expected, actual, success, opts)
  end

  def matches?(:anything, _actual, _opts) do
    true
  end

  def matches?(:any_list, actual, _opts) when is_list(actual) do
    true
  end

  def matches?(:any_map, actual, _opts) when is_map(actual) do
    true
  end

  def matches?(:any_integer, actual, _opts) when is_integer(actual) do
    true
  end

  def matches?(:any_tuple, actual, _opts) when is_tuple(actual) do
    true
  end

  def matches?(:any_binary, actual, _opts) when is_binary(actual) do
    true
  end

  def matches?(:any_atom, actual, _opts) when is_atom(actual) do
    true
  end

  def matches?(:any_boolean, actual, _opts) when is_boolean(actual) do
    true
  end

  def matches?(expected, actual, opts) when is_function(expected) do
    success = expected.(actual)
    log_unequal_warning(expected, actual, success, opts)
  end

  def matches?(:any_struct, %{__struct__: _}, _opts) do
    true
  end

  def matches?(expected, actual, opts) do
    success = expected == actual
    log_unequal_warning(expected, actual, success, opts)
  end

  defp add_non_nil(list, val) when is_nil(val), do: list
  defp add_non_nil(list, val) when is_list(list), do: [val | list]

  defp log_missing_map_key_warning(key, expected, actual, opts) do
    key = stringify(key)
    expected = stringify(expected)
    actual = stringify(actual)
    error_string = "Key #{key} not present in #{inspect actual} but present in #{inspect expected}"
    log_error_string(error_string, false, opts)
    false
  end

  defp log_incorrect_map_value_warning(key, expected_map, actual_map, opts) do
    printable_key = key
                    |> print_or_inspect()
    expected_val = expected_map
                   |> Map.get(key)
                   |> print_or_inspect()
    actual_val = actual_map
                 |> Map.get(key)
                 |> print_or_inspect()
    string_exp_map = expected_map
                     |> print_or_inspect()
    string_actual_map = actual_map
                        |> print_or_inspect()
    error_string = "Key #{printable_key} is expected to have a value of #{expected_val} (according to #{string_exp_map}) but has a value of #{actual_val} (in #{string_actual_map})"
    log_error_string(error_string, false, opts)
    false
  end

  def print_or_inspect(%{__struct__: _} = val) do
    inspect val
  end

  def print_or_inspect(%{} = val) do
    inspect val
  end

  def print_or_inspect(val) when is_integer(val) do
    val
  end

  def print_or_inspect(val) when is_function(val) do
    inspect val
  end

  def print_or_inspect(val) when is_list(val) do
    val
    |> Enum.map(&print_or_inspect/1)
    |> Enum.join(~s(, ))
    |> (fn(val) -> ~s([#{val}]) end).()
  end

  def print_or_inspect(val) when is_tuple(val) do
    inspect val
  end

  def print_or_inspect(val) when is_atom(val) do
    inspect val
  end

  def print_or_inspect(val) when is_binary(val) do
    inspect val
  end

  def print_or_inspect(val) do
    val
  end

  defp log_unequal_warning(_expected, _actual, true, _opts), do: true

  # TODO: treat maps and non-maps differently???
  defp log_unequal_warning(expected, actual, success, opts) do
    #expected = stringify(expected)
    #actual = stringify(actual)
    error_string = [Map.get(opts, :warning_message, nil), "#{print_or_inspect actual} does not match #{print_or_inspect expected}"]
                   |> List.foldl([], fn(val, acc) -> add_non_nil(acc, val) end)
                   |> Enum.reverse()
                   |> Enum.join(":\n")
    log_error_string(error_string, success, opts)
    success
  end

  defp log_error_string(error_string, success, opts) do
    unless success || opts[:suppress_warnings] do
      if opts[:io_errors] do
        IO.inspect(error_string)
      else
        Logger.error(error_string)
      end
    end
  end

  def stringify(value) when is_binary(value) do
    value
  end

  def stringify(value) when is_integer(value) do
    inspect value
  end

  def stringify(value) when is_function(value) do
    inspect value
  end

  def stringify(value) when is_tuple(value) do
    inspect value
  end

  def stringify(value) when is_atom(value) do
    inspect value
  end

  def stringify(value) when is_list(value) do
    value
    |> Enum.map(&stringify/1)
    |> Enum.join(~s(, ))
    |> (fn(val) -> ~s([#{val}]) end).()
  end

  def stringify(%_struct{} = value) do
    inspect value
  end

  def stringify(value) when is_map(value) do
    value
    |> Map.keys()
    |> Enum.reduce(%{},
                   fn(key, acc) ->
                     Map.put(acc, key, Map.get(value, key) |> stringify())
                   end)
    # m |> Map.keys() |> Enum.reduce(%{}, fn(key, acc) -> Map.put(acc, key, Map.get(m, key) |> RSM.stringify()) end)
  end

  def stringify(value) do
    inspect value
  end

  defp standardize_keys(expected, actual) do
    {expected |> AtomicMap.convert(%{safe: false}),
     actual |> AtomicMap.convert(%{safe: false})}
  end

  def convert_struct_to_map(%_{} = struct) do
    keys_to_strip = [:__meta__, :__field__, :__queryable__, :__owner__, :__cardinality__]
    map = struct
          |> Map.from_struct()
    Enum.reduce(keys_to_strip,
                map,
                fn(key_to_strip, acc) -> Map.delete(acc, key_to_strip) end)
  end

end
