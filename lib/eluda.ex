defmodule Eluda do
  @moduledoc false

  alias Eluda.Transpiler
  alias Eluda.Transpiler.Transpilation

  @on_load :load_nifs

  def load_nifs() do
    File.write!("c_src/kernels.c", "", [:write])

    :erlang.load_nif(~c"./priv/c_dest/eluda_nifs", 0)
  end

  def execute_nif(_kernel_name, _data, _res_length) do
    raise "execute_nif/3 was not implemented!"
  end

  @doc """
  def my_fun() do
    vet = Matrex.random()

    device i <- 0..1000, do: vet[i] + vet[i]
  end

  The main macro

  mat_1 = Matrex.random(...)

  x = 1 + 3

  ex: device(n <- mat_1, do: n * 2)

  device  n <- 0 .. 1000, do: vet1[n] + vet2[n]

  detecção de variaveis livres

  detectar as q sao usadas mas n sao declaradas (variaveis livres)

  ----

  passar multiplos argumentos na função

  automatizar as variaveis livres como argumentos na funcao

  lidar com multiplos argumentos nas nifs

  ---------------------

  Estou tentando passar multiplos binaries para a nif, este é o problema atual

  """
  defmacro device({:<-, _meta, [_left, right]} = generator, do: expr) do
    Transpilation.start_link()

    Transpilation.set_unique_name()

    # passar as scope_vars para o transpiler e depois de descobrir quais são usadas é q deve fazer o scope_info de cada uma

    __CALLER__
    |> Macro.Env.vars()
    |> Enum.map(fn {k, _} -> {k, false} end)
    |> Enum.each(&Transpilation.add_scope_var/1)

    [generator]
    |> Enum.map(&handle_generator/1)
    |> Enum.with_index(fn {a, b}, i -> {a, b, i} end)
    |> Enum.each(&Transpilation.add_gen_var/1)

    transpiled = Transpiler.transpile(expr)

    IO.puts(transpiled)

    quote do
      # list = Enum.map(unq)
      # IO.inspect(unquote(used))

      # case unquote(right) do
      #   %Matrex{data: data} ->
      #     <<head::binary-size(8), rest::binary>> = data

      #     new_data = head <> execute_nif(unquote(unique_name), [data | unquote(used)], 10)

      #     %Matrex{data: new_data}

      #   start..final ->
      #     IO.inspect(execute_nif(unquote(unique_name), unquote(used)))

      #     # passar todos os binaries utilizados na expressao para a memoria do dispositivo
      #     # após, executar o kernel
      # end
    end
  end

  defmacro device(generators, do: expr) when is_list(generators) do
    unique_name = ~c"f#{:erlang.phash2(:erlang.unique_integer())}"

    # scope_vars =
    #   __CALLER__
    #   |> Macro.Env.vars()
    #   |> Enum.map(fn {k, _} -> k end)

    # infos =
    #   generators
      # |> Enum.map(&handle_generator/1)
      # |> Enum.with_index(&%GeneratorInfo{&1 | index: &2})

    # IO.inspect(infos)

    quote do
      3
    end

    # IO.inspect(info)

    # symbols_used = Enum.with_index([var_symbol | used])

    # expr
    # |> Transpiler.transpile(symbols_used, unique_name)
    # |> c_compile()

    # essa parte computa todas as variáveis que estão sendo utilizadas na expressão, se
    # não existir no escopo alguma das que estão sendo usadas deverá disparar um erro
    # Macro.prewalk(expr, &IO.inspect/1)

    # IO.inspect(used)

    # used = bind_variables(expr, Macro.Env.vars(__CALLER__))
    # IO.inspect(used)

    # quote do
    #   list = Enum.map(unq)
    #   IO.inspect(unquote(used))

    #   case unquote(right) do
    #     %Matrex{data: data} ->
    #       <<head::binary-size(8), rest::binary>> = data

    #       new_data = head <> execute_nif(unquote(unique_name), [data | unquote(used)], 10)

    #       %Matrex{data: new_data}

    #     start..final ->
    #       IO.inspect(execute_nif(unquote(unique_name), unquote(used)))

    #       # passar todos os binaries utilizados na expressao para a memoria do dispositivo
    #       # após, executar o kernel
    #   end
    # end
  end

  defp handle_generator({:<-, _meta, [{var_symbol, _, _}, {:.., _, [start, finish]}]}) do
    # %GeneratorInfo{symbol: var_symbol, range: start..finish}
    {var_symbol, start..finish}
  end

  defp handle_generator({:<-, _meta, [{var_symbol, _, _}, {:"..//", _, [start, finish, step]}]}) do
    # %GeneratorInfo{symbol: var_symbol, range: start..finish//step}
    {var_symbol, start..finish//step}
  end

  defp handle_generator({:<-, _meta, [{var_symbol, _, _}, {tensor_symbol, _, _}]}) do
    # %GeneratorInfo{symbol: var_symbol, range: nil}
    {var_symbol, tensor_symbol}
  end

  defp bind_variables(expr, vars) do
    env_vars = Enum.map(vars, fn {name, _} -> name end)
    Macro.prewalk(expr, [], &handle_node(&1, &2, env_vars))
  end

  defp handle_node({symbol, _meta, _args}, acc, env_vars) do
    if Enum.member?(env_vars, symbol) do
      [symbol | acc]
    else
      acc
    end
  end

  defp handle_node(symbol, acc, env_vars) when is_atom(symbol) do
    if Enum.member?(env_vars, symbol) do
      [symbol | acc]
    else
      acc
    end
  end

  defp handle_node(_value, acc, _env_vars), do: acc

  @src_path "c_src/kernels.c"
  @dest_path "priv/c_dest/kernels.so"
  defp c_compile(c_code) do
    if File.exists?(@src_path) do
      File.write(@src_path, c_code, [:append])
    else
      File.write(@src_path, c_code)
    end

    System.cmd("gcc", ["-fPIC", "-shared", "-o", @dest_path, @src_path])
  end
end
