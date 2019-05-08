defmodule Pan.Automata.Kernel do
  defmacro first(x) do
    quote bind_quoted: [x: x] do
      List.last(x)
    end
  end

  defmacro last(x) do
    quote bind_quoted: [x: x] do
      List.first(x)
    end
  end

  defmacro previous(x) do
    quote bind_quoted: [x: x] do
      hd(tl(x))
    end
  end

  defmacro current(x) do
    quote bind_quoted: [x: x] do
      hd(x)
    end
  end

  defmacro length(x) do
    quote bind_quoted: [x: x] do
      Kernel.length(x)
    end
  end
end
