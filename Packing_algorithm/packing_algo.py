import numpy as np
from collections import defaultdict

def generate_sparse_matrix(rows, cols, density):
    """Generate a random sparse matrix with given density"""
    matrix = np.zeros((rows, cols), dtype=int)
    num_non_zero = int(rows * cols * density)
    
    for _ in range(num_non_zero):
        i, j = np.random.randint(0, rows), np.random.randint(0, cols)
        while matrix[i][j] != 0:
            i, j = np.random.randint(0, rows), np.random.randint(0, cols)
        matrix[i][j] = np.random.randint(1, 10)
    
    print(f"\nGenerated {rows}x{cols} matrix with density {density:.2f}")
    return matrix

def print_matrix(matrix, title="Matrix"):
    """Print matrix with headers"""
    rows, cols = matrix.shape
    print(f"\n{title}:")
    print("     " + " ".join(f"{j:2}" for j in range(cols)))
    print("    " + "-"*(3*cols))
    for i in range(rows):
        print(f"{i:2} | " + " ".join(f"{val:2}" if val != 0 else " ." for val in matrix[i]))

def get_non_zero_positions(matrix):
    """Return dictionary of {column: set(non-zero rows)}"""
    non_zero = defaultdict(set)
    for i in range(matrix.shape[0]):
        for j in range(matrix.shape[1]):
            if matrix[i][j] != 0:
                non_zero[j].add(i)
    return non_zero

def count_collisions(group, candidate_col, non_zero_positions):
    """Calculate collisions between candidate column and existing group"""
    total_collisions = 0
    row_collisions = defaultdict(int)
    
    candidate_rows = non_zero_positions[candidate_col]
    
    for col in group:
        existing_rows = non_zero_positions[col]
        collisions = candidate_rows & existing_rows
        total_collisions += len(collisions)
        for row in collisions:
            row_collisions[row] += 1
    
    return total_collisions, row_collisions

def group_columns(matrix, total_collisions_allowed=2, row_collisions_allowed=1):
    """Group columns based on collision constraints"""
    non_zero_positions = get_non_zero_positions(matrix)
    cols = matrix.shape[1]
    groups = []
    used_cols = set()
    
    print(f"\nColumn grouping process (max total collisions: {total_collisions_allowed}, max row collisions: {row_collisions_allowed}):")
    for j in range(cols):
        if j in used_cols or not non_zero_positions[j]:
            continue
            
        current_group = [j]
        used_cols.add(j)
        print(f"\nStarting new group with column {j}")

        for k in range(j+1, cols):
            if k in used_cols or not non_zero_positions[k]:
                continue
                
            total_collisions, row_collisions = count_collisions(current_group, k, non_zero_positions)
            max_row_collision = max(row_collisions.values(), default=0)
            
            print(f"  Checking column {k}: Total collisions={total_collisions}, Max row collisions={max_row_collision}")

            if (total_collisions <= total_collisions_allowed and 
                max_row_collision <= row_collisions_allowed):
                current_group.append(k)
                used_cols.add(k)
                print(f"  Added column {k} to group {current_group}")
            else:
                print(f"  Rejected column {k} - constraints exceeded")

        groups.append(current_group)
        print(f"Finalized group: {current_group}")
    
    return groups

def build_result_matrices(original_matrix, groups, prev_index_matrix=None):
    """Build final matrix and index matrix using max-value resolution"""
    rows = original_matrix.shape[0]
    num_groups = len(groups)
    final_matrix = np.zeros((rows, num_groups), dtype=int)
    index_matrix = np.full((rows, num_groups), -1, dtype=int)
    
    for group_idx, group in enumerate(groups):
        for row in range(rows):
            max_val = -1
            max_col = -1
            for col in group:
                val = original_matrix[row, col]
                if val > max_val:
                    max_val = val
                    max_col = col
            if max_val > 0:
                final_matrix[row, group_idx] = max_val
                if prev_index_matrix is not None:
                    # Track back through previous index matrix
                    index_matrix[row, group_idx] = prev_index_matrix[row, max_col]
                else:
                    # Store direct column reference
                    index_matrix[row, group_idx] = max_col
    
    return final_matrix, index_matrix

def main():
    # Configuration
    rows = 16
    cols = 16
    density = 0.3
    constraints = [
        (4, 2),  # First iteration
        (2, 1),  # Second iteration
        (0, 0)   # Final iteration
    ]
    
    # Generate original matrix
    original = generate_sparse_matrix(rows, cols, density)
    print_matrix(original, "Original Matrix")
    
    current_matrix = original.copy()
    current_index = None
    metrics = []
    
    for iteration, (total_col, row_col) in enumerate(constraints, 1):
        print(f"\n{'='*40}")
        print(f"ITERATION {iteration} WITH CONSTRAINTS: Total collisions={total_col}, Row collisions={row_col}")
        print(f"{'='*40}")
        
        # Group columns for current iteration
        groups = group_columns(current_matrix, total_col, row_col)
        
        # Build result matrices
        final, index = build_result_matrices(current_matrix, groups, current_index)
        
        # Calculate metrics
        orig_non_zero = np.count_nonzero(original)
        curr_non_zero = np.count_nonzero(current_matrix)
        final_non_zero = np.count_nonzero(final)
        
        metrics.append({
            'iteration': iteration,
            'groups': len(groups),
            'compression_ratio': current_matrix.shape[1] / len(groups),
            'preserved_values': final_non_zero / orig_non_zero * 100,
            'collision_constraints': (total_col, row_col)
        })
        
        # Print intermediate results
        print(f"\nRESULT AFTER ITERATION {iteration}:")
        print_matrix(final, f"Iteration {iteration} - Value Matrix")
        print_matrix(index, f"Iteration {iteration} - Index Matrix")
        
        # Prepare for next iteration
        current_matrix = final
        current_index = index
    
    # Print final metrics
    print("\n\n" + "="*50)
    print("QUANTITATIVE METRICS REPORT")
    print("="*50)
    print(f"Original Matrix Columns: {cols}")
    print(f"Original Non-zero Values: {np.count_nonzero(original)}")
    
    for m in metrics:
        print(f"\nIteration {m['iteration']} (Constraints: {m['collision_constraints']}):")
        print(f"- Number of Groups: {m['groups']}")
        print(f"- Column Compression Ratio: {m['compression_ratio']:.1f}x")
        print(f"- Values Preserved: {m['preserved_values']:.1f}% of original")
    
    print("\nFinal Results:")
    print(f"- Total Compression Throughput: {cols / metrics[-1]['groups']:.1f}x")
    print(f"- Final Values Preserved: {metrics[-1]['preserved_values']:.1f}% of original")
    print("="*50)
    
    # Print final matrices
    print("\nFINAL RESULT:")
    print_matrix(current_matrix, "Final Value Matrix")
    print_matrix(current_index, "Final Index Matrix (Original Columns)")

if __name__ == "__main__":
    main()
