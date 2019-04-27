defmodule Pan.NFAState do
  defstruct [:position, :id, :name, :variable, :type, :predicate]

  def build({:::, _, [type, {variable, _, _}]}) do
    case type do
      [{name, _, _}] -> %__MODULE__{id: variable, name: name, variable: variable, type: :kleene}
      {name, _, _} -> %__MODULE__{id: variable, name: name, variable: variable, type: :single}
    end
  end
end
