import numpy as np
np.random.seed(42)
vector = np.random.randint(0, 10, size=4)
print("vector",vector)
matrix = np.random.randint(0, 10, size=(4, 4))
print("matrix",matrix)
print("answer",matrix @ vector)
accum = np.zeros(4)
tile_size = 2
for i in range(tile_size):
    for j in range(tile_size):
        tile = matrix[i*tile_size:i*tile_size+tile_size, j*tile_size:j*tile_size+tile_size]  # shape (2,2)
        print("tile",tile)
        vec_tile = vector[j*tile_size:j*tile_size+tile_size]    # corresponding 2 elements\
        print("vec_tile",vec_tile)
        curr = np.zeros(4)
        curr[i*tile_size:i*tile_size+tile_size] = (tile @ vec_tile)
        print("curr", curr)
        accum[i*tile_size:i*tile_size+tile_size] += (tile @ vec_tile)

print("ACCUUM",accum)

