`ifndef SYSTOLIC_ARRAY_IF_VH
`define SYSTOLIC_ARRAY_IF_VH

`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */

interface systolic_array_if;
  // Signals
  logic weight_en;        // Current input bus is for array weights
  logic [$clog2(N)-1:0] row_in_en;   // Row enable for weights
  logic input_en;         // Current input bus is for array inputs
  logic partial_en;       // Memory is sending partial sums
  logic out_en;
  /* verilator lint_off UNUSEDSIGNAL */
  logic drained;          // Indicates the systolic array is fully drained
  /* verilator lint_off UNUSEDSIGNAL */
  /* verilator lint_off UNUSEDSIGNAL */
  logic fifo_has_space;   // Indicates FIFO has space for another GEMM
  /* verilator lint_off UNUSEDSIGNAL */
  logic [DW*N-1:0] vals_in;            // Input data for the array
  logic [IND*N-1:0] inds_in;            // Input data for the indices
  logic [N-1:0] ends_in;            // Input data for the ends pointers
  logic [DW*N-1:0] array_in_partials;   // Input partial sums for the array
  logic [DW*N-1:0] array_output;        // Output data from the array

  // Memory Ports
  //memory to systolic array
  modport memory_array (  
    input  weight_en, input_en, partial_en, row_in_en, vals_in, inds_in, ends_in, array_in_partials,
    output drained, fifo_has_space, array_output, out_en
  );

endinterface

`endif
