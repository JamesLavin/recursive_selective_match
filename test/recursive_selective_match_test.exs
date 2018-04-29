defmodule RecursiveSelectiveMatchTest do
  use ExUnit.Case
  doctest RecursiveSelectiveMatch

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
