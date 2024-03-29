defmodule Mex do
  defmacro mex(do: block) do
    block
    |> Macro.expand(__CALLER__)
    |> Macro.to_string()
    |> Code.format_string!()
    |> IO.puts()

    block
  end
end
