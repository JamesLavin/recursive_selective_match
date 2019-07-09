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
      |> Enum.map(&String.Chars.to_string/1)
      |> Enum.join(", ")

    "{#{interior}}"
  end
end
