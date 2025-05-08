import numpy as np
import sys
import struct
import packing_algo

np.random.seed(42)
filename = sys.argv[1]
type = sys.argv[2]
tile_size = int(sys.argv[3])
matrix_size = int(sys.argv[4])
#fp or int
# weights_shape = [4,4]
# tile_size = 2
weights_shape = [matrix_size,matrix_size]
# tile_size = 4
# weights = np.random.randint(0, 10, size=(weights_shape[0], weights_shape[1]))
density = 1
weights = packing_algo.generate_sparse_matrix(weights_shape[0], weights_shape[1], density)
inputs = np.random.randint(0, 10, size=(weights_shape[0], weights_shape[1]))
# print("inputs",inputs)

# print("answer",weights @ inputs)
tiles = {}
tiles_ind = {}
input_tiles = {}
test = {}
for i in range(0, weights.shape[0], tile_size):
    for j in range(0, weights.shape[1], tile_size):
        tiles[(i // tile_size, j // tile_size)] = weights[i:i+tile_size, j:j+tile_size]

for i in range(0, weights.shape[0], tile_size): # tiles of input matrix
    for j in range(matrix_size): # columns of input matrix
        input_tiles[(i // tile_size, j)] = inputs[i:i+tile_size, j]  


accum = np.zeros((weights.shape[0], weights.shape[1]))
prev_weight = np.zeros((tile_size, tile_size))
with open(f'systolic_array_utils/{filename}.txt', "w") as input_file, open(f'systolic_array_utils/{filename}_output.txt', "w") as output_file:
    for i in range(0, weights.shape[0], tile_size):
        partial = np.zeros((tile_size, weights.shape[1]))
        for j in range(0, weights.shape[1], tile_size):
            for v in range(weights.shape[0]): # input vectors
                pre_partial = partial
                curr_weight = tiles[(i//tile_size,j//tile_size)]
                curr_vec = input_tiles[j//tile_size, v]
                curr_partial = pre_partial[:,v].copy()
                partial[:,v] = curr_weight @ curr_vec + curr_partial
                curr_out = partial[:,v]
                # print("weight tile", curr_weight)
                # print("input vec",curr_vec)
                # print("curr_partial", curr_partial)
                # print("curr_out", curr_out)
                if (type == "fp"):
                    output_file.write(" ".join(str(struct.pack('>e', v).hex()) for v in curr_out) + "\n")
                else:
                    output_file.write(" ".join(str(int(v)) for v in curr_out) + "\n")
                # Write weights
                if not np.array_equal(curr_weight, prev_weight):
                    input_file.write("Weights\n")
                    for row in curr_weight:
                        if type == "fp":
                            line = " ".join(f"({struct.pack('>e', val).hex()},{j})" for j, val in enumerate(row))
                        else:
                            line = " ".join(f"({int(val)},{j})" for j, val in enumerate(row))
                        input_file.write(line + "\n")
                prev_weight = curr_weight
                # write inputs
                input_file.write("Inputs\n")
                for idx, val in enumerate(curr_vec):
                    if type == "fp":
                        input_file.write(f"({struct.pack('>e', val).hex()},{idx},1) ")
                    else:
                        input_file.write(f"({int(val)},{idx},1) ")
                input_file.write("\n")
                # write partials
                input_file.write("Partials\n")
                if type == "fp":
                    input_file.write(" ".join(str(struct.pack('>e', v).hex()) for v in curr_partial) + "\n")
                else:
                    input_file.write(" ".join(str(int(v)) for v in curr_partial) + "\n")
                input_file.write("Multiply\n")
        accum[i:i+tile_size] += partial


# print("my answer", accum)