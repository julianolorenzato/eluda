defmodule Eluda do
  @moduledoc """
  Documentation for `Eluda`.
  """

  require Eluda.Transpiler, as: Transpiler

  @on_load :load_nifs

  def load_nifs() do
    :erlang.load_nif(~c"./c_src/eluda", 0)
  end

  def loop_nif(_list) do
    raise "loop_nif/0 was not implemented!"
  end

  def obj_nif() do
    raise "obj_nif/0 was not implemented!"
  end

  @doc """
  The main macro
  """
  defmacro eluda({:<-, _, [_var, enumerable]} = generator, [do: expr] = statement) do
    IO.inspect(enumerable, label: "list: ")
    IO.inspect(expr, label: "expr: ")

    quote do
      code = Transpiler.transpile(unquote(expr))

      File.write("./priv/generated_code.c", code)

      # Compilation
      System.cmd("gcc", [
        "-fPIC",
        "-shared",
        "-o",
        "priv/generated_code.so",
        "priv/generated_code.c"
      ])
    end
  end
end
