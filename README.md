# Pan

This is an experiment at implementing Complex Event Processing system
via Macros. The implementation is loosely based on the paper
[Efficient Pattern Matching over Event Streams](https://people.cs.umass.edu/~yanlei/publications/sase-sigmod08.pdf). Instead of using an interpreter
which handles the NFA state changes, the code is generated during
compile time which theoretically speaking should be faster because we
remove the entire interpreter.



```elixir
defmodule Example do
  def is_alert(alert) do
    alert.event == "alert"
  end

  def is_shipment(shipment) do
    shipment.event == "shipment"
  end

  automata :logistics,
    pattern: [Alert :: a, [Shipment] :: s],
    contiguity: :skip_till_any_match,
    partition_by: [:org],
    where:
      a.type == "contaminated" && first(s).from == a.site && current(s).from == previous(s).to
end
```

```elixir
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
```
