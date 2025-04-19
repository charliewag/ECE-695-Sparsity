`ifndef SYSTOLIC_ARRAY_PE_IF_VH
`define SYSTOLIC_ARRAY_PE_IF_VH

`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */

interface systolic_array_PE_if;

  // MAC Signals
  logic start;
  logic value_ready;
  logic [DW-1:0] weight;                    // Input weight value to be pre-loaded
  logic [DW-1:0] in_value;                  // Input value to be multiplied
  logic shift;                              // shift the input to the next array
  logic [DW-1:0] val_pass;                  // Input value to be passed to next MAC
  logic [DW-1:0] in_accumulate;             // Input accumulate value from above
  logic [DW-1:0] out_accumulate;            // Output accumulate value
  // PE Signals
  logic [IND-1:0] in_ind;             // input index
  logic [IND-1:0] ind_pass;        // input index pass on
  logic [IND-1:0] weight_col;         // weight column index
  logic in_end;                       // input end flag
  logic end_pass;                  // input end flag pass on
  logic acc_en;                       // input accumulate send flag

  // PE Port for Array
  modport PE(
    input  start, weight, in_value, shift, in_accumulate, in_ind, weight_col, in_end, 
    output out_accumulate, val_pass, value_ready, ind_pass, end_pass, acc_en
  );
endinterface

`endif
