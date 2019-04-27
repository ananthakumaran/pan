defmodule Pan.Automata.Kernel do
  defmacro first(x) do
    quote bind_quoted: [x: x] do
      List.first(x)
    end
  end

  defmacro last(x) do
    quote bind_quoted: [x: x] do
      List.last(x)
    end
  end

  defmacro previous(x) do
    quote bind_quoted: [x: x] do
      Enum.at(x, var!(i__) - 1)
    end
  end

  defmacro current(x) do
    quote bind_quoted: [x: x] do
      Enum.at(x, var!(i__))
    end
  end
end
