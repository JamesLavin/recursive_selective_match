defmodule RecursiveSelectiveMatch do
  require Logger

  @moduledoc """
  `RecursiveSelectiveMatch` is an Elixir library application enabling testing of deeply nested Elixir data structures. It includes several powerful features:

  1) It selectively ignores irrelevant data elements and data structure subtrees you wish to exclude from your matching (like primary & foreign key IDs, timestamps, and 3rd-party IDs), so you can specify what must match and ignore everything else
  2) By default, it allows testing actual structs with expected maps, but you can enable :strict_struct_matching
  3) By default, it requires that keys be of the same type, but you can ignore differences between string and atom keys by enabling :standardize_keys
  4) Rather than testing only values, you can also test values' datatypes using any of the following:
      * :anything
      * :any_iso8601_date (a string, like "2018-07-04"; rejects most invalid dates)
      * :any_iso8601_time (a string, like "12:56:11"; rejects invalid times)
      * :any_iso8601_datetime (a string, like "2018-07-04 12:56:11" or "2018-07-04T12:56:11"; rejects most invalid dates/times)
      * :any_date (the Elixir Date representation)
      * :any_time (the Elixir Time representation)
      * :any_naive_datetime (the Elixir NaiveDateTime representation)
      * :any_list
      * :any_map
      * :any_tuple
      * :any_integer (also: :any_pos_integer & :any_non_neg_integer)
      * :any_float (also: :any_pos_float & :any_non_neg_float)
      * :any_number (also: :any_pos_number & :any_non_neg_number)
      * :any_binary
      * :any_bitstring
      * :any_atom
      * :any_boolean
      * :any_struct
      * :any_pid
      * :any_port
      * :any_reference
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
                greatest_player: %Person{id: 4, fname: "Bill", lname: "Russell", position: :center, jersey_num: "6", born: ~D[1934-02-12]},
                plays_at: %{arena: %{name: "Boston Garden",
                                     location: %{"city" => "Boston", "state" => "MA"}}}},
        data_fetched_at: "2018-04-17 11:14:53",
        formatted_data_fetched_at: ~N[2018-04-17 11:14:53]
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
        formatted_data_fetched_at: :any_naive_datetime,
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
                                         jersey_num: &(Regex.match?(~r/\d{1,2}/,&1)),
                                         born: :any_date},
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
  library I wrote at [Teladoc](https://www.teladoc.com/) to solve the same problem. I reimplemented it to
  write cleaner code on my second attempt. (As Fred Brooks wrote, "plan to throw
  one away; you will, anyhow.") While I created this library on my own time and have added
  features not present in the original, my inspiration to create this and the time spent
  building my initial implementation both came from Teladoc, so thank you, Teladoc! Thanks also
  to [CareDox](https://caredox.com/) where I work now and have begun extending this library.
  """

  @doc """
  `RecursiveSelectiveMatch.includes?(expected, actual, opts // %{})` tests whether `expected` exists as a member of `actual`,
  where inclusion is tested using RecursiveSelectiveMatch.matches?()

  """
  def includes?(expected, actual_list, _opts \\ %{})

  def includes?(expected, actual_list, _opts) when is_list(actual_list) do
    Enum.any?(
      actual_list,
      fn actual_val ->
        matches?(expected, actual_val, %{suppress_warnings: true})
      end
    )
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
    Enum.all?(list, fn expectation -> matches?(expectation, actual, opts) end)
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

    success =
      Enum.reduce(Map.keys(expected), true, fn key, acc ->
        has_key = Map.has_key?(actual, key)

        has_correct_value =
          matches?(
            Map.get(expected, key),
            Map.get(actual, key),
            Map.merge(opts, %{suppress_warnings: true})
          )

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
        log_unequal_warning(
          expected,
          actual,
          false,
          Map.put(opts, :warning_message, "Expected tuple is larger than actual tuple")
        )

      tuple_size(expected) < tuple_size(actual) ->
        log_unequal_warning(
          expected,
          actual,
          false,
          Map.put(opts, :warning_message, "Actual tuple is larger than expected tuple")
        )

      tuple_size(expected) >= 1 ->
        is_equal =
          Enum.zip(
            expected |> Tuple.to_list(),
            actual |> Tuple.to_list()
          )
          |> Enum.map(fn {exp, act} -> matches?(exp, act, opts) end)
          |> Enum.all?(fn x -> x == true end)

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
  # By default, ignore order of elements within list
  # If %{exact_lists: true}, match only if the actual list exactly equals the expected list
  # If %{full_lists: true}, match only if the actual list contains only elements in the expected list
  # If %{ordered_lists: true}, match only if elements are in order
  def matches?(expected, actual, %{exact_lists: true} = opts)
      when is_list(expected) and is_list(actual) do
    success =
      length(expected) == length(actual) &&
        Enum.zip(expected, actual)
        |> Enum.all?(fn {exp, act} -> matches?(exp, act) end)

    log_unequal_warning(expected, actual, success, opts)
  end

  def matches?(expected, actual, %{full_lists: true} = opts)
      when is_list(expected) and is_list(actual) do
    success =
      length(expected) == length(actual) &&
        all_expected_list_elements_in_actual(expected, actual, opts)

    log_unequal_warning(expected, actual, success, opts)
  end

  # TODO: Make this work
  # def matches?(expected, actual, %{ordered_lists: true} = opts) when is_list(expected) and is_list(actual) do
  # end

  def matches?(expected, actual, opts) when is_list(expected) and is_list(actual) do
    success = all_expected_list_elements_in_actual(expected, actual, opts)
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

  def matches?(:any_non_neg_integer, actual, _opts) when is_integer(actual) do
    actual >= 0
  end

  def matches?(:any_pos_integer, actual, _opts) when is_integer(actual) do
    actual > 0
  end

  def matches?(:any_float, actual, _opts) when is_float(actual) do
    true
  end

  def matches?(:any_non_neg_float, actual, _opts) when is_float(actual) do
    actual >= 0
  end

  def matches?(:any_pos_float, actual, _opts) when is_float(actual) do
    actual > 0
  end

  def matches?(:any_number, actual, _opts) when is_number(actual) do
    true
  end

  def matches?(:any_non_neg_number, actual, _opts) when is_number(actual) do
    actual >= 0
  end

  def matches?(:any_pos_number, actual, _opts) when is_number(actual) do
    actual > 0
  end

  def matches?(:any_pid, actual, _opts) when is_pid(actual) do
    true
  end

  def matches?(:any_port, actual, _opts) when is_port(actual) do
    true
  end

  def matches?(:any_reference, actual, _opts) when is_reference(actual) do
    true
  end

  def matches?(:any_tuple, actual, _opts) when is_tuple(actual) do
    true
  end

  def matches?(:any_binary, actual, _opts) when is_binary(actual) do
    true
  end

  def matches?(:any_bitstring, actual, _opts) when is_bitstring(actual) do
    true
  end

  def matches?(:any_atom, actual, _opts) when is_atom(actual) do
    true
  end

  def matches?(:any_boolean, actual, _opts) when is_boolean(actual) do
    true
  end

  def matches?(:any_date, actual, _opts) do
    is_date(actual)
  end

  def matches?(:any_iso8601_date, actual, _opts) do
    Regex.match?(~r/\d{4}-(0[1-9]|1[0-2])-([0-2]\d|3[01])/, actual)
  end

  def matches?(:any_iso8601_time, actual, _opts) do
    Regex.match?(~r/([01]\d|2[0-3]):[0-5]\d:[0-5]\d/, actual)
  end

  def matches?(:any_iso8601_datetime, actual, _opts) do
    Regex.match?(
      ~r/\d{4}-(0[1-9]|1[0-2])-([0-2]\d|3[01])[ T]([01]\d|2[0-3]):[0-5]\d:[0-5]\d/,
      actual
    )
  end

  def matches?(:any_time, actual, _opts) do
    is_time(actual)
  end

  def matches?(:any_naive_datetime, actual, _opts) do
    is_naive_datetime(actual)
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

  defp all_expected_list_elements_in_actual(expected, actual, opts) do
    Enum.all?(expected, fn expected_element ->
      Enum.any?(
        actual,
        fn actual_element ->
          matches?(
            expected_element,
            actual_element,
            Map.merge(opts, %{suppress_warnings: true})
          )
        end
      )
    end)
  end

  defp add_non_nil(list, val) when is_nil(val), do: list
  defp add_non_nil(list, val) when is_list(list), do: [val | list]

  defp log_missing_map_key_warning(key, expected, actual, opts) do
    key = stringify(key)
    expected = stringify(expected)
    actual = stringify(actual)

    error_string =
      "Key #{key} not present in #{inspect(actual)} but present in #{inspect(expected)}"

    log_error_string(error_string, false, opts)
    false
  end

  defp log_incorrect_map_value_warning(key, expected_map, actual_map, opts) do
    printable_key =
      key
      |> print_or_inspect()

    expected_val =
      expected_map
      |> Map.get(key)
      |> print_or_inspect()

    actual_val =
      actual_map
      |> Map.get(key)
      |> print_or_inspect()

    string_exp_map =
      expected_map
      |> print_or_inspect()

    string_actual_map =
      actual_map
      |> print_or_inspect()

    error_string =
      "Key #{printable_key} is expected to have a value of #{expected_val} (according to #{
        string_exp_map
      }) but has a value of #{actual_val} (in #{string_actual_map})"

    log_error_string(error_string, false, opts)
    false
  end

  def print_or_inspect(%{__struct__: _} = val) do
    inspect(val)
  end

  def print_or_inspect(%{} = val) do
    inspect(val)
  end

  def print_or_inspect(val) when is_integer(val) do
    val
  end

  def print_or_inspect(val) when is_function(val) do
    inspect(val)
  end

  def print_or_inspect(val) when is_list(val) do
    val
    |> Enum.map(&print_or_inspect/1)
    |> Enum.join(~s(, ))
    |> (fn val -> ~s([#{val}]) end).()
  end

  def print_or_inspect(val) when is_tuple(val) do
    inspect(val)
  end

  def print_or_inspect(val) when is_atom(val) do
    inspect(val)
  end

  def print_or_inspect(val) when is_binary(val) do
    inspect(val)
  end

  def print_or_inspect(val) when is_port(val) do
    inspect(val)
  end

  def print_or_inspect(val) when is_reference(val) do
    inspect(val)
  end

  def print_or_inspect(val) when is_pid(val) do
    inspect(val)
  end

  def print_or_inspect(val) do
    val
  end

  defp log_unequal_warning(_expected, _actual, true, _opts), do: true

  # TODO: treat maps and non-maps differently???
  defp log_unequal_warning(expected, actual, success, opts) do
    # expected = stringify(expected)
    # actual = stringify(actual)
    error_string =
      [
        Map.get(opts, :warning_message, nil),
        "#{print_or_inspect(actual)} does not match #{print_or_inspect(expected)}"
      ]
      |> List.foldl([], fn val, acc -> add_non_nil(acc, val) end)
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
    inspect(value)
  end

  def stringify(value) when is_function(value) do
    inspect(value)
  end

  def stringify(value) when is_tuple(value) do
    inspect(value)
  end

  def stringify(value) when is_atom(value) do
    inspect(value)
  end

  def stringify(value) when is_list(value) do
    value
    |> Enum.map(&stringify/1)
    |> Enum.join(~s(, ))
    |> (fn val -> ~s([#{val}]) end).()
  end

  def stringify(%_struct{} = value) do
    inspect(value)
  end

  def stringify(value) when is_map(value) do
    value
    |> Map.keys()
    |> Enum.reduce(
      %{},
      fn key, acc ->
        Map.put(acc, key, Map.get(value, key) |> stringify())
      end
    )

    # m |> Map.keys() |> Enum.reduce(%{}, fn(key, acc) -> Map.put(acc, key, Map.get(m, key) |> RSM.stringify()) end)
  end

  def stringify(value) do
    inspect(value)
  end

  defp standardize_keys(expected, actual) do
    {expected |> AtomicMap.convert(%{safe: false}), actual |> AtomicMap.convert(%{safe: false})}
  end

  def convert_struct_to_map(%_{} = struct) do
    keys_to_strip = [:__meta__, :__field__, :__queryable__, :__owner__, :__cardinality__]

    map =
      struct
      |> Map.from_struct()

    Enum.reduce(
      keys_to_strip,
      map,
      fn key_to_strip, acc -> Map.delete(acc, key_to_strip) end
    )
  end

  defp is_date(val) do
    with %Date{calendar: _c, day: _d, month: _m, year: _y} <- val do
      true
    else
      _ ->
        false
    end
  end

  defp is_time(val) do
    with %Time{calendar: _c, hour: _h, minute: _m, second: _s, microsecond: _ms} <- val do
      true
    else
      _ ->
        false
    end
  end

  defp is_naive_datetime(val) do
    with %NaiveDateTime{
           calendar: _c,
           year: _yy,
           month: _mm,
           day: _dd,
           hour: _h,
           minute: _m,
           second: _s,
           microsecond: _ms
         } <- val do
      true
    else
      _ ->
        false
    end
  end
end
