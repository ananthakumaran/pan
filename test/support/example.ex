defmodule Example do
  import Mex
  require Integer
  use Pan.Automata

  automata :loop_skip_till_any_match,
    contiguity: :skip_till_any_match,
    pattern: [Integer :: a, [Integer] :: b],
    where: Integer.is_even(a) && Integer.is_odd(current(b)) && current(b) > previous(b)

  mex do
    automata :loop_length,
      contiguity: :skip_till_any_match,
      pattern: [Integer :: a, [Integer] :: b],
      where:
        Integer.is_even(a) && Integer.is_odd(current(b)) && current(b) > previous(b) &&
          length(b) >= 2
  end

  automata :loop_skip_till_next_match,
    contiguity: :skip_till_next_match,
    pattern: [Integer :: a, [Integer] :: b],
    where: Integer.is_even(a) && Integer.is_odd(current(b))

  automata :loop_strict,
    contiguity: :strict,
    pattern: [Integer :: a, [Integer] :: b],
    where: Integer.is_even(a) && Integer.is_odd(current(b))

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

  def is_trip(_) do
    true
  end

  automata :long,
    contiguity: :skip_till_next_match,
    pattern: [Trip :: a, Trip :: b, Trip :: c],
    partition_by: [:medallion],
    where:
      a.medallion == b.medallion && b.medallion == c.medallion &&
        a.trip_time_in_secs > 60 * 60 * 1 && b.trip_time_in_secs > 60 * 60 * 1 &&
        c.trip_time_in_secs > 60 * 60 * 1
end
