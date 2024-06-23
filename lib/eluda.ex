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

  def load_kernel_nif(_kernel_name) do
    raise "load_kernel_nif/1 was not implemented!"
  end

  @doc """
  The main macro

  mat_1 = Matrex.random(...)

  x = 1 + 3

  ex: device(n <- mat_1, do: n * 2)

  """
  defmacro device({:<-, _, [{var_symbol, _, _}, matrex]}, do: expr) do
    unique_name = "f#{:erlang.phash2(:erlang.unique_integer())}"

    # AST Transpilation
    code = Transpiler.transpile(expr, var_symbol, unique_name)

    src_path = "priv/c_src/kernels.c"
    dest_path = "priv/c_dest/kernels.so"

    if File.exists?(src_path) do
      File.write(src_path, code, [:append])
    else
      File.write(src_path, code)
    end

    # C Compilation
    System.cmd("gcc", ["-fPIC", "-shared", "-o", dest_path, src_path])

    # %Matrex{data: data} = unquote(matrex)
    # {ref, m_size} = Eluda.device_alloc_nif(data)

    # tratar expressão também

    quote do
      # load_kernel_nif(Eluda, kernel)
      # load_fun(abc); load_kernel (devolve ponteiro pro kernel)
      # (abre a biblioteca c que tem o codigo que eu gerei (dlopen))
      # dlsym (usa o retorno do dlopen)(recebe o nome da funcao e devolve um ponteiro para essa função (que eu uso pra executar a função))

      # passar mat_1 como argumento de outra função

      # Retornar a chamada para a NIF que executará o LOOP em C
      # Algo como:
      # Eluda.kernel_nif(nome_da_função, mat_1, tamanho_da_lista)
    end
  end
end
