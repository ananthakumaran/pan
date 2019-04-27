defmodule Example do
  require Integer
  import Mex
  use Pan.Automata

  def scan(_x) do
    true
  end

  mex do
    automata :loop,
      pattern: [scan :: a, scan :: b],
      where: Integer.is_even(a) && b == a + 1 && Integer.is_odd(b)
  end

  mex do
    automata :logistics,
      pattern: [alert :: a, [shipment] :: s],
      where:
        a.event == "alert" && a.type == "contaminated" && first(s).event == "shipment" &&
          first(s).from == a.site && current(s).to == previous(s).from
  end
end
