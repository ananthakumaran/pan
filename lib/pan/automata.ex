defmodule Pan.Automata do
  alias Pan.Formula
  alias Pan.Run

  @doc false
  defmacro __using__(_) do
    quote do
      import Pan.Automata, only: [automata: 2]
      import Kernel, except: [length: 1]
      require Pan.Automata.Kernel
      import Pan.Automata.Kernel
    end
  end

  defmodule State do
    defstruct [:runs, :run_expiration, matches: []]
  end

  defmacro automata(name, kw) do
    states = parse(kw)
    contiguity = Keyword.get(kw, :contiguity, :strict)

    Enum.map(Enum.with_index(states), fn {state, i} ->
      next = Enum.drop(states, i + 1)

      bindings =
        Enum.take(states, i)
        |> Enum.map(fn s ->
          if Formula.refers?(state.predicate, s.variable) do
            {s.id, Macro.var(s.variable, nil)}
          else
            Macro.var(:_, nil)
          end
        end)
        |> Enum.reverse()

      Pan.NFAState.compile(name, state, bindings, next, contiguity)
    end) ++
      [
        quote location: :keep do
          def unquote(name)() do
            %Pan.Automata.State{runs: %{}, run_expiration: :queue.new()}
          end
        end,
        process(name, states, kw)
      ]
  end

  defp process(name, states, kw) do
    partition_by = Keyword.get(kw, :partition_by)
    within = Keyword.get(kw, :within, 0)

    quote location: :keep do
      def unquote(name)(event, state, time \\ 0) do
        begin_run_id = System.unique_integer()

        begin_run = %Run{
          id: begin_run_id,
          next: unquote(hd(states).id),
          start_time: time
        }

        unquote(
          if within > 0 do
            quote do
              {runs, run_expiration} =
                Run.prune_old_runs(state.runs, state.run_expiration, time - unquote(within))

              state = %{state | runs: runs}
            end
          end
        )

        unquote(
          if partition_by do
            quote do
              partition_key = get_in(event, unquote(partition_by))
              runs = Map.get(state.runs, partition_key, %{})
              state = %{state | runs: Map.delete(state.runs, partition_key)}
            end
          else
            quote do
              runs = state.runs
              state = %{state | runs: %{}}
            end
          end
        )

        runs = Map.put(runs, begin_run.id, [begin_run])

        state =
          Enum.reduce(
            runs,
            state,
            fn {run_id, runs}, state ->
              Enum.reduce(runs, state, fn run, state ->
                %{matches: matches, branches: branches} =
                  unquote(name)(event, run.next, run.bindings, run.partial_match)

                if branches == [] do
                  %{state | matches: matches ++ state.matches}
                else
                  next_runs =
                    Enum.map(branches, fn branch ->
                      %{
                        run
                        | next: branch.next,
                          bindings: branch.bindings,
                          partial_match: branch.partial_match
                      }
                    end)

                  runs =
                    unquote(
                      if partition_by do
                        quote do
                          if Map.has_key?(state.runs, partition_key) do
                            update_in(
                              state.runs,
                              [partition_key, run_id],
                              &(next_runs ++ (&1 || []))
                            )
                          else
                            Map.put(state.runs, partition_key, %{run_id => next_runs})
                          end
                        end
                      else
                        quote do
                          Map.update(state.runs, run_id, next_runs, &(next_runs ++ &1))
                        end
                      end
                    )

                  %{state | runs: runs, matches: matches ++ state.matches}
                end
              end)
            end
          )

        unquote(
          if within > 0 do
            if partition_by do
              quote do
                if get_in(state.runs, [partition_key, begin_run_id]) do
                  state = %{
                    state
                    | run_expiration:
                        :queue.in({time, partition_key, begin_run_id}, run_expiration)
                  }
                else
                  %{state | run_expiration: run_expiration}
                end
              end
            else
              quote do
                if Map.has_key?(state.runs, begin_run_id) do
                  state = %{
                    state
                    | run_expiration: :queue.in({time, begin_run_id}, run_expiration)
                  }
                else
                  %{state | run_expiration: run_expiration}
                end
              end
            end
          else
            quote do
              state
            end
          end
        )
      end
    end
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

    Formula.group_by_state(formulas, states)
    |> Enum.map(fn {state, formulas} ->
      {post, pre} = Enum.split_with(formulas, &Formula.post?/1)
      %{state | predicate: Formula.merge(pre), post_predicate: Formula.merge(post)}
    end)
  end
end
