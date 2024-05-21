defmodule Eluda.Transpiler do
  @moduledoc """
  Responsible for transpiling Elixir arithmetic expressions to C/CUDA.
  """

  @allowed_operators [:+, :-, :*, :/]

  # Walks through the abstract syntax tree, checking the nodes and carrying out the respective treatments.
  defp walk(value, _) when is_number(value), do: to_string(value)

  defp walk({name, _, _}, var_symbol) when name == var_symbol, do: "data[i]"

  defp walk({operator, _, [arg1, arg2]}, var_symbol) do
    if operator not in @allowed_operators do
      raise "only the following operators are allowed: " <> inspect(@allowed_operators)
    end

    "(" <> walk(arg1, var_symbol) <> to_string(operator) <> walk(arg2, var_symbol) <> ")"
  end

  @doc """
  Transpile
  """
  defmacro transpile(expr_ast, {var_symbol, _, _}) do
    """
    float *kernel(float *data) {
      for (int i = 0; i < ??; i++) {
        data[i] = #{walk(expr_ast, var_symbol)};
      }

      return data;
    }
    """
  end
end
