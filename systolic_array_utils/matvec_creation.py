import numpy as np
import sys
import struct
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
weights = np.random.randint(0, 10, size=(weights_shape[0], weights_shape[1]))
# print("weights",weights)
inputs = np.random.randint(0, 10, size=weights_shape[1])
# print("inputs",inputs)

# print("answer",weights @ inputs, "len", len(weights @ inputs))
tiles = {}
input_tiles = {}

for i in range(0, weights.shape[0], tile_size):
    for j in range(0, weights.shape[1], tile_size):
        tiles[(i // tile_size, j // tile_size)] = weights[i:i+tile_size, j:j+tile_size]
    input_tiles[i // tile_size] = inputs[i:i+tile_size]

accum = np.zeros(weights.shape[0])
with open(f'systolic_array_utils/{filename}.txt', "w") as input_file, open(f'systolic_array_utils/{filename}_output.txt', "w") as output_file:
    for i in range(0, weights.shape[0], tile_size):
        partial = np.zeros(tile_size)
        for j in range(0, weights.shape[1], tile_size):
            pre_partial = partial
            partial = tiles[(i//tile_size,j//tile_size)] @ input_tiles[j//tile_size] + pre_partial
            if (type == "fp"):
                output_file.write(" ".join(str(struct.pack('>e', v).hex()) for v in partial) + "\n")
            else:
                output_file.write(" ".join(str(int(v)) for v in partial) + "\n")
            curr_weight = tiles[(i//tile_size,j//tile_size)]
            curr_vec = input_tiles[j//tile_size]
            curr_partial = pre_partial
            # Write weights
            input_file.write("Weights\n")
            for row in curr_weight:
                if type == "fp":
                    line = " ".join(f"({struct.pack('>e', val).hex()},{j})" for j, val in enumerate(row))
                else:
                    line = " ".join(f"({int(val)},{j})" for j, val in enumerate(row))
                input_file.write(line + "\n")
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


# print("my answer", accum, "len", len(accum))