defmodule Pan.ConjuctiveNormalForm do
  # https://www.cs.jhu.edu/~jason/tutorials/convert-to-CNF.html

  # and
  def convert({:&&, _, [left, right]}) do
    convert(left) ++ convert(right)
  end

  # variable or expression
  def convert(formula) do
    [formula]
  end
end
