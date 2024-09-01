defmodule Eluda.ScopeInfo do
  defstruct [:index, :symbol, :shape]

  @type t() :: %__MODULE__{
          # index: integer(),
          symbol: atom(),
          shape: tuple()
        }
end
