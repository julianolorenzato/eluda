defmodule Eluda do
  @moduledoc """
  Documentation for `Eluda`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Eluda.hello()
      :world

  """
  @on_load :load_nifs

  def load_nifs() do
    :erlang.load_nif(~c"./c_src/eluda", 0)
  end

  def loop_nif(list) do
    raise "loop/0 was not implemented!"
  end

  defmacro gpu({:<-, _, [_var, enumerable]} = generator, [do: operation] = statement)

    

  end

  defmacro map({:<-, _, [_var, enumerable]} = generator, [do: operation] = statement) do
    quote do
      unquote(enumerable)
      |> Enum.to_list()
      |> loop_nif()
    end
  end

  defmacro reduce({:<-, _, [_var, enumerable] = generator, [do: operation] = statement}) do
  end

  defmacro filter({:<-, _, [_var, enumerable] = generator, [do: operation] = statement}) do
    # chama nif baseado no statement
  end
end

Eluda.reduce(n, a <- [1, 2, 3, 4], 0, do: a + n)

Eluda.map(n <- [1, 2, 3, 4], do: n * n)

Eluda.filter(n <- [1, 2, 3, 4], do: rem(n, 2) == 0)

gpu n <- [1, 2] do

end
