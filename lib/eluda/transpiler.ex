defmodule Eluda.Transpiler do
  alias Eluda.GeneratorInfo

  @moduledoc """
  Responsible for transpiling Elixir arithmetic expressions to C/CUDA.
  """

  @allowed_operators [:+, :-, :*, :/]
  @indent "  "

  @doc """
  Transpile
  """
  @spec transpile(any(), [GeneratorInfo.t()], String.t()) :: String.t()
  def transpile(expr_ast, infos, fun_name) do
    """
    void #{fun_name}(float *dest, float **src, int *sizes) {
    #{@indent}i = 0;
    #{build_nested_loops(expr_ast, infos, infos)}}
    """
  end

  @spec build_nested_loops(any(), [GeneratorInfo.t()], [GeneratorInfo.t()]) :: String.t()
  defp build_nested_loops(expr_ast, infos, infos)

  defp build_nested_loops(expr_ast, [], infos) do
    indent = String.duplicate(@indent, length(infos) + 1)

    """
    #{indent}dest[i] = #{walk(expr_ast, infos)};
    #{indent}i++;
    """
  end

  defp build_nested_loops(expr_ast, [info | rest], infos) do
    indent = String.duplicate(@indent, info.index + 1)

    """
    #{indent}#{for_signature(info)} {
    #{build_nested_loops(expr_ast, rest, infos)}#{indent}}
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
  @spec walk(any(), [GeneratorInfo.t()]) :: String.t()
  defp walk(value, _) when is_number(value), do: to_string(value)

  defp walk({operator, _, [arg1, arg2]}, info) when operator in @allowed_operators do
    "(" <> walk(arg1, info) <> to_string(operator) <> walk(arg2, info) <> ")"
  end

  defp walk({token, _, _}, info) do
    res = Enum.find(info, fn %GeneratorInfo{symbol: symbol} -> token == symbol end)

    case res do
      %GeneratorInfo{index: index} ->
        "src[#{index}][k#{index}]"

      nil ->
        raise "invalid token '#{token}', only the following operators are allowed: #{inspect(@allowed_operators)}"
    end
  end
end
