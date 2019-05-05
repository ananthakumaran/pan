defmodule Example do
  import Mex
  require Integer
  use Pan.Automata

  def scan(_x) do
    true
  end

  mex do
    automata :loop_skip_till_any_match,
      contiguity: :skip_till_any_match,
      pattern: [scan :: a, [scan] :: b],
      where: Integer.is_even(a) && Integer.is_odd(current(b)) && current(b) > previous(b)
  end

  automata :loop_skip_till_next_match,
    contiguity: :skip_till_next_match,
    pattern: [scan :: a, [scan] :: b],
    where: Integer.is_even(a) && Integer.is_odd(current(b))

  automata :loop_strict,
    contiguity: :strict,
    pattern: [scan :: a, [scan] :: b],
    where: Integer.is_even(a) && Integer.is_odd(current(b))

  automata :logistics,
    pattern: [alert :: a, [shipment] :: s],
    contiguity: :skip_till_any_match,
    partition_by: [:org],
    where:
      a.event == "alert" && a.type == "contaminated" && first(s).event == "shipment" &&
        first(s).from == a.site && current(s).from == previous(s).to

  automata :long,
    contiguity: :skip_till_next_match,
    pattern: [trip :: a, trip :: b, trip :: c],
    partition_by: [:medallion],
    where:
      a.medallion == b.medallion && b.medallion == c.medallion &&
        a.trip_time_in_secs > 60 * 60 * 1 && b.trip_time_in_secs > 60 * 60 * 1 &&
        c.trip_time_in_secs > 60 * 60 * 1
end
