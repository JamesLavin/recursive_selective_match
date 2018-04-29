defmodule RecursiveSelectiveMatch do
  @moduledoc """
  RecursiveSelectiveMatch lets you specify a deeply nested test data structure and check
  whether another actual data structure contains all keys and values specified in the
  test data strucure. The actual data structure can include extra keys not mentioned in
  the tes data structure. And actual data structure values will be ignored whenever the
  corresponding test data structure value is :anything.
  """

  @doc """
  matches?()

  ## Examples

      iex> RecursiveSelectiveMatch.matches?(%{what: :ever}, %{what: :ever, not: :checked})
      true

      iex> RecursiveSelectiveMatch.matches?(%{what: :ever, is: :checked}, %{what: :ever})
      false

  """
  def matches?(expected, actual) when is_map(expected) and is_map(actual) do
    Enum.reduce(Map.keys(expected), true, fn key, acc ->
      acc && Map.has_key?(actual, key) && matches?(Map.get(expected, key), Map.get(actual, key))
    end)
  end

  def matches?(expected, actual) when is_list(expected) and is_list(actual) do
    Enum.all?(expected, fn exp_key ->
      Enum.any?(actual, fn(act_key) -> act_key == exp_key end)
    end)
  end

  def matches?(expected, actual) do
    expected == actual
  end
end
