import Eluda

mat = Matrex.random(5, 5)
IO.inspect(mat, label: "Original")

new_mat = device(n <- mat, do: n * 3)
IO.inspect(new_mat, label: "Multiplied by 3")
