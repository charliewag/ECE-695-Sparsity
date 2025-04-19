`ifndef SYSTOLIC_ARRAY_IND_FIFO_IF_VH
`define SYSTOLIC_ARRAY_IND_FIFO_IF_VH

`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */

interface systolic_array_IND_FIFO_if;

  // Signals
  logic load;     // FIFO load signal
  logic shift;    // FIFO shift signal
  logic [DW-1:0] load_vals;   // Load for a row of a matrix
  logic [IND-1:0] load_inds;   // Load for a row of a matrix
  logic load_ends;
  logic [DW-1:0] out_vals;           // Final array_dim value to be seen by array
  logic [IND-1:0] out_inds;           // Final array_dim value to be seen by array
  logic out_ends;
  
  // Ports
  modport IND_FIFO(
    input  load, shift, load_vals, load_inds, load_ends,
    output out_vals, out_inds, out_ends
  );
endinterface

`endif
