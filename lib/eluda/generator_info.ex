defmodule Eluda.GeneratorInfo do
  defstruct [:index, :symbol, :range]

  @type t() :: %__MODULE__{
          # index: integer(),
          symbol: atom(),
          range: Range.t()
        }
end
