defmodule Eluda.TranspilerTest do
  use ExUnit.Case

  alias Eluda.GeneratorInfo
  alias Eluda.Transpiler

  describe "transpile/1" do
    test "should write the function correctly" do
      expr = quote do: 6 - j * n * m + 3 / i - 2

      generators_info = [
        %GeneratorInfo{index: 0, symbol: :n, range: nil},
        %GeneratorInfo{index: 1, symbol: :i, range: 2..7},
        %GeneratorInfo{index: 2, symbol: :m, range: nil},
        %GeneratorInfo{index: 3, symbol: :j, range: 3..10//2}
      ]

      got = Transpiler.transpile(expr, generators_info, "f3598754")

      expected =
        """
        void f3598754(float *dest, float **src, int *sizes) {
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

    test "should raise error if a found token is neither a generator var, scope var or allowed operator" do
      expr = quote do: (6 - j * n * 3) ++ (m + 3 / i - 2)

      generators_info = [
        %GeneratorInfo{index: 0, symbol: :n, range: nil},
        %GeneratorInfo{index: 1, symbol: :i, range: 2..7},
        %GeneratorInfo{index: 2, symbol: :m, range: nil},
        %GeneratorInfo{index: 3, symbol: :j, range: 3..10//2}
      ]

      assert_raise RuntimeError,
                   "invalid token '++', only the following operators are allowed: [:+, :-, :*, :/]",
                   fn ->
                     Transpiler.transpile(expr, generators_info, "f3598754")
                   end
    end
  end
end
