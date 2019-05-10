defmodule Pan.NFAState do
  defstruct [
    :position,
    :id,
    :name,
    :variable,
    :type,
    :predicate,
    :post_predicate
  ]

  def build({:::, _, [type, {variable, _, _}]}) do
    case type do
      [{:__aliases__, _, [name]}] ->
        [
          %__MODULE__{id: variable, name: name, variable: variable, type: :kleene_start},
          %__MODULE__{id: variable, name: name, variable: variable, type: :kleene_plus}
        ]

      {:__aliases__, _, [name]} ->
        [%__MODULE__{id: variable, name: name, variable: variable, type: :single}]
    end
  end

  def is_event(%__MODULE__{name: name}) do
    name =
      Atom.to_string(name)
      |> String.downcase()

    predicate_name = String.to_atom("is_" <> name)

    %Pan.Formula{
      variables: MapSet.new(),
      ast:
        quote do
          unquote(predicate_name)(event__)
        end
    }
  end

  def compile(name, %__MODULE__{type: :single} = state, bindings, next, contiguity) do
    quote location: :keep do
      def unquote(name)(
            event__,
            unquote(state.id),
            bindings__ = unquote(bindings),
            partial_match__
          ) do
        unquote(Macro.var(state.variable, nil)) = event__
        new_bindings__ = [{unquote(state.variable), event__} | bindings__]
        result__ = %{matches: [], branches: []}
        predicate_true__ = unquote(state.predicate.ast)

        # begin
        result__ =
          if predicate_true__ do
            unquote(
              update_result(
                next,
                quote(do: result__),
                quote(do: new_bindings__),
                quote(do: [event__ | partial_match__])
              )
            )
          else
            result__
          end

        result__ =
          unquote(
            case contiguity do
              :strict ->
                quote(do: result__)

              :skip_till_next_match ->
                if state.position == 0 do
                  quote(do: result__)
                else
                  # ignore
                  quote do
                    if !predicate_true__ do
                      unquote(
                        update_result(
                          [state | next],
                          quote(do: result__),
                          quote(do: bindings__),
                          quote(do: partial_match__),
                          false
                        )
                      )
                    else
                      result__
                    end
                  end
                end

              :skip_till_any_match ->
                if state.position == 0 do
                  quote(do: result__)
                else
                  # ignore
                  update_result(
                    [state | next],
                    quote(do: result__),
                    quote(do: bindings__),
                    quote(do: partial_match__),
                    false
                  )
                end
            end
          )
      end
    end
  end

  def compile(name, %__MODULE__{type: :kleene_start} = state, bindings, next, contiguity) do
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

        result__ = %{matches: [], branches: []}
        predicate_true__ = unquote(state.predicate.ast)

        # begin
        result__ =
          if predicate_true__ do
            unquote(
              update_result(
                next,
                quote(do: result__),
                quote(do: new_bindings__),
                quote(do: [event__ | partial_match__])
              )
            )
          else
            result__
          end

        result__ =
          unquote(
            case contiguity do
              :strict ->
                quote(do: result__)

              :skip_till_next_match ->
                if state.position == 0 do
                  quote(do: result__)
                else
                  quote do
                    # ignore
                    if !predicate_true__ do
                      unquote(
                        update_result(
                          [state | next],
                          quote(do: result__),
                          quote(do: bindings__),
                          quote(do: partial_match__),
                          false
                        )
                      )
                    else
                      result__
                    end
                  end
                end

              :skip_till_any_match ->
                if state.position == 0 do
                  quote(do: result__)
                else
                  # ignore
                  update_result(
                    [state | next],
                    quote(do: result__),
                    quote(do: bindings__),
                    quote(do: partial_match__),
                    false
                  )
                end
            end
          )
      end
    end
  end

  def compile(name, %__MODULE__{type: :kleene_plus} = state, bindings, next, contiguity) do
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

        new_bindings__ = [
          {unquote(state.variable), unquote(Macro.var(state.variable, nil))} | tl(bindings__)
        ]

        result__ = %{matches: [], branches: []}
        predicate_true__ = unquote(state.predicate.ast)

        # take
        result__ =
          if predicate_true__ do
            unquote(
              update_result(
                [state | next],
                quote(do: result__),
                quote(do: new_bindings__),
                quote(do: [event__ | partial_match__])
              )
            )
          else
            result__
          end

        result__ =
          unquote(
            case contiguity do
              :strict ->
                quote(do: result__)

              :skip_till_next_match ->
                quote do
                  if !predicate_true__ do
                    unquote(
                      update_result(
                        [state | next],
                        quote(do: result__),
                        quote(do: bindings__),
                        quote(do: partial_match__),
                        false
                      )
                    )
                  else
                    result__
                  end
                end

              :skip_till_any_match ->
                update_result(
                  [state | next],
                  quote(do: result__),
                  quote(do: bindings__),
                  quote(do: partial_match__),
                  false
                )
            end
          )
      end
    end
  end

  def update_result(rest, result, bindings, partial_match, follow_proceed \\ true)

  def update_result([], result, _bindings, partial_match, _) do
    quote do
      %{
        unquote(result)
        | matches: [Enum.reverse(unquote(partial_match)) | unquote(result).matches]
      }
    end
  end

  def update_result([next | _], result, bindings, partial_match, false) do
    quote do
      %{
        unquote(result)
        | branches: [
            %{
              next: unquote(next.id),
              bindings: unquote(bindings),
              partial_match: unquote(partial_match)
            }
            | unquote(result).branches
          ]
      }
    end
  end

  def update_result(states = [next | rest], result, bindings, partial_match, true) do
    if next.type == :kleene_plus do
      quote do
        post_predicate_true__ = unquote(next.post_predicate.ast)
        # proceed
        result__ =
          if post_predicate_true__ do
            unquote(update_result(rest, result, bindings, partial_match, true))
          else
            result__
          end

        unquote(update_result(states, quote(do: result__), bindings, partial_match, false))
      end
    else
      update_result(states, result, bindings, partial_match, false)
    end
  end
end
