defmodule PanTest do
  use ExUnit.Case
  alias Pan.State
  alias Pan.Runner.Naive
  require Integer

  test "pan" do
    automata =
      Pan.compile([
        State.one(:alert, fn alert, _ ->
          alert.event == "alert" && alert.type == "contaminated"
        end),
        State.many(
          :shipments,
          fn shipment, bindings ->
            shipment.event == "shipment" && shipment.from == bindings.alert.site
          end,
          fn _, %{shipments: [current | [previous | _rest]]} ->
            current.event == "shipment" && current.from == previous.to
          end
        )
      ])

    events = [
      %{event: "alert", type: "contaminated", site: "A"},
      %{event: "shipment", from: "A", to: "B"},
      %{event: "shipment", from: "B", to: "C"},
      %{event: "shipment", from: "C", to: "D"}
    ]

    %{matches: matches} =
      Enum.reduce(events, Naive.state(), fn event, state ->
        Naive.execute(event, automata, state)
      end)

    assert matches == [
             [
               %{event: "alert", site: "A", type: "contaminated"},
               %{event: "shipment", from: "A", to: "B"},
               %{event: "shipment", from: "B", to: "C"},
               %{event: "shipment", from: "C", to: "D"}
             ],
             [
               %{event: "alert", site: "A", type: "contaminated"},
               %{event: "shipment", from: "A", to: "B"},
               %{event: "shipment", from: "B", to: "C"}
             ],
             [
               %{event: "alert", site: "A", type: "contaminated"},
               %{event: "shipment", from: "A", to: "B"}
             ]
           ]
  end

  test "sequence" do
    assert sequence(:strict, 0..5) == [[0, 1], [2, 3], [4, 5]]

    assert sequence(:skip_till_next_match, 0..5) == [
             [0, 1],
             [0, 1, 3],
             [2, 3],
             [0, 1, 3, 5],
             [2, 3, 5],
             [4, 5]
           ]

    assert sequence(:skip_till_any_match, 0..5) == [
             [0, 1],
             [0, 3],
             [0, 1, 3],
             [2, 3],
             [0, 5],
             [0, 3, 5],
             [0, 1, 5],
             [0, 1, 3, 5],
             [2, 5],
             [2, 3, 5],
             [4, 5]
           ]
  end

  defp sequence(contiguity, events) do
    automata =
      Pan.compile([
        State.one(:even, fn x, _ -> Integer.is_even(x) end),
        State.many(
          :numbers,
          fn x, _ -> Integer.is_odd(x) end,
          fn y, _ -> Integer.is_odd(y) end,
          contiguity: contiguity
        )
      ])

    %{matches: matches} =
      Enum.reduce(events, Naive.state(), fn event, state ->
        Naive.execute(event, automata, state)
      end)

    Enum.reverse(matches)
  end
end
