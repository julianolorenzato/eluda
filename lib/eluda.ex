defmodule Eluda do
  @moduledoc """
  Documentation for `Eluda`.
  """

  require Eluda.Transpiler, as: Transpiler

  @on_load :load_nifs

  def load_nifs() do
    :erlang.load_nif(~c"./priv/c_dest/eluda_nifs", 0)
  end

  def device_alloc_nif(_binary) do
    raise "device_alloc_nif/1 was not implemented!"
  end

  @doc """
  The main macro

  ex: device(n <- [1, 2, 3], do: n * 2)
  """
  defmacro device({:<-, _, [var_symbol, matrex]}, [do: expr]) do
    quote do
      code = Transpiler.transpile(unquote(expr), unquote(var_symbol))

      File.write("./priv/c_src/kernel.c", code)

      # Compilation
      System.cmd("gcc", [
        "-fPIC",
        "-shared",
        "-o",
        "priv/c_dest/kernel.so",
        "priv/c_src/kernel.c"
      ])

      %Matrex{data: data} = unquote(matrex)
      ref = Eluda.device_alloc_nif(data)

      # load_fun; load_kernel

      # Retornar a chamada para a NIF que executará o LOOP em C
      # Algo como:
      # Eluda.kernel_nif(ponteiro_para_a_lista)
    end
  end
end
