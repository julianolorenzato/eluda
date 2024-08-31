defmodule Eluda do
  @moduledoc false

  alias Eluda.Transpiler
  alias Eluda.GeneratorInfo

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
  defmacro device({:<-, _meta, [{var_symbol, _, _} = left, right]}, do: expr) do
  end

  defmacro device(generators, do: expr) when is_list(generators) do
    unique_name = ~c"f#{:erlang.phash2(:erlang.unique_integer())}"

    # scope_vars =
    #   __CALLER__
    #   |> Macro.Env.vars()
    #   |> Enum.map(fn {k, _} -> k end)

    # tensors =
    #   MapSet.new(generators, fn {:<-, _meta, [{var_symbol, _, _} = left, right]} ->
    #     right
    #   end)

    info =
      generators
      |> Enum.map(fn
        {:<-, _meta, [{var_symbol, _, _}, {:.., _, [start, finish]}]} ->
          %GeneratorInfo{symbol: var_symbol, range: start..finish}

        {:<-, _meta, [{var_symbol, _, _}, {:"..//", _, [start, finish, step]}]} ->
          %GeneratorInfo{symbol: var_symbol, range: start..finish//step}

        {:<-, _meta, [{var_symbol, _, _}, _tensor]} ->
          %GeneratorInfo{symbol: var_symbol, range: nil}
      end)
      |> Enum.with_index(&%GeneratorInfo{&1 | index: &2})

    IO.inspect(info)

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

  defp handle_generator({:<-, _meta, [{left_symbol, _, _} = left, {right_symbol, _, _} = right]}) do
    {left, right}
  end

  defp left({:<-, _meta, [{left_symbol, _, _}, _right]}) do
    left_symbol
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
