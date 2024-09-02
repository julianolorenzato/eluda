alias Eluda.Transpiler.Transpilation

import Eluda

mat = Matrex.random(2, 3)

%Matrex{data: d} = mat

t = Nx.tensor([[1, 2, 3], [4, 5, 6]])

# device [n <- mat, i <- 5..10//2, m <- mat], do: 3

# device n <- mat, do: n * 3 / 4
device n <- mat, do: t[n]
# device n <- mat, do: n * 3 / 4
# device n <- mat, do: n * 3 / 4

# device i <- mat3 do
#   mat[i][2] + 3
# end
