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

  def group_by_state(formulas, states) do
    formulas_by_position =
      Enum.map(formulas, fn formula ->
        position =
          Enum.map(formula.variables, fn variable ->
            finder =
              case variable do
                {v, :i, 0} -> fn s -> s.type == :kleene_start && s.variable == v end
                {v, :i, _} -> fn s -> s.type == :kleene_plus && s.variable == v end
                _ -> fn s -> s.variable == variable end
              end

            state = Enum.find(states, finder)
            state.position
          end)
          |> Enum.max(fn -> 0 end)

        {position, formula}
      end)
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

    Enum.map(states, fn state ->
      formulas = formulas_by_position[state.position]
      {state, formulas}
    end)
  end
end
