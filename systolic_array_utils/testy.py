import numpy as np
import packing_algo

original = np.array([
    [8, 0, 0, 3, 1, 0, 2, 0],
    [0, 6, 4, 0, 0, 5, 0, 3],
    [7, 0, 3, 0, 9, 0, 0, 1],
    [0, 7, 8, 0, 0, 2, 9, 0]
])

weight_tile = np.array([
    [8, 3, 1, 2],
    [6, 4, 5, 3],
    [7, 3, 9, 1],
    [7, 8, 2, 9]
])

# Define corresponding column indices for each entry
index_tile = [
    [ 0, 3, 4, 6],
    [ 1, 2, 5, 7],
    [ 0, 2, 4, 7],
    [ 1, 2, 5, 6]
]

# Define input vector
inputs = np.array([3, 4, 7, 2, 2, 9, 6, 8])
tile_size = 4

output = packing_algo.mult(weight_tile, index_tile, inputs)

print("Output:", output)
print("answer",original @ inputs)