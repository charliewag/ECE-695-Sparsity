import numpy as np
import sys
import struct
import packing_algo


np.random.seed(41)
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
# print("weights",weights)
inputs = np.random.randint(0, 10, size=(weights_shape[1],matrix_size))
# print("inputs",inputs)

density = 0.05

constraints = [
    (4, 2),  # First iteration
    (2, 1),  # Second iteration
    (0, 0)   # Final iteration
]

# Generate original matrix
original = packing_algo.generate_sparse_matrix(weights_shape[0], weights_shape[1], density)
# print("Original Matrix\n",original)

current_matrix = original.copy()
current_index = None
array_size = 32  # width of systolic array
matrix_width = original.shape[1]
matrix_height = original.shape[0]
packed_chunks = []
index_chunks = []
max_width = 0

# Process vertical chunks
for row_start in range(0, matrix_height, array_size):
    row_end = row_start + array_size
    current_matrix = original[row_start:row_end, :].copy()
    current_index = None  # reset per chunk

    for iteration, (total_col, row_col) in enumerate(constraints, 1):
        groups = packing_algo.group_columns(current_matrix, total_col, row_col)
        final, index = packing_algo.build_result_matrices(current_matrix, groups, current_index)

        current_matrix = final
        current_index = index
        max_width = max(max_width, current_matrix.shape[1])
    # print(final.shape)
    packed_chunks.append(final)
    index_chunks.append(index)

padded_chunks = [np.pad(chunk, ((0, 0), (0, max_width - chunk.shape[1])), mode='constant', constant_values=0)
                 for chunk in packed_chunks]
padded_indices = [np.pad(chunk, ((0, 0), (0, max_width - chunk.shape[1])), mode='constant', constant_values=-1)
                  for chunk in index_chunks]

current_matrix = np.vstack(padded_chunks)
current_index = np.vstack(padded_indices)

print("\nFINAL RESULT pre pad:")
print("Final Size Matrix\n",current_matrix.shape)
# print("Final Value Matrix\n",current_matrix)
# print("Final Index Matrix\n",current_index)
weights = packing_algo.pad_to_tile_size(current_matrix, tile_size, 0)
weights_ind = packing_algo.pad_to_tile_size(current_index, tile_size, -1)
post_pack_original = packing_algo.unpack_matrix(weights, weights_ind, shape=(weights_shape[0], weights_shape[1]))
print("Final Size Matrix post pad\n",weights.shape)
print("answer",post_pack_original @ inputs)
tiles = {}
tiles_ind = {}
input_tiles = {}

for i in range(0, weights.shape[0], tile_size):
    for j in range(0, weights.shape[1], tile_size):
        tiles[(i // tile_size, j // tile_size)] = weights[i:i+tile_size, j:j+tile_size]
        tiles_ind[(i // tile_size, j // tile_size)] = weights_ind[i:i+tile_size, j:j+tile_size]

accum = np.zeros((weights_shape[0], inputs.shape[1]))
prev_weight = np.zeros((tile_size, tile_size))
with open(f'systolic_array_utils/{filename}.txt', "w") as input_file, open(f'systolic_array_utils/{filename}_output.txt', "w") as output_file:
    for i in range(0, weights.shape[0], tile_size):
        partial = np.zeros((tile_size, inputs.shape[1]))
        for j in range(0, weights.shape[1], tile_size):
            for v in range(inputs.shape[1]):
                pre_partial = partial
                curr_weight = tiles[(i//tile_size,j//tile_size)]
                curr_inds = tiles_ind[(i//tile_size,j//tile_size)]
                curr_vec = inputs[:, v]
                curr_partial = pre_partial[:,v].copy()
                prod = packing_algo.mult(curr_weight,curr_inds,curr_vec)
                partial[:,v] = prod + curr_partial
                curr_out = partial[:,v] 
                # get input vecs 
                inp = [0] * tile_size
                ind = [0] * tile_size
                for c in range(tile_size):
                    curr_c = curr_inds[:,c]
                    nonneg = curr_c[curr_c >= 0]
                    uniq = np.unique(nonneg)
                    ind[c] = uniq
                    inp[c] = curr_vec[uniq]
                # print("inputs",inp)
                # print("indices", ind)
                max_len = max(len(vec) for vec in inp)
                padded_inputs = np.array([np.pad(vec, (0, max_len - len(vec)), mode='constant', constant_values=0) for vec in inp]).T
                padded_indices = []
                for iv, ind_vec in enumerate(ind):
                    pad_len = max_len - len(ind_vec)
                    if pad_len > 0:
                        # Only apply -1 padding if this is the first column (i == 0)
                        # pad_val = -1 if iv == 0 else 0
                        padded = np.pad(ind_vec, (0, pad_len), mode='constant', constant_values=0)#pad_val)
                    else:
                        padded = ind_vec
                    padded_indices.append(padded)
                padded_indices = np.array(padded_indices).T
                # padded_indices = np.array([np.pad(ind, (0, max_len - len(ind)), mode='constant') for ind in ind]).T
                # wrt_indices = np.clip(curr_inds, 0, None)
                wrt_indices = curr_inds
                # print("inputs",padded_inputs)
                # print("indices", padded_indices)
                # print(wrt_indices)
                # print("weight tile", curr_weight)
                # print("index tile", curr_inds)
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
                    for w_row, idx_row in zip(curr_weight, wrt_indices):
                        if type == "fp":
                            line = " ".join(
                                f"({struct.pack('>e', w).hex()},{ww})"
                                for w, ww in zip(w_row, idx_row)
                            )
                        else:
                            line = " ".join(
                                f"({int(w)},{ww})"
                                for w, ww in zip(w_row, idx_row)
                            )
                        input_file.write(line + "\n")
                prev_weight = curr_weight
                # write inputs
                input_file.write("Inputs\n")
                nrows = padded_inputs.shape[0]
                for r, (in_row, idx_row) in enumerate(zip(padded_inputs, padded_indices)):
                    # flag==1 only on the last row
                    flag = 1 if r == nrows - 1 else 0
                    if type == "fp":
                        line = " ".join(
                            f"({struct.pack('>e', val).hex()},{idx},{flag})"
                            for val, idx in zip(in_row, idx_row)
                        )
                    else:
                        line = " ".join(
                            f"({int(val)},{idx},{flag})"
                            for val, idx in zip(in_row, idx_row)
                        )
                    input_file.write(line + "\n")
                # write partials
                input_file.write("Partials\n")
                if type == "fp":
                    input_file.write(" ".join(str(struct.pack('>e', v).hex()) for v in curr_partial) + "\n")
                else:
                    input_file.write(" ".join(str(int(v)) for v in curr_partial) + "\n")
                input_file.write("Multiply\n")
        accum[i:i+tile_size] += partial

print("my answer", accum)