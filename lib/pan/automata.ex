defmodule Pan.Automata do
  alias Pan.Formula

  @doc false
  defmacro __using__(_) do
    quote do
      import Pan.Automata, only: [automata: 2]
      Module.register_attribute(__MODULE__, :pan_automata_definition, accumulate: true)
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

    Enum.map(Enum.with_index(states), fn {state, i} ->
      last? = length(states) == i + 1

      next =
        unless last? do
          Enum.at(states, i + 1)
        end

      bindings =
        Enum.take(states, i)
        |> Enum.map(&{&1.id, Macro.var(&1.variable, nil)})
        |> Enum.reverse()

      quote do
        def unquote(name)(
              __event,
              unquote(state.id),
              __bindings = unquote(bindings),
              __partial_match
            ) do
          unquote(Macro.var(state.variable, nil)) = __event
          __new_bindings = [{unquote(state.variable), __event} | __bindings]

          if unquote(state.predicate.ast) do
            unquote(
              if last? do
                quote do
                  %{matches: [Enum.reverse([__event | __partial_match])], branches: []}
                end
              else
                quote do
                  %{
                    matches: [],
                    branches: [
                      %{
                        next: unquote(next.id),
                        bindings: __new_bindings,
                        partial_match: [__event | __partial_match]
                      }
                    ]
                  }
                end
              end
            )
          else
            %{matches: [], branches: []}
          end
        end
      end
    end) ++
      [
        quote do
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

    Enum.map(pattern, &Pan.NFAState.build/1)
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
            state = Enum.find(states, &(&1.variable == variable))
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
