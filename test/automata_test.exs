defmodule PanTest do
  use ExUnit.Case

  test "simple" do
    events = [1, 2, 4, 5, 6]

    %{matches: matches} =
      Enum.reduce(events, Example.loop(), fn event, state ->
        Example.loop(event, state)
      end)

    IO.inspect(matches)
  end

  test "logistics" do
    events = [
      %{event: "alert", type: "contaminated", site: "A"},
      %{event: "shipment", from: "A", to: "B"},
      %{event: "shipment", from: "B", to: "C"},
      %{event: "shipment", from: "C", to: "D"}
    ]

    %{matches: matches} =
      Enum.reduce(events, Example.logistics(), fn event, state ->
        Example.logistics(event, state)
      end)

    IO.inspect(matches)
  end
end
