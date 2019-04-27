defmodule Example do
  require Integer
  import Mex
  use Pan.Automata

  def scan(_x) do
    true
  end

  mex do
    automata :loop_skip_till_any_match,
      contiguity: :skip_till_any_match,
      pattern: [scan :: a, [scan] :: b],
      where: Integer.is_even(a) && Integer.is_odd(first(b)) && Integer.is_odd(current(b))
  end

  automata :loop_skip_till_next_match,
    contiguity: :skip_till_next_match,
    pattern: [scan :: a, [scan] :: b],
    where: Integer.is_even(a) && Integer.is_odd(first(b)) && Integer.is_odd(current(b))

  automata :loop_strict,
    contiguity: :strict,
    pattern: [scan :: a, [scan] :: b],
    where: Integer.is_even(a) && Integer.is_odd(first(b)) && Integer.is_odd(current(b))

  automata :logistics,
    pattern: [alert :: a, [shipment] :: s],
    contiguity: :skip_till_any_match,
    where:
      a.event == "alert" && a.type == "contaminated" && first(s).event == "shipment" &&
        first(s).from == a.site && current(s).from == previous(s).to
end
