`ifndef SYS_ARR_PKG_VH
`define SYS_ARR_PKG_VH

package sys_arr_pkg;
  parameter N = 32; // dimensions of the systolic array
  parameter DW = 16; // data width
  parameter IND = 9; // index bits
  parameter MAC_TIME= 19; // 3 for int 19 for fp16
endpackage

`endif
