defmodule Pan.NFAState do
  defstruct [:position, :id, :name, :variable, :type, :predicate]

  def build({:::, _, [type, {variable, _, _}]}) do
    case type do
      [{name, _, _}] ->
        [
          %__MODULE__{id: variable, name: name, variable: variable, type: :kleene_start},
          %__MODULE__{id: variable, name: name, variable: variable, type: :kleene_plus}
        ]

      {name, _, _} ->
        [%__MODULE__{id: variable, name: name, variable: variable, type: :single}]
    end
  end

  def compile(name, %__MODULE__{type: :single} = state, bindings, next) do
    quote location: :keep do
      def unquote(name)(
            event__,
            unquote(state.id),
            bindings__ = unquote(bindings),
            partial_match__
          ) do
        unquote(Macro.var(state.variable, nil)) = event__
        new_bindings__ = [{unquote(state.variable), event__} | bindings__]

        if unquote(state.predicate.ast) do
          unquote(
            if !next do
              quote do
                %{matches: [Enum.reverse([event__ | partial_match__])], branches: []}
              end
            else
              quote do
                %{
                  matches: [],
                  branches: [
                    %{
                      next: unquote(next.id),
                      bindings: new_bindings__,
                      partial_match: [event__ | partial_match__]
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
  end

  def compile(name, %__MODULE__{type: :kleene_start} = state, bindings, next) do
    quote location: :keep do
      def unquote(name)(
            event__,
            unquote(state.id),
            bindings__ = unquote(bindings),
            partial_match__
          ) do
        unquote(Macro.var(state.variable, nil)) = [event__]

        new_bindings__ = [
          {unquote(state.variable), unquote(Macro.var(state.variable, nil))} | bindings__
        ]

        if unquote(state.predicate.ast) do
          unquote(
            if !next do
              quote do
                %{matches: [Enum.reverse([event__ | partial_match__])], branches: []}
              end
            else
              quote do
                %{
                  matches: [],
                  branches: [
                    %{
                      next: unquote(next.id),
                      bindings: new_bindings__,
                      partial_match: [event__ | partial_match__]
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
  end

  def compile(name, %__MODULE__{type: :kleene_plus} = state, bindings, next) do
    quote location: :keep do
      def unquote(name)(
            event__,
            unquote(state.id),
            bindings__ = unquote(bindings),
            partial_match__
          ) do
        unquote(Macro.var(state.variable, nil)) = [
          event__ | unquote(Macro.var(state.variable, nil))
        ]

        var!(i__) = length(unquote(Macro.var(state.variable, nil))) - 1

        new_bindings__ = [
          {unquote(state.variable), unquote(Macro.var(state.variable, nil))} | tl(bindings__)
        ]

        if unquote(state.predicate.ast) do
          unquote(
            if !next do
              quote do
                %{matches: [Enum.reverse([event__ | partial_match__])], branches: []}
              end
            else
              quote do
                %{
                  matches: [],
                  branches: [
                    %{
                      next: unquote(next.id),
                      bindings: new_bindings__,
                      partial_match: [event__ | partial_match__]
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
  end
end
