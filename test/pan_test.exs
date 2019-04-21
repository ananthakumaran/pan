defmodule PanTest do
  use ExUnit.Case
  alias Pan.State
  alias Pan.Runner.Naive

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
end
