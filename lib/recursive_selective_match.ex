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
    if opts[:standardize_keys] do
      {expected, actual} = standardize_keys(expected, actual)
    end
    success = Enum.reduce(Map.keys(expected), true, fn key, acc ->
      acc && Map.has_key?(actual, key) && matches?(Map.get(expected, key), Map.get(actual, key), opts)
    end)
    print_warning(expected, actual, success, opts)
  end

  def matches?(expected, actual, opts) when is_tuple(expected) and is_tuple(actual) do
    if tuple_size(expected) >= 1 do
      exp = elem(expected, 0)
      act = elem(actual, 0)
      matches?(exp, act, opts) &&
        matches?(Tuple.delete_at(expected, 0), Tuple.delete_at(actual, 0), opts)
    else
      true
    end
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

  def matches?(:any_list, actual, opts) when is_list(actual) do
    true
  end

  def matches?(:any_map, actual, opts) when is_map(actual) do
    true
  end

  def matches?(:any_integer, actual, opts) when is_integer(actual) do
    true
  end

  def matches?(:any_binary, actual, opts) when is_binary(actual) do
    true
  end

  def matches?(:any_atom, actual, opts) when is_atom(actual) do
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

  defp standardize_keys(expected, actual) do
    {expected |> AtomicMap.convert(%{safe: false}),
     actual |> AtomicMap.convert(%{safe: false})}
  end

end
