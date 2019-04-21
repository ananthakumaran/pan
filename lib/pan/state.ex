defmodule Pan.State do
  defstruct [:id, :binding, :edges, :next, proceed: false]

  def one(binding, predicate) do
    %__MODULE__{
      id: System.unique_integer(),
      binding: fn event, bindings ->
        Map.put(bindings, binding, event)
      end,
      edges: [
        fn event, bindings ->
          if predicate.(event, bindings) do
            :begin
          else
            :drop
          end
        end
      ]
    }
  end

  def many(binding, start_predicate, continue_predicate, options \\ []) do
    contiguity = Keyword.get(options, :contiguity, :strict)

    [
      %__MODULE__{
        id: System.unique_integer(),
        binding: fn event, bindings ->
          Map.put(bindings, binding, [event])
        end,
        edges: [
          fn event, bindings ->
            case contiguity do
              :strict ->
                :drop

              :skip_till_next_match ->
                if !start_predicate.(event, bindings) do
                  :ignore
                else
                  :drop
                end

              :skip_till_any_match ->
                :ignore
            end
          end,
          fn event, bindings ->
            if start_predicate.(event, bindings) do
              :begin
            else
              :drop
            end
          end
        ]
      },
      %__MODULE__{
        id: System.unique_integer(),
        binding: fn event, bindings ->
          Map.update!(bindings, binding, &[event | &1])
        end,
        proceed: true,
        edges: [
          fn event, bindings ->
            case contiguity do
              :strict ->
                :drop

              :skip_till_next_match ->
                if !continue_predicate.(event, bindings) do
                  :ignore
                else
                  :drop
                end

              :skip_till_any_match ->
                :ignore
            end
          end,
          fn event, bindings ->
            if continue_predicate.(event, bindings) do
              :take
            else
              :drop
            end
          end
        ]
      }
    ]
  end
end
