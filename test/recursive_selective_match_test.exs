defmodule RecursiveSelectiveMatchTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  import ExUnit.CaptureIO
  doctest RecursiveSelectiveMatch
  alias RecursiveSelectiveMatch, as: RSM

  defp celtics_actual() do
    %{
      players: [
        %Person{id: 1187, fname: "Robert", lname: "Parrish", position: :center, jersey_num: "00"},
        %Person{id: 979, fname: "Kevin", lname: "McHale", position: :forward, jersey_num: "32"},
        %Person{id: 1033, fname: "Larry", lname: "Bird", position: :forward, jersey_num: "33"}
      ],
      team: %{
        name: "Celtics",
        nba_id: 13,
        greatest_player: %Person{
          id: 4,
          fname: "Bill",
          lname: "Russell",
          position: :center,
          jersey_num: "6",
          born: ~D[1934-02-12]
        },
        plays_at: %{
          arena: %{name: "Boston Garden", location: %{"city" => "Boston", "state" => "MA"}}
        }
      },
      formatted_data_fetched_at: ~N[2018-04-17 11:14:53],
      data_fetched_at: "2018-04-17 11:14:53"
    }
  end

  defp celtics_expected() do
    %{
      players: :any_list,
      team: %{
        name: :any_binary,
        nba_id: :any_integer,
        greatest_player: :any_struct,
        plays_at: %{
          arena: %{name: :any_binary, location: %{"city" => :any_binary, "state" => :any_binary}}
        }
      },
      formatted_data_fetched_at: :any_naive_datetime,
      data_fetched_at: :any_binary
    }
  end

  defp invalid_team() do
    %{
      team: %{name: "Lakers"}
    }
  end

  test "Lakers are the wrong team" do
    refute RSM.matches?(invalid_team(), celtics_actual(), %{suppress_warnings: true})
  end

  test "errors are logged" do
    assert capture_log(fn ->
             RSM.matches?(invalid_team(), celtics_actual())
           end) =~ " does not match "
  end

  test "tuples that match print no warning" do
    expected = {:a, :b, :c}
    actual = {:a, :b, :c}

    assert capture_log(fn ->
             RSM.matches?(expected, actual)
           end) == ""
  end

  test "tuples with elements that don't match print warnings by default" do
    expected = {:a, :b, :c}
    actual = {:a, :b, :d}

    assert capture_log(fn -> RSM.matches?(expected, actual) end) =~
             "[error] :d does not match :c"

    assert capture_log(fn -> RSM.matches?(expected, actual) end) =~
             "[error] {:a, :b, :d} does not match {:a, :b, :c}"
  end

  test "tuples with more actual elements than expected don't match" do
    expected = {:a, :b, :c}
    actual = {:a, :b, :c, :d}

    assert capture_log(fn -> RSM.matches?(expected, actual) end) =~
             "[error] Actual tuple is larger than expected tuple:\n{:a, :b, :c, :d} does not match {:a, :b, :c}"
  end

  test "tuples with fewer actual elements than expected don't match" do
    expected = {:a, :b, :c, :f}
    actual = {:a, :b, :c}

    assert capture_log(fn -> RSM.matches?(expected, actual) end) =~
             "[error] Expected tuple is larger than actual tuple:\n{:a, :b, :c} does not match {:a, :b, :c, :f}"
  end

  test "tuples that don't match print warnings via IO.inspect when io_errors: true" do
    expected = {:a, :b, :c}
    actual = {:a, :b, :d}
    # TODO: The next line produces IO output I'd like to suppress without voiding the test
    assert capture_log(fn -> RSM.matches?(expected, actual, %{io_errors: true}) end) == ""

    assert capture_io(fn -> RSM.matches?(expected, actual, %{io_errors: true}) end) =~
             ":d does not match :c"

    assert capture_io(fn -> RSM.matches?(expected, actual, %{io_errors: true}) end) =~
             "{:a, :b, :d} does not match {:a, :b, :c}"
  end

  defp efgh_list() do
    [["e", "f"], ["g", "h"]]
  end

  test "even with %{full_lists: true}, exact matches of lists of lists match" do
    assert RSM.matches?([["e", "f"], ["g", "h"]], efgh_list(), %{full_lists: true})
  end

  test "by default, unexpected actual list elements are ignored" do
    assert RSM.matches?([["e", "f"]], efgh_list())
  end

  # TODO: Make this work
  @tag :skip
  test "regexs can be used to match list elements" do
    assert RSM.matches?([[~r/e/, ~r/f/]], efgh_list())
  end

  test "when %{full_lists: true}, unexpected actual list elements cause match failure" do
    assert capture_log(fn ->
             RSM.matches?([["e", "f"]], efgh_list(), %{full_lists: true})
           end) =~ "[error] [[\"e\", \"f\"], [\"g\", \"h\"]] does not match [[\"e\", \"f\"]]"
  end

  test "when %{full_lists: true}, order of list elements is ignored" do
    assert RSM.matches?([["g", "h"], ["e", "f"]], efgh_list(), %{full_lists: true})
  end

  test "exactly matching lists match when %{exact_lists: true}" do
    assert RSM.matches?([["e", "f"], ["g", "h"]], efgh_list(), %{exact_lists: true})
  end

  test "presence of unexpected list items causes match failure if %{exact_lists: true}" do
    assert capture_log(fn ->
             RSM.matches?([["e", "f"]], efgh_list(), %{exact_lists: true})
           end) =~
             "[error] [[\"e\", \"f\"], [\"g\", \"h\"]] does not match [[\"e\", \"f\"]]"
  end

  test "order of list items matters when %{exact_lists: true}" do
    assert capture_log(fn ->
             RSM.matches?([["g", "h"], ["e", "f"]], efgh_list(), %{exact_lists: true})
           end) =~
             "[error] [[\"e\", \"f\"], [\"g\", \"h\"]] does not match [[\"g\", \"h\"], [\"e\", \"f\"]]"
  end

  # TODO: Make this work
  @tag :skip
  test "order matters when matching list elements if %{ordered_lists: true}" do
    refute RSM.matches?([["f", "e"]], efgh_list(), %{ordered_lists: true})
  end

  test "suppress_warnings: true disables error logging" do
    expected = {:a, :b, :c}
    actual = {:a, :b, :d}
    assert capture_log(fn -> RSM.matches?(expected, actual, %{suppress_warnings: true}) end) == ""
    assert capture_io(fn -> RSM.matches?(expected, actual, %{suppress_warnings: true}) end) == ""
  end

  test "Celtics matches? test" do
    assert RSM.matches?(celtics_expected(), celtics_actual())
  end

  test "by default, structs don't match maps" do
    parrish = %Person{
      id: 1187,
      fname: "Robert",
      lname: "Parrish",
      position: :center,
      jersey_num: "00"
    }

    refute RSM.includes?(parrish, parrish |> RSM.convert_struct_to_map())
  end

  test "Celtics includes? finds a particular struct when present" do
    assert RSM.includes?(
             celtics_actual()[:players] |> Enum.at(1),
             celtics_actual()[:players]
           )
  end

  test "Celtics includes? finds map with keys when present" do
    assert RSM.includes?(
             %{fname: "Larry", lname: "Bird"},
             celtics_actual()[:players]
           )
  end

  test "Celtics includes? doesn't find map with keys when not present" do
    refute RSM.includes?(
             %{fname: "Magic", lname: "Johnson"},
             celtics_actual()[:players]
           )
  end

  test "Celtics includes? finds :any_struct when struct is present" do
    assert RSM.includes?(
             :any_struct,
             celtics_actual()[:players]
           )
  end

  defp celtics_expectation_functions() do
    %{
      players: &is_list/1,
      team: %{
        name: &is_binary/1,
        nba_id: &is_integer/1,
        greatest_player: :any_struct,
        plays_at: %{
          arena: %{
            name: &is_binary/1,
            location: %{"city" => &is_binary/1, "state" => &is_binary/1}
          }
        }
      },
      data_fetched_at: &is_binary/1
    }
  end

  test "Celtics test with expectation functions" do
    assert RSM.matches?(celtics_expectation_functions(), celtics_actual())
  end

  defp celtics_expectation_functions_w_regex() do
    %{
      players: &(length(&1) == 3),
      team: %{
        name: &(&1 in ["Bucks", "Celtics", "76ers", "Lakers", "Rockets", "Warriors"]),
        nba_id: &(&1 >= 1 && &1 <= 30),
        greatest_player: %Person{
          id: &(&1 >= 0 && &1 <= 99),
          fname: &Regex.match?(~r/[A-Z][a-z]{2,}/, &1),
          lname: &Regex.match?(~r/[A-Z][a-z]{2,}/, &1),
          position: &(&1 in [:center, :guard, :forward]),
          jersey_num: &Regex.match?(~r/\d{1,2}/, &1),
          born: :any_date
        },
        plays_at: %{
          arena: %{
            name: &(String.length(&1) > 3),
            location: %{"city" => &is_binary/1, "state" => &Regex.match?(~r/[A-Z]{2}/, &1)}
          }
        }
      },
      data_fetched_at: &Regex.match?(~r/2018-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/, &1)
    }
  end

  test "Celtics test with expectation functions with regexes" do
    assert RSM.matches?(celtics_expectation_functions_w_regex(), celtics_actual())
  end

  test ":multi allows multiple test criteria" do
    expected = %{
      players:
        {:multi,
         [&(length(&1) == 3), &Enum.all?(&1, fn player -> player.lname |> byte_size() >= 4 end)]}
    }

    assert RSM.matches?(expected, celtics_actual())
  end

  test "matches a single element of a list" do
    expected = %{
      players: [
        %Person{id: 1187, fname: "Robert", lname: "Parrish", position: :center, jersey_num: "00"}
      ]
    }

    assert RSM.matches?(expected, celtics_actual())
  end

  test "matches two out of order elements within a list" do
    expected = %{
      players: [
        %Person{id: 1033, fname: "Larry", lname: "Bird", position: :forward, jersey_num: "33"},
        %Person{id: 1187, fname: "Robert", lname: "Parrish", position: :center, jersey_num: "00"}
      ]
    }

    assert RSM.matches?(expected, celtics_actual())
  end

  test "matches the full set of list elements when out of order & some matchers are functions" do
    expected = %{
      players: [
        %Person{
          id: &is_integer/1,
          fname: "Larry",
          lname: "Bird",
          position: :forward,
          jersey_num: "33"
        },
        %Person{
          id: 979,
          fname: &is_binary/1,
          lname: "McHale",
          position: :forward,
          jersey_num: "32"
        },
        %Person{
          id: 1187,
          fname: "Robert",
          lname: &(String.length(&1) > 4),
          position: :center,
          jersey_num: "00"
        }
      ]
    }

    assert RSM.matches?(expected, celtics_actual())
  end

  test "doesn't match if Parrish's jersey number expectation is wrong ('0' instead of '00')" do
    expected = %{
      players: [
        %Person{
          id: &is_integer/1,
          fname: "Larry",
          lname: "Bird",
          position: :forward,
          jersey_num: "33"
        },
        %Person{
          id: 979,
          fname: &is_binary/1,
          lname: "McHale",
          position: :forward,
          jersey_num: "32"
        },
        %Person{
          id: 1187,
          fname: "Robert",
          lname: &(String.length(&1) > 4),
          position: :center,
          jersey_num: "0"
        }
      ]
    }

    refute RSM.matches?(expected, celtics_actual(), %{suppress_warnings: true})
  end

  test "single-level, key-valued maps" do
    expected = %{best_beatle: %{fname: "John", lname: "Lennon"}}
    actual = %{best_beatle: %{fname: "John", lname: "Lennon"}}
    assert RSM.matches?(expected, actual)
  end

  test "multi-level, key-valued maps" do
    expected = %{best_beatle: %{fname: "John", lname: "Lennon"}}
    actual = %{best_beatle: %{fname: "John", mname: "Winston", lname: "Lennon", born: 1940}}
    assert RSM.matches?(expected, actual)
  end

  test "map with an expected value of :anything and an actual value of a list" do
    expected = %{team: "Red Sox", players: :anything}

    actual = %{
      team: "Red Sox",
      players: [
        "Mookie Betts",
        "Xander Bogaerts",
        "Hanley Ramirez",
        "Jackie Bradley Jr",
        "Chris Sale",
        "Rick Porcello",
        "David Price"
      ]
    }

    assert RSM.matches?(expected, actual)
  end

  test "map with an expected value of :any_list and an actual value of a list" do
    expected = %{team: "Red Sox", players: :any_list}

    actual = %{
      team: "Red Sox",
      players: [
        "Mookie Betts",
        "Xander Bogaerts",
        "Hanley Ramirez",
        "Jackie Bradley Jr",
        "Chris Sale",
        "Rick Porcello",
        "David Price"
      ]
    }

    assert RSM.matches?(expected, actual)
  end

  test "map with an expected value of :any_map and an actual value of a list" do
    expected = %{team: "Red Sox", players: :any_map}

    actual = %{
      team: "Red Sox",
      players: [
        "Mookie Betts",
        "Xander Bogaerts",
        "Hanley Ramirez",
        "Jackie Bradley Jr",
        "Chris Sale",
        "Rick Porcello",
        "David Price"
      ]
    }

    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "map with an expected value of :any_map and an actual value of a map" do
    expected = %{team: "Red Sox", players: :any_map}

    actual = %{
      team: "Red Sox",
      players: %{
        right_field: "Mookie Betts",
        third_base: "Xander Bogaerts",
        dh: "Hanley Ramirez",
        center_field: "Jackie Bradley Jr",
        p1: "Chris Sale",
        p3: "Rick Porcello",
        p2: "David Price"
      }
    }

    assert RSM.matches?(expected, actual)
  end

  test ":any_datetime matches a DateTime{}" do
    assert RSM.matches?(:any_datetime, DateTime.utc_now())
  end

  test ":any_datetime doesn't match a UTCDateTime{}" do
    refute RSM.matches?(:any_datetime, UTCDateTime.utc_now())
  end

  test ":any_datetime doesn't match a NaiveDateTime{}" do
    refute RSM.matches?(:any_datetime, NaiveDateTime.utc_now())
  end

  test ":any_utc_datetime doesn't match a DateTime{}" do
    refute RSM.matches?(:any_utc_datetime, DateTime.utc_now())
  end

  test ":any_utc_datetime matches a UTCDateTime{}" do
    assert RSM.matches?(:any_utc_datetime, UTCDateTime.utc_now())
  end

  test ":any_utc_datetime doesn't match a NaiveDateTime{}" do
    refute RSM.matches?(:any_utc_datetime, NaiveDateTime.utc_now())
  end

  test ":any_naive_datetime doesn't match a DateTime{}" do
    refute RSM.matches?(:any_naive_datetime, DateTime.utc_now())
  end

  test ":any_naive_datetime matches a NaiveDateTime{}" do
    assert RSM.matches?(:any_naive_datetime, NaiveDateTime.utc_now())
  end

  test ":any_naive_datetime doesn't match a UTCDateTime{}" do
    refute RSM.matches?(:any_naive_datetime, UTCDateTime.utc_now())
  end

  test ":any_iso8601_datetime with :data_fetched_at" do
    assert RSM.matches?(:any_iso8601_datetime, celtics_actual()[:data_fetched_at])
  end

  test ":any_iso8601_date" do
    assert RSM.matches?(:any_iso8601_date, "2018-12-25")
  end

  test ":any_iso8601_date when invalid month" do
    refute RSM.matches?(:any_iso8601_date, "2018-13-25")
  end

  test ":any_iso8601_date when invalid day" do
    refute RSM.matches?(:any_iso8601_date, "2018-09-33")
  end

  test ":any_iso8601_time" do
    assert RSM.matches?(:any_iso8601_time, "11:54:09")
  end

  test ":any_iso8601_time when invalid second" do
    refute RSM.matches?(:any_iso8601_time, "11:54:69")
  end

  test ":any_iso8601_datetime with 'T' between date and time" do
    assert RSM.matches?(:any_iso8601_datetime, "2018-12-25T13:51:11")
  end

  test ":any_iso8601_datetime with valid date/time in distant past" do
    assert RSM.matches?(:any_iso8601_datetime, "1009-02-13 13:51:11")
  end

  test ":any_iso8601_datetime with valid date/time in far future" do
    assert RSM.matches?(:any_iso8601_datetime, "9999-02-13 13:51:11")
  end

  test ":any_iso8601_datetime with invalid minute 61" do
    refute RSM.matches?(:any_iso8601_datetime, "2017-02-13 13:61:11")
  end

  test ":any_iso8601_datetime with invalid second 60" do
    refute RSM.matches?(:any_iso8601_datetime, "2017-02-13 13:11:60")
  end

  test ":any_iso8601_datetime with invalid hour 24" do
    refute RSM.matches?(:any_iso8601_datetime, "2017-02-13T24:11:11")
  end

  test ":any_iso8601_datetime with invalid hour 35" do
    refute RSM.matches?(:any_iso8601_datetime, "2017-02-13 35:11:11")
  end

  test "map with an expected value of :any_integer and an actual value of an integer" do
    expected = %{team: "Red Sox", current_standing: :any_integer}
    actual = %{team: "Red Sox", current_standing: 1}
    assert RSM.matches?(expected, actual)
  end

  test "map with an expected value of :any_integer and an actual value of a non-integer" do
    expected = %{team: "Red Sox", current_standing: :any_integer}
    actual = %{team: "Red Sox", current_standing: "1"}

    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) =~
             "[error] Key :current_standing is expected to have a value of :any_integer (according to %{current_standing: :any_integer, team: \"Red Sox\"}) but has a value of \"1\" (in %{current_standing: \"1\", team: \"Red Sox\"})"

    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) =~
             "[error] %{current_standing: \"1\", team: \"Red Sox\"} does not match %{current_standing: :any_integer, team: \"Red Sox\"}"
  end

  test "map with an expected value of :any_binary and an actual value of a binary" do
    expected = %{team: "Red Sox", current_standing: :any_binary}
    actual = %{team: "Red Sox", current_standing: "1"}
    assert RSM.matches?(expected, actual)
  end

  test "map with an expected value of :any_binary and an actual value of a non-binary" do
    expected = %{team: "Red Sox", current_standing: :any_binary}
    actual = %{team: "Red Sox", current_standing: 1}

    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) =~
             "[error] %{current_standing: 1, team: \"Red Sox\"} does not match %{current_standing: :any_binary, team: \"Red Sox\"}"

    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) =~
             "[error] Key :current_standing is expected to have a value of :any_binary (according to %{current_standing: :any_binary, team: \"Red Sox\"}) but has a value of 1 (in %{current_standing: 1, team: \"Red Sox\"})"
  end

  test "struct with an expected value of :any_binary and an actual value of a binary treated like an equivalent map" do
    expected = %TestStruct{fname: "Larry", lname: :any_binary, hof: :any_boolean}
    actual = %TestStruct{fname: "Larry", lname: "Bird", hof: true}
    assert RSM.matches?(expected, actual)
  end

  test "structs of different types don't match" do
    expected = %TestStruct{fname: "Larry", lname: "Bird", hof: true}
    actual = %AnotherTestStruct{fname: "Larry", lname: "Bird", hof: true}

    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) =~
             "[error] AnotherTestStruct does not match TestStruct"
  end

  test "map with an expected value of :any_atom and an actual value of an atom" do
    expected = %{team: "Red Sox", current_standing: :any_atom}
    actual = %{team: "Red Sox", current_standing: :first}
    assert RSM.matches?(expected, actual)
  end

  test "map with an expected value of :any_atom and an actual value of a non-atom" do
    expected = %{team: "Red Sox", current_standing: :any_atom}
    actual = %{team: "Red Sox", current_standing: 1}

    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) =~
             "[error] Key :current_standing is expected to have a value of :any_atom (according to %{current_standing: :any_atom, team: \"Red Sox\"}) but has a value of 1 (in %{current_standing: 1, team: \"Red Sox\"})"

    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) =~
             "[error] %{current_standing: 1, team: \"Red Sox\"} does not match %{current_standing: :any_atom, team: \"Red Sox\"}"
  end

  test "basic logging" do
    expected = %{team: "Red Sox", players: ["Mookie Betts", "Xander Bogaerts"]}
    actual = %{team: "Red Sox", players: ["Mookie Betts"]}

    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) =~
             "[error] Key :players is expected to have a value of [\"Mookie Betts\", \"Xander Bogaerts\"] (according to %{players: [\"Mookie Betts\", \"Xander Bogaerts\"], team: \"Red Sox\"}) but has a value of [\"Mookie Betts\"] (in %{players: [\"Mookie Betts\"], team: \"Red Sox\"})"
  end

  test "map with an expected value of :any_tuple and an actual value of a list" do
    expected = %{team: "Red Sox", players: :any_tuple}

    actual = %{
      team: "Red Sox",
      players: [
        "Mookie Betts",
        "Xander Bogaerts",
        "Hanley Ramirez",
        "Jackie Bradley Jr",
        "Chris Sale",
        "Rick Porcello",
        "David Price"
      ]
    }

    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) =~
             ~s/[error] Key :players is expected to have a value of :any_tuple (according to %{players: :any_tuple, team: "Red Sox"}) but has a value of ["Mookie Betts", "Xander Bogaerts", "Hanley Ramirez", "Jackie Bradley Jr", "Chris Sale", "Rick Porcello", "David Price"] (in %{players: ["Mookie Betts", "Xander Bogaerts", "Hanley Ramirez", "Jackie Bradley Jr", "Chris Sale", "Rick Porcello", "David Price"], team: "Red Sox"})/

    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) =~
             "[error] %{players: [\"Mookie Betts\", \"Xander Bogaerts\", \"Hanley Ramirez\", \"Jackie Bradley Jr\", \"Chris Sale\", \"Rick Porcello\", \"David Price\"], team: \"Red Sox\"} does not match %{players: :any_tuple, team: \"Red Sox\"}"
  end

  test "map with an expected value of :any_tuple and an actual value of a tuple" do
    expected = %{team: "Red Sox", players: :any_tuple}

    actual = %{
      team: "Red Sox",
      players:
        {"Mookie Betts", "Xander Bogaerts", "Hanley Ramirez", "Jackie Bradley Jr", "Chris Sale",
         "Rick Porcello", "David Price"}
    }

    assert RSM.matches?(expected, actual, %{})
    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) == ""
  end

  test "single-level, key-valued maps don't ignore differences between string & atom keys" do
    expected = %{best_beatle: %{fname: "John", lname: "Lennon"}}
    actual = %{"best_beatle" => %{fname: "John", lname: "Lennon"}}

    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) =~
             "[error] Key :best_beatle not present in %{\"best_beatle\" => %{fname: \"John\", lname: \"Lennon\"}} but present in %{best_beatle: %{fname: \"John\", lname: \"Lennon\"}}"

    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) =~
             "[error] %{\"best_beatle\" => %{fname: \"John\", lname: \"Lennon\"}} does not match %{best_beatle: %{fname: \"John\", lname: \"Lennon\"}}"
  end

  test "multi-level, key-valued maps don't ignore differences between string & atom keys" do
    expected = %{best_beatle: %{fname: "John", lname: "Lennon"}}

    actual = %{
      best_beatle: %{"fname" => "John", "mname" => "Winston", "lname" => "Lennon", "born" => 1940}
    }

    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) =~
             "[error] Key :best_beatle is expected to have a value of %{fname: \"John\", lname: \"Lennon\"} (according to %{best_beatle: %{fname: \"John\", lname: \"Lennon\"}}) but has a value of %{\"born\" => 1940, \"fname\" => \"John\", \"lname\" => \"Lennon\", \"mname\" => \"Winston\"} (in %{best_beatle: %{\"born\" => 1940, \"fname\" => \"John\", \"lname\" => \"Lennon\", \"mname\" => \"Winston\"}})"

    assert capture_log(fn -> RSM.matches?(expected, actual, %{}) end) =~
             "[error] %{best_beatle: %{\"born\" => 1940, \"fname\" => \"John\", \"lname\" => \"Lennon\", \"mname\" => \"Winston\"}} does not match %{best_beatle: %{fname: \"John\", lname: \"Lennon\"}}"
  end

  test "single-level, key-valued maps ignore differences between string & atom keys when standardize_keys: true" do
    expected = %{best_beatle: %{fname: "John", lname: "Lennon"}}
    actual = %{"best_beatle" => %{fname: "John", lname: "Lennon"}}
    assert RSM.matches?(expected, actual, %{standardize_keys: true})
  end

  test "multi-level, key-valued maps ignore differences between string & atom keys when standardize_keys: true" do
    expected = %{best_beatle: %{"fname" => "John", "lname" => "Lennon"}}
    actual = %{"best_beatle" => %{fname: "John", mname: "Winston", lname: "Lennon", born: 1940}}
    assert RSM.matches?(expected, actual, %{standardize_keys: true})
  end

  test "single-level list when identical" do
    expected = ["apple", "banana", "cherry"]
    actual = ["apple", "banana", "cherry"]
    assert RSM.matches?(expected, actual)
  end

  test "single-level list when actual has extra values" do
    expected = ["apple", "banana", "cherry"]
    actual = ["apple", "banana", "cherry", "strawberry"]
    assert RSM.matches?(expected, actual)
  end

  test "single-level list when expected has extra values" do
    expected = ["apple", "banana", "cherry", "strawberry"]
    actual = ["apple", "banana", "cherry"]
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "multi-level lists when expected has extra string value" do
    expected = ["apple", "banana", ["cherry", "grape"], "strawberry"]
    actual = ["apple", "banana", ["cherry", "grape"]]
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "multi-level lists when expected has extra string and list values" do
    expected = ["apple", "banana", ["cherry", "grape"], "strawberry", ["peach", "apricot"]]
    actual = ["apple", "banana", ["cherry", "grape"]]
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "multi-level lists when actual has extra string value" do
    expected = ["apple", "banana", ["cherry", "grape"]]
    actual = ["apple", "banana", ["cherry", "grape"], "strawberry"]
    assert RSM.matches?(expected, actual)
  end

  test "multi-level lists when actual has extra string and list values" do
    expected = ["apple", "banana", ["cherry", "grape"]]
    actual = ["apple", "banana", ["cherry", "grape"], "strawberry", ["peach", "apricot"]]
    assert RSM.matches?(expected, actual)
  end

  test "multi-level, mixed map & list data structures" do
    expected = %{
      best_beatle: %{fname: "John", lname: "Lennon", cities: ["Liverpool", "New York"]}
    }

    actual = %{
      best_beatle: %{
        fname: "John",
        mname: "Winston",
        lname: "Lennon",
        born: 1940,
        cities: ["Liverpool", "New York"]
      }
    }

    assert RSM.matches?(expected, actual)
  end

  test "expected values of :anything are ignored" do
    expected = %{best_beatle: %{fname: "John", mname: :anything, lname: "Lennon"}}
    actual = %{best_beatle: %{fname: "John", mname: "Winston", lname: "Lennon", born: 1940}}
    assert RSM.matches?(expected, actual)
  end

  test "expected values of :anything must exist in actual" do
    expected = %{best_beatle: %{fname: "John", mname: :anything, lname: "Lennon"}}
    actual = %{best_beatle: %{fname: "John", lname: "Lennon", born: 1940}}
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "single-level tuple" do
    expected = {1, "banana"}
    actual = {1, "banana"}
    assert RSM.matches?(expected, actual)
  end

  test "single-level tuple when not matching" do
    expected = {1, "banana"}
    actual = {2, "banana"}
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "multi-level tuple" do
    expected = {1, {"banana", "bananas"}}
    actual = {1, {"banana", "bananas"}}
    assert RSM.matches?(expected, actual)
  end

  test "multi-level tuple when not matching" do
    expected = {1, {"banana", "yellow"}}
    actual = {1, {"banana", "green"}}
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test "single-level tuple with :anything" do
    expected = {1, :anything}
    actual = {1, "banana"}
    assert RSM.matches?(expected, actual)
  end

  test ":any_time matches Time values" do
    expected = :any_time
    actual = ~T[11:13:12.032]
    assert RSM.matches?(expected, actual)
  end

  test ":any_time doesn't match Date values" do
    expected = :any_time
    actual = ~D[2018-11-09]
    refute RSM.matches?(expected, actual)
  end

  test ":any_date matches Date values" do
    expected = :any_date
    actual = ~D[2018-11-09]
    assert RSM.matches?(expected, actual)
  end

  test ":any_date doesn't match Time values" do
    expected = :any_date
    actual = ~T[11:13:12.032]
    refute RSM.matches?(expected, actual)
  end

  test ":any_pos_integer matches 3" do
    expected = :any_pos_integer
    actual = 3
    assert RSM.matches?(expected, actual)
  end

  test ":any_pos_integer doesn't match 3.5" do
    expected = :any_pos_integer
    actual = 3.5
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_pos_integer doesn't match 0" do
    expected = :any_pos_integer
    actual = 0
    refute RSM.matches?(expected, actual)
  end

  test ":any_pos_integer doesn't match -4" do
    expected = :any_pos_integer
    actual = -4
    refute RSM.matches?(expected, actual)
  end

  test ":any_non_neg_integer matches 3" do
    expected = :any_non_neg_integer
    actual = 3
    assert RSM.matches?(expected, actual)
  end

  test ":any_non_neg_integer doesn't match 3.5" do
    expected = :any_non_neg_integer
    actual = 3.5
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_non_neg_integer matches 0" do
    expected = :any_non_neg_integer
    actual = 0
    assert RSM.matches?(expected, actual)
  end

  test ":any_non_neg_integer doesn't match -4" do
    expected = :any_non_neg_integer
    actual = -4
    refute RSM.matches?(expected, actual)
  end

  test ":any_float doesn't match 3" do
    expected = :any_float
    actual = 3
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_float matches 3.5" do
    expected = :any_float
    actual = 3.5
    assert RSM.matches?(expected, actual)
  end

  test ":any_float doesn't match 0" do
    expected = :any_float
    actual = 0
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_float matches 0.0" do
    expected = :any_float
    actual = 0.0
    assert RSM.matches?(expected, actual)
  end

  test ":any_float matches -3.5" do
    expected = :any_float
    actual = -3.5
    assert RSM.matches?(expected, actual)
  end

  test ":any_float doesn't match -4" do
    expected = :any_float
    actual = -4
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_pos_float doesn't match 3" do
    expected = :any_pos_float
    actual = 3
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_pos_float matches 3.5" do
    expected = :any_pos_float
    actual = 3.5
    assert RSM.matches?(expected, actual)
  end

  test ":any_pos_float doesn't match 0" do
    expected = :any_pos_float
    actual = 0
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_pos_float doesn't match 0.0" do
    expected = :any_pos_float
    actual = 0.0
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_pos_float doesn't match -3.5" do
    expected = :any_pos_float
    actual = -3.5
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_pos_float doesn't match -4" do
    expected = :any_pos_float
    actual = -4
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_non_neg_float doesn't match 3" do
    expected = :any_non_neg_float
    actual = 3
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_non_neg_float matches 3.5" do
    expected = :any_non_neg_float
    actual = 3.5
    assert RSM.matches?(expected, actual)
  end

  test ":any_non_neg_float doesn't match 0" do
    expected = :any_non_neg_float
    actual = 0
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_non_neg_float matches 0.0" do
    expected = :any_non_neg_float
    actual = 0.0
    assert RSM.matches?(expected, actual)
  end

  test ":any_non_neg_float doesn't match -3.5" do
    expected = :any_non_neg_float
    actual = -3.5
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_non_neg_float doesn't match -4" do
    expected = :any_non_neg_float
    actual = -4
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_number matches 3" do
    expected = :any_number
    actual = 3
    assert RSM.matches?(expected, actual)
  end

  test ":any_number matches 3.5" do
    expected = :any_number
    actual = 3.5
    assert RSM.matches?(expected, actual)
  end

  test ":any_number matches 0" do
    expected = :any_number
    actual = 0
    assert RSM.matches?(expected, actual)
  end

  test ":any_number matches 0.0" do
    expected = :any_number
    actual = 0.0
    assert RSM.matches?(expected, actual)
  end

  test ":any_number matches -3.5" do
    expected = :any_number
    actual = -3.5
    assert RSM.matches?(expected, actual)
  end

  test ":any_number matches -4" do
    expected = :any_number
    actual = -4
    assert RSM.matches?(expected, actual)
  end

  test ":any_pos_number matches 3" do
    expected = :any_pos_number
    actual = 3
    assert RSM.matches?(expected, actual)
  end

  test ":any_pos_number matches 3.5" do
    expected = :any_pos_number
    actual = 3.5
    assert RSM.matches?(expected, actual)
  end

  test ":any_pos_number doesn't match 0" do
    expected = :any_pos_number
    actual = 0
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_pos_number doesn't match 0.0" do
    expected = :any_pos_number
    actual = 0.0
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_pos_number doesn't match -3.5" do
    expected = :any_pos_number
    actual = -3.5
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_pos_number doesn't match -4" do
    expected = :any_pos_number
    actual = -4
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_non_neg_number matches 3" do
    expected = :any_non_neg_number
    actual = 3
    assert RSM.matches?(expected, actual)
  end

  test ":any_non_neg_number matches 3.5" do
    expected = :any_non_neg_number
    actual = 3.5
    assert RSM.matches?(expected, actual)
  end

  test ":any_non_neg_number matches 0" do
    expected = :any_non_neg_number
    actual = 0
    assert RSM.matches?(expected, actual)
  end

  test ":any_non_neg_number matches 0.0" do
    expected = :any_non_neg_number
    actual = 0.0
    assert RSM.matches?(expected, actual)
  end

  test ":any_non_neg_number doesn't match -3.5" do
    expected = :any_non_neg_number
    actual = -3.5
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_non_neg_number doesn't match -4" do
    expected = :any_non_neg_number
    actual = -4
    refute RSM.matches?(expected, actual, %{suppress_warnings: true})
  end

  test ":any_reference matches a reference" do
    expected = :any_reference
    actual = make_ref()
    assert RSM.matches?(expected, actual)
  end

  test ":any_port matches a port" do
    expected = :any_port
    {:ok, port} = :gen_udp.open(0)
    assert RSM.matches?(expected, port)
  end

  test ":any_pid matches a pid" do
    expected = :any_pid
    {:ok, pid} = StringIO.open("")
    assert RSM.matches?(expected, pid)
  end

  test ":any_bitstring matches a bitstring" do
    expected = :any_bitstring
    bitstring = <<"josé"::bitstring>>
    assert RSM.matches?(expected, bitstring)
  end

  test ":any_reference doesn't match a port" do
    expected = :any_reference
    {:ok, port} = :gen_udp.open(0)
    refute RSM.matches?(expected, port, %{suppress_warnings: true})
  end

  test ":any_port doesn't match a reference" do
    expected = :any_port
    ref = make_ref()
    refute RSM.matches?(expected, ref, %{suppress_warnings: true})
  end

  test ":any_pid doesn't match a bitstring" do
    expected = :any_pid
    bitstring = <<"josé"::bitstring>>
    refute RSM.matches?(expected, bitstring, %{suppress_warnings: true})
  end

  test ":any_bitstring doesn't match a pid" do
    expected = :any_bitstring
    {:ok, pid} = StringIO.open("")
    refute RSM.matches?(expected, pid, %{suppress_warnings: true})
  end
end
