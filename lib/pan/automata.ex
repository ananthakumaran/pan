defmodule Pan.Automata do
  alias Pan.Formula

  @doc false
  defmacro __using__(_) do
    quote do
      import Pan.Automata, only: [automata: 2]
      require Pan.Automata.Kernel
      import Pan.Automata.Kernel
    end
  end

  defmodule Run do
    defstruct [:next, partial_match: [], bindings: []]
  end

  defmodule State do
    defstruct runs: [], matches: []
  end

  defmacro automata(name, kw) do
    states = parse(kw)
    contiguity = Keyword.get(kw, :contiguity, :strict)

    Enum.map(Enum.with_index(states), fn {state, i} ->
      next = Enum.drop(states, i + 1)

      bindings =
        Enum.take(states, i)
        |> Enum.map(&{&1.id, Macro.var(&1.variable, nil)})
        |> Enum.reverse()

      Pan.NFAState.compile(name, state, bindings, next, contiguity)
    end) ++
      [
        quote location: :keep do
          def unquote(name)() do
            %Pan.Automata.State{}
          end
        end,
        quote do
          def unquote(name)(event, state) do
            Enum.reduce(
              [%Run{next: unquote(hd(states).id)}] ++ state.runs,
              %{state | runs: []},
              fn run, state ->
                %{matches: matches, branches: branches} =
                  unquote(name)(event, run.next, run.bindings, run.partial_match)

                next_runs =
                  Enum.map(branches, fn branch ->
                    %{
                      run
                      | next: branch.next,
                        bindings: branch.bindings,
                        partial_match: branch.partial_match
                    }
                  end)

                %{state | runs: next_runs ++ state.runs, matches: matches ++ state.matches}
              end
            )
          end
        end
      ]
  end

  defp parse(kw) do
    states = parse_pattern(kw)
    parse_where(kw, states)
  end

  defp parse_pattern(kw) do
    pattern = Keyword.fetch!(kw, :pattern)

    Enum.flat_map(pattern, &Pan.NFAState.build/1)
    |> Enum.with_index()
    |> Enum.map(fn {state, i} ->
      %{state | position: i}
    end)
  end

  defp parse_where(kw, states) do
    where = Keyword.fetch!(kw, :where)

    variables = Enum.map(states, & &1.variable)

    formulas =
      Pan.ConjuctiveNormalForm.convert(where)
      |> Enum.map(&Formula.build(&1, variables))

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

    states =
      Enum.map(states, fn state ->
        formulas = formulas_by_position[state.position]

        predicate =
          if formulas do
            Formula.merge(formulas)
          else
            Formula.constant(true)
          end

        %{state | predicate: predicate}
      end)

    states
  end
end
