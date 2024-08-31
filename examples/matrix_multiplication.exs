import Eluda

mat1 = Matrex.random(4, 3)
mat2 = Matrex.random(3, 4) |> Matrex.transpose()

IO.inspect(mat1, label: "Matrix 1")

res = device i <- 0..4, mat1, mat2 do

end

device i: 2, do: i * 4

device n <- mat1 do

end

IO.inspect(res, label: "Matrix Result")
