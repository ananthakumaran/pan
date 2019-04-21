defmodule Pan do
  def compile(states) do
    [state | rest] = states
    states = [%{state | id: :begin} | rest]

    List.flatten(states)
    |> Enum.chunk_every(2, 1, [:end])
    |> Enum.reduce(%{}, fn
      [current, :end], acc ->
        Map.put(acc, current.id, %{current | next: :end})

      [current, next], acc ->
        Map.put(acc, current.id, %{current | next: next.id})
    end)
  end

  @doc false
  def run(
        event,
        automata,
        current_id,
        bindings,
        partial_match,
        result \\ %{matches: [], branches: []}
      ) do
    current = automata[current_id]
    new_bindings = current.binding.(event, bindings)

    Enum.reduce(current.edges, result, fn edge, result ->
      case edge.(event, new_bindings) do
        :drop ->
          result

        :begin ->
          update_result(
            automata,
            result,
            current.next,
            new_bindings,
            [event | partial_match]
          )

        :take ->
          update_result(automata, result, current.id, new_bindings, [event | partial_match])
      end
    end)
  end

  defp update_result(automata, result, next, bindings, partial_match, follow_proceed \\ true)

  defp update_result(_automata, result, :end, _bindings, partial_match, _) do
    %{
      result
      | matches: [Enum.reverse(partial_match) | result.matches]
    }
  end

  defp update_result(_automata, result, next, bindings, partial_match, false) do
    %{
      result
      | branches: [
          %{
            next: next,
            bindings: bindings,
            partial_match: partial_match
          }
          | result.branches
        ]
    }
  end

  defp update_result(automata, result, next, bindings, partial_match, true) do
    n = automata[next]
    result = update_result(automata, result, next, bindings, partial_match, false)

    if n.proceed do
      update_result(automata, result, n.next, bindings, partial_match, true)
    else
      result
    end
  end
end
