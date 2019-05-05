defmodule Pan.Formula do
  defstruct [:ast, :variables]

  def refers?(%__MODULE__{variables: variables}, variable) do
    Enum.find(variables, fn
      {var, _} -> var == variable
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
                |> MapSet.put({var, :start})
              else
                variables
              end

            {:previous, _, [{var, _, nil}]} ->
              if Enum.member?(all_variables, var) do
                MapSet.delete(variables, var)
                |> MapSet.put({var, :plus})
              else
                variables
              end

            {:current, _, [{var, _, nil}]} ->
              if Enum.member?(all_variables, var) do
                MapSet.delete(variables, var)
                |> MapSet.put({var, :all})
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

  def merge([]), do: constant(true)

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
    formula_by_positions =
      Enum.map(formulas, fn formula ->
        positions =
          Enum.map(formula.variables, fn variable ->
            finder =
              case variable do
                {v, :start} ->
                  fn s -> s.type == :kleene_start && s.variable == v end

                {v, :plus} ->
                  fn s -> s.type == :kleene_plus && s.variable == v end

                {v, :all} ->
                  fn s -> s.type in [:kleene_start, :kleene_plus] && s.variable == v end

                _ ->
                  fn s -> s.type == :single && s.variable == variable end
              end

            Enum.filter(states, finder)
            |> Enum.map(& &1.position)
          end)

        {formula, positions}
      end)

    Enum.map(states, fn state ->
      formulas =
        Enum.filter(formula_by_positions, fn {_formula, positions} ->
          Enum.any?(positions, fn p -> Enum.member?(p, state.position) end) &&
            Enum.all?(positions, fn p -> Enum.min(p, fn -> 0 end) <= state.position end)
        end)
        |> Enum.map(fn {formula, _} -> formula end)

      {state, formulas}
    end)
  end
end
