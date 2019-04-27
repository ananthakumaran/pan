defmodule Pan.Formula do
  defstruct [:ast, :variables]

  def build(ast, all_variables) do
    {_, variables} =
      Macro.prewalk(ast, MapSet.new(), fn ast, variables ->
        variables =
          case ast do
            {var, _, nil} ->
              if Enum.member?(all_variables, var) do
                MapSet.put(variables, var)
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
