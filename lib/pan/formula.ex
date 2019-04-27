defmodule Pan.Formula do
  defstruct [:ast, :variables]

  def refers?(%__MODULE__{variables: variables}, variable) do
    Enum.find(variables, fn
      {var, :i, _} -> var == variable
      var -> var == variable
    end)
  end

  def build(ast, all_variables) do
    {_, variables} =
      Macro.postwalk(ast, MapSet.new(), fn ast, variables ->
        variables =
          case ast do
            {var, _, nil} ->
              if Enum.member?(all_variables, var) do
                MapSet.put(variables, var)
              else
                variables
              end

            {:first, _, [{var, _, nil}]} ->
              if Enum.member?(all_variables, var) do
                MapSet.delete(variables, var)
                |> MapSet.put({var, :i, 0})
              else
                variables
              end

            {:previous, _, [{var, _, nil}]} ->
              if Enum.member?(all_variables, var) do
                MapSet.delete(variables, var)
                |> MapSet.put({var, :i, -1})
              else
                variables
              end

            {:current, _, [{var, _, nil}]} ->
              if Enum.member?(all_variables, var) do
                MapSet.delete(variables, var)
                |> MapSet.put({var, :i, :i})
              else
                variables
              end

            _ ->
              variables
          end

        {ast, variables}
      end)

    %Pan.Formula{ast: ast, variables: variables}
  end

  def merge([formula]), do: formula

  def merge([f1 | [f2 | rest]]) do
    merge([
      %Pan.Formula{
        variables: MapSet.union(f1.variables, f2.variables),
        ast: {:&&, [], [f1.ast, f2.ast]}
      }
      | rest
    ])
  end

  def constant(value) do
    %Pan.Formula{
      variables: MapSet.new(),
      ast: Macro.escape(value)
    }
  end
end
