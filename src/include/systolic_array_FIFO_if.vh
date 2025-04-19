`ifndef SYSTOLIC_ARRAY_FIFO_IF_VH
`define SYSTOLIC_ARRAY_FIFO_IF_VH

`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */

interface systolic_array_FIFO_if;
  // Signals
  logic load;     // FIFO load signal
  logic shift;    // FIFO shift signal
  logic [DW-1:0] load_vals;   // Load for a row of a matrix
  logic [DW-1:0] out_vals;           // Final array_dim value to be seen by array
  // Ports
  modport FIFO(
    input  load, shift, load_vals, 
    output out_vals
  );
endinterface

`endif
