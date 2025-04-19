`ifndef SYSTOLIC_ARRAY_CONTROL_UNIT_IF_VH
`define SYSTOLIC_ARRAY_CONTROL_UNIT_IF_VH

`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */

interface systolic_array_control_unit_if;

  // Signals
  // logic weight_en;        // Current input bus is for array weights
  logic input_en;         // Current input bus is for array inputs
/* verilator lint_off UNUSEDSIGNAL */
  logic partial_en;       // Memory is sending partial sums
  /* verilator lint_off UNUSEDSIGNAL */
  logic fifo_has_space;   // FIFOS can load more inputs 
  logic [N*N-1:0] PE_start;           // Start signals for all PEs
  logic PE_value_ready;      // done signal for the PE
  logic [N-1:0] add_start;           // Start signals for all partial sum adders
  logic [N-1:0] add_value_ready;      // done signal for the adders
  logic [N-1:0] in_fifo_shift;      // Shift signal for partial sum FIFOS
  logic [N-1:0] ps_fifo_shift;      // Shift signal for FIFOS
  logic [N*N-1:0] PE_shift;         // Shift signal for PEs
  logic [N-1:0] acc_end_flags;  // end flags come out of PEs if its the last value
  logic drained;

  // Control Unit Ports
  modport control_unit(
    input  input_en, partial_en, PE_value_ready, add_value_ready, acc_end_flags, 
    output fifo_has_space, in_fifo_shift, ps_fifo_shift, PE_shift, PE_start, add_start, drained
  );
endinterface

`endif
