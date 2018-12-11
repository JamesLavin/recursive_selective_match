defmodule Person do
  defstruct id: nil, fname: nil, lname: nil, position: nil, jersey_num: nil, born: nil

  defimpl String.Chars do
    def to_string(%Person{id: id, fname: fname, lname: lname, position: position, jersey_num: jersey_num, born: born}) do
      "%Person{id: #{id}, fname: #{fname}, lname: #{lname}, position: #{position}, jersey_num: #{jersey_num}, born: #{born}}"
    end
  end

  defimpl Inspect do
    def inspect(%Person{id: id, fname: fname, lname: lname, position: position, jersey_num: jersey_num, born: born}, _opts) do
      "%Person{id: #{id}, fname: #{fname}, lname: #{lname}, position: #{position}, jersey_num: #{jersey_num}, born: #{born}}"
    end
  end
end
