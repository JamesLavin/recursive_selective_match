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
end
