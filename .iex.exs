import Eluda

mat = Matrex.random(2, 3)

%Matrex{data: d} = mat

t = Nx.tensor([[1, 2, 3], [4, 5, 6]])

device [n <- mat, i <- 5..10//2, m <- mat], do: 3
