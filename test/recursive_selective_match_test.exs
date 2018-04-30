defmodule RecursiveSelectiveMatchTest do
  use ExUnit.Case
  doctest RecursiveSelectiveMatch
  Code.require_file("test/person.ex")
  Code.require_file("test/test_struct.ex")
  Code.require_file("test/another_test_struct.ex")

  defp celtics_actual() do
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
  end

  defp celtics_expected() do
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
  end

  test "Celtics test" do
    assert RecursiveSelectiveMatch.matches?(celtics_expected(), celtics_actual())
  end

  defp celtics_expectation_functions() do
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
  end

  test "Celtics test with expectation functions" do
    assert RecursiveSelectiveMatch.matches?(celtics_expectation_functions(), celtics_actual())
  end

  defp celtics_expectation_functions_w_regex() do
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
  end

  test "Celtics test with expectation functions with regexes" do
    assert RecursiveSelectiveMatch.matches?(celtics_expectation_functions_w_regex(), celtics_actual())
  end

  test "matches a single element of a list" do
    expected = %{ players: [
                    %Person{id: 1187, fname: "Robert", lname: "Parrish", position: :center, jersey_num: "00"}
                  ]
                }
    assert RecursiveSelectiveMatch.matches?(expected, celtics_actual())
  end

  test "matches two out of order elements within a list" do
    expected = %{ players: [
                  %Person{id: 1033, fname: "Larry", lname: "Bird", position: :forward, jersey_num: "33"},
                  %Person{id: 1187, fname: "Robert", lname: "Parrish", position: :center, jersey_num: "00"}
                ]
               }
    assert RecursiveSelectiveMatch.matches?(expected, celtics_actual())
  end

  test "matches the full set of list elements when out of order & some matchers are functions" do
    expected = %{ players: [
                  %Person{id: &is_integer/1, fname: "Larry", lname: "Bird", position: :forward, jersey_num: "33"},
                  %Person{id: 979, fname: &is_binary/1, lname: "McHale", position: :forward, jersey_num: "32"},
                  %Person{id: 1187, fname: "Robert", lname: &(String.length(&1) > 4), position: :center, jersey_num: "00"}
                ]
               }
    assert RecursiveSelectiveMatch.matches?(expected, celtics_actual())
  end

  test "doesn't match if Parrish's jersey number expectation is wrong ('0' instead of '00')" do
    expected = %{ players: [
                  %Person{id: &is_integer/1, fname: "Larry", lname: "Bird", position: :forward, jersey_num: "33"},
                  %Person{id: 979, fname: &is_binary/1, lname: "McHale", position: :forward, jersey_num: "32"},
                  %Person{id: 1187, fname: "Robert", lname: &(String.length(&1) > 4), position: :center, jersey_num: "0"}
                ]
               }
    refute RecursiveSelectiveMatch.matches?(expected, celtics_actual(), %{suppress_warnings: true})
  end

  test "single-level, key-valued maps" do
    expected = %{best_beatle: %{fname: "John", lname: "Lennon"}}
    actual = %{best_beatle: %{fname: "John", lname: "Lennon"}}
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "multi-level, key-valued maps" do
    expected = %{best_beatle: %{fname: "John", lname: "Lennon"}}
    actual = %{best_beatle: %{fname: "John", mname: "Winston", lname: "Lennon", born: 1940}}
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "map with an expected value of :anything and an actual value of a list" do
    expected = %{team: "Red Sox", players: :anything}
    actual = %{team: "Red Sox", players: ["Mookie Betts","Xander Bogaerts", "Hanley Ramirez","Jackie Bradley Jr","Chris Sale","Rick Porcello","David Price"]}
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "map with an expected value of :any_list and an actual value of a list" do
    expected = %{team: "Red Sox", players: :any_list}
    actual = %{team: "Red Sox", players: ["Mookie Betts","Xander Bogaerts", "Hanley Ramirez","Jackie Bradley Jr","Chris Sale","Rick Porcello","David Price"]}
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "map with an expected value of :any_map and an actual value of a list" do
    expected = %{team: "Red Sox", players: :any_map}
    actual = %{team: "Red Sox", players: ["Mookie Betts","Xander Bogaerts", "Hanley Ramirez","Jackie Bradley Jr","Chris Sale","Rick Porcello","David Price"]}
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "map with an expected value of :any_map and an actual value of a map" do
    expected = %{team: "Red Sox", players: :any_map}
    actual = %{team: "Red Sox", players: %{right_field: "Mookie Betts", third_base: "Xander Bogaerts", dh: "Hanley Ramirez", center_field: "Jackie Bradley Jr", p1: "Chris Sale", p3: "Rick Porcello", p2: "David Price"}}
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "map with an expected value of :any_integer and an actual value of an integer" do
    expected = %{team: "Red Sox", current_standing: :any_integer}
    actual = %{team: "Red Sox", current_standing: 1}
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "map with an expected value of :any_integer and an actual value of a non-integer" do
    expected = %{team: "Red Sox", current_standing: :any_integer}
    actual = %{team: "Red Sox", current_standing: "1"}
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "map with an expected value of :any_binary and an actual value of a binary" do
    expected = %{team: "Red Sox", current_standing: :any_binary}
    actual = %{team: "Red Sox", current_standing: "1"}
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "map with an expected value of :any_binary and an actual value of a non-binary" do
    expected = %{team: "Red Sox", current_standing: :any_binary}
    actual = %{team: "Red Sox", current_standing: 1}
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "struct with an expected value of :any_binary and an actual value of a binary treated like an equivalent map" do
    expected = %TestStruct{fname: "Larry", lname: :any_binary, hof: :any_boolean}
    actual = %TestStruct{fname: "Larry", lname: "Bird", hof: true}
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "structs of different types don't match" do
    expected = %TestStruct{fname: "Larry", lname: "Bird", hof: true}
    actual = %AnotherTestStruct{fname: "Larry", lname: "Bird", hof: true}
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "map with an expected value of :any_atom and an actual value of an atom" do
    expected = %{team: "Red Sox", current_standing: :any_atom}
    actual = %{team: "Red Sox", current_standing: :first}
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "map with an expected value of :any_atom and an actual value of a non-atom" do
    expected = %{team: "Red Sox", current_standing: :any_atom}
    actual = %{team: "Red Sox", current_standing: 1}
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "map with an expected value of :any_tuple and an actual value of a list" do
    expected = %{team: "Red Sox", players: :any_tuple}
    actual = %{team: "Red Sox", players: ["Mookie Betts","Xander Bogaerts", "Hanley Ramirez","Jackie Bradley Jr","Chris Sale","Rick Porcello","David Price"]}
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "map with an expected value of :any_tuple and an actual value of a tuple" do
    expected = %{team: "Red Sox", players: :any_tuple}
    actual = %{team: "Red Sox", players: {"Mookie Betts","Xander Bogaerts", "Hanley Ramirez","Jackie Bradley Jr","Chris Sale","Rick Porcello","David Price"}}
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "single-level, key-valued maps don't ignore differences between string & atom keys" do
    expected = %{best_beatle: %{fname: "John", lname: "Lennon"}}
    actual = %{"best_beatle" => %{fname: "John", lname: "Lennon"}}
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "multi-level, key-valued maps don't ignore differences between string & atom keys" do
    expected = %{best_beatle: %{fname: "John", lname: "Lennon"}}
    actual = %{best_beatle: %{"fname" => "John", "mname" => "Winston", "lname" => "Lennon", "born" => 1940}}
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "single-level, key-valued maps ignore differences between string & atom keys when standardize_keys: true" do
    expected = %{best_beatle: %{fname: "John", lname: "Lennon"}}
    actual = %{"best_beatle" => %{fname: "John", lname: "Lennon"}}
    assert RecursiveSelectiveMatch.matches?(expected, actual, %{standardize_keys: true})
  end

  test "multi-level, key-valued maps ignore differences between string & atom keys when standardize_keys: true" do
    expected = %{best_beatle: %{"fname" => "John", "lname" => "Lennon"}}
    actual = %{"best_beatle" => %{fname: "John", mname: "Winston", lname: "Lennon", born: 1940}}
    assert RecursiveSelectiveMatch.matches?(expected, actual, %{standardize_keys: true})
  end

  test "single-level list when identical" do
    expected = ["apple", "banana", "cherry"]
    actual = ["apple", "banana", "cherry"]
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "single-level list when actual has extra values" do
    expected = ["apple", "banana", "cherry"]
    actual = ["apple", "banana", "cherry", "strawberry"]
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "single-level list when expected has extra values" do
    expected = ["apple", "banana", "cherry", "strawberry"]
    actual = ["apple", "banana", "cherry"]
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "multi-level lists when expected has extra string value" do
    expected = ["apple", "banana", ["cherry", "grape"], "strawberry"]
    actual = ["apple", "banana", ["cherry", "grape"]]
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "multi-level lists when expected has extra string and list values" do
    expected = ["apple", "banana", ["cherry", "grape"], "strawberry", ["peach", "apricot"]]
    actual = ["apple", "banana", ["cherry", "grape"]]
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "multi-level lists when actual has extra string value" do
    expected = ["apple", "banana", ["cherry", "grape"]]
    actual = ["apple", "banana", ["cherry", "grape"], "strawberry"]
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "multi-level lists when actual has extra string and list values" do
    expected = ["apple", "banana", ["cherry", "grape"]]
    actual = ["apple", "banana", ["cherry", "grape"], "strawberry", ["peach", "apricot"]]
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "multi-level, mixed map & list data structures" do
    expected = %{best_beatle: %{fname: "John", lname: "Lennon", cities: ["Liverpool", "New York"]}}
    actual = %{best_beatle: %{fname: "John", mname: "Winston", lname: "Lennon", born: 1940, cities: ["Liverpool", "New York"]}}
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "expected values of :anything are ignored" do
    expected = %{best_beatle: %{fname: "John", mname: :anything, lname: "Lennon"}}
    actual = %{best_beatle: %{fname: "John", mname: "Winston", lname: "Lennon", born: 1940}}
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "expected values of :anything must exist in actual" do
    expected = %{best_beatle: %{fname: "John", mname: :anything, lname: "Lennon"}}
    actual = %{best_beatle: %{fname: "John", lname: "Lennon", born: 1940}}
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "single-level tuple" do
    expected = {1, "banana"}
    actual = {1, "banana"}
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "single-level tuple when not matching" do
    expected = {1, "banana"}
    actual = {2, "banana"}
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "multi-level tuple" do
    expected = {1, {"banana", "bananas"}}
    actual = {1, {"banana", "bananas"}}
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

  test "multi-level tuple when not matching" do
    expected = {1, {"banana", "yellow"}}
    actual = {1, {"banana", "green"}}
    refute RecursiveSelectiveMatch.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "single-level tuple with :anything" do
    expected = {1, :anything}
    actual = {1, "banana"}
    assert RecursiveSelectiveMatch.matches?(expected, actual)
  end

end
