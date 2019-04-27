defmodule PanTest do
  use ExUnit.Case

  test "automata" do
    events = [1, 2, 4, 5, 6]

    %{matches: matches} =
      Enum.reduce(events, StockAutomata.loop(), fn event, state ->
        StockAutomata.loop(event, state)
      end)

    IO.inspect(matches)
  end
end
