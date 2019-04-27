defmodule StockAutomata do
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
end
