defmodule Pan.Runner.Naive do
  defmodule Run do
    defstruct partial_match: [], next: :begin, bindings: %{}
  end

  defmodule State do
    defstruct runs: [], matches: []
  end

  def state() do
    %State{}
  end

  def execute(event, automata, state) do
    Enum.reduce([%Run{}] ++ state.runs, %{state | runs: []}, fn run, state ->
      %{matches: matches, branches: branches} =
        Pan.run(event, automata, run.next, run.bindings, run.partial_match)

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
    end)
  end
end
