defmodule PanTest do
  use ExUnit.Case

  test "simple" do
    assert sequence(:loop_strict, 0..5) == [[0, 1], [2, 3], [4, 5]]

    assert sequence(:loop_skip_till_next_match, 0..5) == [
             [0, 1],
             [0, 1, 3],
             [2, 3],
             [0, 1, 3, 5],
             [2, 3, 5],
             [4, 5]
           ]

    assert sequence(:loop_skip_till_any_match, 0..5) == [
             [0, 1],
             [0, 1, 3],
             [0, 3],
             [2, 3],
             [0, 1, 3, 5],
             [0, 1, 5],
             [0, 3, 5],
             [0, 5],
             [2, 3, 5],
             [2, 5],
             [4, 5]
           ]

    assert sequence(:loop_length, 0..5) == [
             [0, 1, 3],
             [0, 1, 3, 5],
             [0, 1, 5],
             [0, 3, 5],
             [2, 3, 5]
           ]
  end

  test "logistics" do
    events = [
      %{org: "a", event: "alert", type: "contaminated", site: "A"},
      %{org: "a", event: "shipment", from: "A", to: "B"},
      %{org: "a", event: "shipment", from: "B", to: "C"},
      %{org: "a", event: "shipment", from: "C", to: "D"}
    ]

    %{matches: matches} =
      Enum.reduce(events, Example.logistics(), fn event, state ->
        Example.logistics(event, state)
      end)

    assert matches == [
             [
               %{org: "a", event: "alert", site: "A", type: "contaminated"},
               %{org: "a", event: "shipment", from: "A", to: "B"},
               %{org: "a", event: "shipment", from: "B", to: "C"},
               %{org: "a", event: "shipment", from: "C", to: "D"}
             ],
             [
               %{org: "a", event: "alert", site: "A", type: "contaminated"},
               %{org: "a", event: "shipment", from: "A", to: "B"},
               %{org: "a", event: "shipment", from: "B", to: "C"}
             ],
             [
               %{org: "a", event: "alert", site: "A", type: "contaminated"},
               %{org: "a", event: "shipment", from: "A", to: "B"}
             ]
           ]
  end

  defp sequence(name, events) do
    %{matches: matches} =
      Enum.reduce(events, apply(Example, name, []), fn event, state ->
        apply(Example, name, [event, state])
      end)

    Enum.reverse(matches)
  end
end
