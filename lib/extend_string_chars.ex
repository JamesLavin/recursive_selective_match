defimpl String.Chars, for: Map do
  def to_string(map) do
    inspect(map)
  end
end

defimpl String.Chars, for: Tuple do
  def to_string(tuple) do
    interior =
      tuple
      |> Tuple.to_list()
      |> Enum.map(&inspect/1)
      |> Enum.join(", ")

    "{#{interior}}"
  end
end

defimpl String.Chars, for: Function do
  def to_string(fun) do
    inspect(fun)
  end
end

# override to_string/1 when param is list to call inspect/1 instead of to_string/1

defimpl String.Chars, for: List do
  def to_string(list) do
    inspect(list)
    # interior =
    #   list
    #   |> Enum.map(&inspect/1)
    #   |> Enum.join(", ")

    # "[#{interior}]"
  end
end
