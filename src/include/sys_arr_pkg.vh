`ifndef SYS_ARR_PKG_VH
`define SYS_ARR_PKG_VH

package sys_arr_pkg;
  parameter N = 4; // dimensions of the systolic array
  parameter DW = 16; // data width
  parameter IND = 8; // index bits
  parameter MAC_TIME= 3; // 3 for int 19 for fp16
endpackage

`endif
