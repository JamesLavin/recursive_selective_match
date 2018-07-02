defmodule IncludesTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  import ExUnit.CaptureIO
  doctest RecursiveSelectiveMatch
  alias RecursiveSelectiveMatch, as: RSM

  defp abcd_list() do
    [["a","b"],["c","d"]]
  end

  test "integer element exists in list" do
    assert RSM.includes?(1, [2, 1, 3])
  end

  test "atom element exists in list" do
    assert RSM.includes?(:who, [:when, :what, :who])
  end

  test "atom element doesn't exist in list" do
    refute RSM.includes?(:where, [:when, :what, :who])
  end

  test "list within lists" do
    assert RSM.includes?(["c", "c"], abcd_list())
  end

  test "doesn't include list within lists" do
    refute RSM.includes?(["1", "3"], abcd_list())
  end

  test "order is irrelevant (by default) when matching list elements" do
    assert RSM.includes?(["d", "c"], abcd_list())
  end

  test "by default, unexpected actual list elements are ignored" do
    assert RSM.includes?(["d", "c"], abcd_list())
  end


  # test "doesn't include list within lists" do
  #   assert capture_log(fn->
  #     RSM.includes?(["1", "3"], abcd_list())
  #   end) =~ "oops"
  # end

end
