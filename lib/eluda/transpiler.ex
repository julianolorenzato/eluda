defmodule Eluda.Transpiler do
  @allowed_operators [:+, :-, :*, :/]

  defp ast_walk(value) when is_number(value), do: to_string(value)

  defp ast_walk({operator, _, [arg1, arg2]}) do
    if operator not in @allowed_operators do
      raise "only the following operators are allowed: " <> inspect(@allowed_operators)
    end

    "(" <> ast_walk(arg1) <> to_string(operator) <> ast_walk(arg2) <> ")"
  end

  defmacro transpile(ast) do
    """
    float kernel(float value) {
      return #{ast_walk(ast)};
    }
    """
  end
end
