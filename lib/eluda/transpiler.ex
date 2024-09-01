defmodule Eluda.Transpiler do
  @moduledoc """
  Responsible for transpiling Elixir arithmetic expressions to C/CUDA.
  """

  alias Eluda.ScopeInfo
  alias Eluda.GeneratorInfo

  @allowed_operators [:+, :-, :*, :/]
  @indent "  "

  @doc """
  Transpile
  """
  @spec transpile(any(), [GeneratorInfo.t()], list(), charlist()) :: String.t()
  def transpile(expr_ast, infos, scope_vars, fun_name) do
    """
    void #{fun_name}(float *dest, float **src, int *sizes, float **aux, int *sizes_aux) {
    #{@indent}i = 0;
    #{build_nested_loops(expr_ast, infos, infos, scope_vars)}}
    """
  end

  @spec build_nested_loops(any(), [GeneratorInfo.t()], [GeneratorInfo.t()], [ScopeInfo.t()]) ::
          String.t()
  defp build_nested_loops(expr_ast, infos, infos, scope_vars)

  defp build_nested_loops(expr_ast, [], infos, scope_vars) do
    indent = String.duplicate(@indent, length(infos) + 1)

    """
    #{indent}dest[i] = #{walk(expr_ast, infos, scope_vars)};
    #{indent}i++;
    """
  end

  defp build_nested_loops(expr_ast, [info | rest], infos, scope_vars) do
    indent = String.duplicate(@indent, info.index + 1)

    """
    #{indent}#{for_signature(info)} {
    #{build_nested_loops(expr_ast, rest, infos, scope_vars)}#{indent}}
    """
  end

  @spec for_signature(GeneratorInfo.t()) :: String.t()
  defp for_signature(info) do
    case info do
      %GeneratorInfo{index: index, range: start..finish//step} ->
        "for (int k#{index} = #{start}; k#{index} < #{finish}; k#{index} += #{step})"

      %GeneratorInfo{index: index, range: start..finish} ->
        "for (int k#{index} = #{start}; k#{index} < #{finish}; k#{index}++)"

      %GeneratorInfo{index: index, range: nil} ->
        "for (int k#{index} = 0; k#{index} < sizes[#{index}]; k#{index}++)"
    end
  end

  # Walks through the abstract syntax tree, checking the nodes and carrying out the respective treatments.
  @spec walk(any(), [GeneratorInfo.t()], [ScopeInfo.t()]) :: String.t()
  defp walk(value, _, _) when is_number(value), do: to_string(value)

  defp walk({operator, _, [arg1, arg2]}, infos, scope_vars)
       when operator in @allowed_operators do
    "(" <>
      walk(arg1, infos, scope_vars) <>
      to_string(operator) <> walk(arg2, infos, scope_vars) <> ")"
  end

  # Scope symbols (Access protocol)
  defp walk({{:., _, [Access, :get]}, _, [{token, _, _}, index]}, infos, scope_vars) do
    res = Enum.find(scope_vars, fn symbol -> token == symbol end)

    if is_nil(res) do
      raise "index '#{token}' not found!"
    end

    case index do
      {atom, _, _} when is_atom(atom) ->
        nil

      num when is_integer(num) ->

    end


    # case res do
    #   sym_atom when is_atom(sym_atom) ->
    #     Enum.reduce(rest, "aux", fn {s, _, _}, acc ->
    #       r = Enum.find(infos, fn %GeneratorInfo{symbol: sym} -> s == sym end)

    #       if is_nil(r) do
    #         raise "index '#{s}' not found!"
    #       else
    #         acc <> "[#{s}]"
    #       end
    #     end)

    #   nil ->
    #     raise "Wht?"
    # end
  end

  # Generator symbols
  defp walk({token, _, _}, infos, _scope_vars) do
    res = Enum.find(infos, fn %GeneratorInfo{symbol: symbol} -> token == symbol end)

    case res do
      %GeneratorInfo{index: index} ->
        "src[#{index}][k#{index}]"

      nil ->
        raise "invalid token '#{token}', only the following operators are allowed: #{inspect(@allowed_operators)}"
    end
  end
end
