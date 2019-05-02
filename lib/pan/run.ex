defmodule Pan.Run do
  defstruct [:id, :next, :start_time, partial_match: [], bindings: []]

  def prune_old_runs(runs, run_expiration, cutoff_time) do
    case :queue.peek(run_expiration) do
      {:value, {time, id}} when time < cutoff_time ->
        prune_old_runs(Map.delete(runs, id), :queue.drop(run_expiration), cutoff_time)

      {:value, {time, partition_key, id}} when time < cutoff_time ->
        {_dropped, runs} = pop_in(runs, [partition_key, id])
        prune_old_runs(runs, :queue.drop(run_expiration), cutoff_time)

      _ ->
        {runs, run_expiration}
    end
  end
end
