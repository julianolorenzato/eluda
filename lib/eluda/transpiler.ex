defmodule Eluda.Transpiler do
  @moduledoc """
  Responsible for transpiling Elixir arithmetic expressions to C/CUDA.
  """

  alias Eluda.Transpiler.Transpilation

  @allowed_operators [:+, :-, :*, :/]
  @indent "  "

  @doc """
  Transpile
  """
  @spec transpile(any()) :: String.t()
  def transpile(expr_ast) do
    fun_name = Transpilation.unique_name()
    gen_vars = Transpilation.gen_vars() |> Enum.reverse()

    """
    void #{fun_name}(float *dest, float **src, int *sizes, float **aux, int *sizes_aux) {
    #{@indent}i = 0;
    #{build_nested_loops(expr_ast, gen_vars)}}
    """
  end

  @spec build_nested_loops(any(), list()) :: String.t()
  defp build_nested_loops(expr_ast, gen_vars)

  defp build_nested_loops(expr_ast, []) do
    indent = String.duplicate(@indent, length(Transpilation.gen_vars()) + 1)

    """
    #{indent}dest[i] = #{walk(expr_ast)};
    #{indent}i++;
    """
  end

  defp build_nested_loops(expr_ast, [{_var_symbol, _tensor_symbol, i} = gen_var | rest]) do
    indent = String.duplicate(@indent, i + 1)

    """
    #{indent}#{for_signature(gen_var)} {
    #{build_nested_loops(expr_ast, rest)}#{indent}}
    """
  end

  @spec for_signature(tuple()) :: String.t()
  defp for_signature(gen_var) do
    case gen_var do
      {_var_symbol, start..finish//step, i} ->
        "for (int k#{i} = #{start}; k#{i} < #{finish}; k#{i} += #{step})"

      {_var_symbol, start..finish, i} ->
        "for (int k#{i} = #{start}; k#{i} < #{finish}; k#{i}++)"

      {_var_symbol, tensor_symbol, i} when is_atom(tensor_symbol) ->
        if !valid_scope_symbol?(tensor_symbol) do
          raise "invalid token '#{tensor_symbol}' in generator, is not in the scope"
        end

        "for (int k#{i} = 0; k#{i} < sizes[#{i}]; k#{i}++)"
    end
  end

  # Walks through the abstract syntax tree, checking the nodes and carrying out the respective treatments.
  @spec walk(any()) :: String.t()
  defp walk(value) when is_number(value), do: to_string(value)

  defp walk({operator, _, [arg1, arg2]}) when operator in @allowed_operators do
    "(" <> walk(arg1) <> to_string(operator) <> walk(arg2) <> ")"
  end

  # Access protocol, var index - vet[j]
  # defp walk({{:., _, [Access, :get]}, _, [{tensor_symbol, _, _}, {index_symbol, _, _}]}) do
  #   # verify if 'j' is a generator var if not raises an error
  #   if !valid_gen_symbol?(index_symbol) do
  #     raise "invalid token '#{index_symbol}' in expression, is neither a generator var or number"
  #   end

  #   # needs dry (already fetch gen_vars 5 lines above)
  #   {_, _, idx} =
  #     Transpilation.gen_vars()
  #     |> Enum.find(fn {i_symbol, _, _} -> i_symbol == index_symbol end)

  #   {_, idx_scope} =
  #     Transpilation.scope_vars()
  #     |> Enum.find(fn {s, _} -> s == tensor_symbol end)

  #   # verify if 'vet' is in scope if not raises an error, mark 'vet' as used otherwise
  #   if !valid_scope_symbol?(tensor_symbol) do
  #     raise "invalid token '#{tensor_symbol}' in expression, is not in the scope"
  #   else
  #     Transpilation.mark_used_scope_var(tensor_symbol)
  #   end

  #   "aux[#{idx_scope}][k#{idx}]"
  # end

  # Access protocol, number index - vet[3]
  defp walk({{:., _, [Access, :get]}, _, [{tensor_symbol, _, _}, i]}) when is_integer(i) do
    Enum.find(Transpilation.gen_vars(), fn {var, tensor, index} -> var == tensor_symbol end)

    # verify if 'vet' is in scope if not raises an error, mark 'vet' as used otherwise
    if !valid_scope_symbol?(tensor_symbol) do
      raise "invalid token '#{tensor_symbol}' in expression, is not in the scope"
    else
      Transpilation.mark_used_scope_var(tensor_symbol)
    end

    "#{tensor_symbol}[#{i}]"
  end

  # Generator symbols
  defp walk({token, _, _}) do
    res =
      Transpilation.gen_vars()
      |> Enum.find(fn {symbol, _, _} -> token == symbol end)

    case res do
      {_symbol, _tensor, i} ->
        "src[#{i}][k#{i}]"

      nil ->
        raise "invalid token '#{token}' in expression, only the following operators are allowed: #{inspect(@allowed_operators)}"
    end
  end

  # have interrogation but is not returning boolean for all results
  defp valid_gen_symbol?(symbol) do
    Transpilation.gen_vars()
    |> Enum.find(false, fn {gen_index, _, _} -> gen_index == symbol end)
  end

  defp valid_scope_symbol?(symbol) do
    Transpilation.scope_vars()
    |> Enum.find(false, fn {var, _} -> symbol == var end)
  end
end
