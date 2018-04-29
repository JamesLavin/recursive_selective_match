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
    refute RecursiveSelectiveMatch.matches?(expected, actual)
  end

  # test "multi-level, key-valued maps" do
  #   expected = %{best_beatle: %{fname: "John", lname: "Lennon"}}
  #   actual = %{best_beatle: %{fname: "John", mname: "Winston", lname: "Lennon", born: 1940}}
  #   assert RecursiveSelectiveMatch.matches?(expected, actual)
  # end

end
