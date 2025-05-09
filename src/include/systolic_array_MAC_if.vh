`ifndef SYSTOLIC_ARRAY_MAC_IF_VH
`define SYSTOLIC_ARRAY_MAC_IF_VH

`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */

interface systolic_array_MAC_if;

  // Signals
  /* verilator lint_off UNUSEDSIGNAL */
  logic start;          // MAC unit start signal
  /* verilator lint_off UNUSEDSIGNAL */
  logic value_ready;
  logic [DW-1:0] weight;                    // Input weight value to be pre-loaded
  logic [DW-1:0] in_value;                  // Input value to be multiplied
  logic [DW-1:0] in_accumulate;             // Input accumulate value from above
  logic [DW-1:0] out_accumulate;            // Output accumulate value

  // MAC Port for Array
  modport MAC(
    input  start, weight, in_value, in_accumulate,
    output out_accumulate, value_ready
  );
endinterface

`endif
