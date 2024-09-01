defmodule Eluda.TranspilerTest do
  use ExUnit.Case

  alias Eluda.Transpiler.Transpilation
  alias Eluda.GeneratorInfo
  alias Eluda.Transpiler

  setup do
    {:ok, pid} = Transpilation.start_link()
    Transpilation.set_unique_name()

    [:mat1, :mat2]
    |> Enum.each(&Transpilation.add_scope_var/1)

    on_exit(fn ->
      if Process.alive?(pid) do
        Transpilation.stop()
      end
    end)

    :ok
  end

  describe "transpile/1" do
    test "should write the function correctly" do
      expr = quote do: 6 - j * n * m + 3 / i - 2

      [
        {:n, :mat1, 0},
        {:i, 2..7, 1},
        {:m, :mat2, 2},
        {:j, 3..10//2, 3}
      ]
      |> Enum.each(&Transpilation.add_gen_var/1)

      got = Transpiler.transpile(expr)

      expected =
        """
        void #{Transpilation.unique_name()}(float *dest, float **src, int *sizes, float **aux, int *sizes_aux) {
          i = 0;
          for (int k0 = 0; k0 < sizes[0]; k0++) {
            for (int k1 = 2; k1 < 7; k1 += 1) {
              for (int k2 = 0; k2 < sizes[2]; k2++) {
                for (int k3 = 3; k3 < 10; k3 += 2) {
                  dest[i] = (((6-((src[3][k3]*src[0][k0])*src[2][k2]))+(3/src[1][k1]))-2);
                  i++;
                }
              }
            }
          }
        }
        """

      assert got == expected
    end

    test "should raise error if a found tensor symbol is not in scope" do
      expr = quote do: 6 - j * n * m + 3 / i - 2

      [
        {:n, :mat1, 0},
        {:i, 2..7, 1},
        {:m, :mat3, 2},
        {:j, 3..10//2, 3}
      ]
      |> Enum.reverse()
      |> Enum.each(&Transpilation.add_gen_var/1)

      assert_raise RuntimeError,
                   "token 'mat3' is not in the scope",
                   fn ->
                     Transpiler.transpile(expr)
                   end
    end

    test "should raise error if a found token is neither a generator var, scope var or allowed operator" do
      #   expr = quote do: (6 - j * n * 3) ++ (m + 3 / i - 2)

      #   generators_info = [
      #     %GeneratorInfo{index: 0, symbol: :n, range: nil},
      #     %GeneratorInfo{index: 1, symbol: :i, range: 2..7},
      #     %GeneratorInfo{index: 2, symbol: :m, range: nil},
      #     %GeneratorInfo{index: 3, symbol: :j, range: 3..10//2}
      #   ]

      #   assert_raise RuntimeError,
      #                "invalid token '++', only the following operators are allowed: [:+, :-, :*, :/]",
      #                fn ->
      #                  Transpiler.transpile(expr)
      #                end
    end
  end
end
