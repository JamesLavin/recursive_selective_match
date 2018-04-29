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

      iex> RecursiveSelectiveMatch.matches?(%{what: :ever, is: :checked}, %{what: :ever}, %{suppress_warnings: true})
      false

  """
  def matches?(expected, actual, opts \\ %{})

  def matches?(expected, actual, opts) when is_map(expected) and is_map(actual) do
    success = Enum.reduce(Map.keys(expected), true, fn key, acc ->
      acc && Map.has_key?(actual, key) && matches?(Map.get(expected, key), Map.get(actual, key), opts)
    end)
    print_warning(expected, actual, success, opts)
  end

  def matches?(expected, actual, opts) when is_list(expected) and is_list(actual) do
    success = Enum.all?(expected, fn exp_key ->
      Enum.any?(actual, fn(act_key) -> act_key == exp_key end)
    end)
    print_warning(expected, actual, success, opts)
  end

  def matches?(:anything, actual, opts) do
    true
  end

  def matches?(expected, actual, opts) do
    success = expected == actual
    print_warning(expected, actual, success, opts)
  end

  defp print_warning(expected, actual, success, opts) when is_list(expected) and is_list(actual) do
    unless success || opts[:suppress_warnings] do
      IO.inspect("#{IO.inspect actual} does not match #{IO.inspect expected}")
    end
    success
  end

  defp print_warning(expected, actual, success, opts) do
    unless success || opts[:suppress_warnings] do
      IO.inspect("#{inspect actual} does not match #{inspect expected}")
    end
    success
  end

end
