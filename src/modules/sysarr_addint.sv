`include "systolic_array_add_if.vh"
`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */

module sysarr_add (
    /* verilator lint_off UNUSEDSIGNAL */
    input logic clk, nRST,
    /* verilator lint_off UNUSEDSIGNAL */
    systolic_array_add_if.add adder
);
    logic [2:0]count;
    logic [2:0]nxt_count;
    always_ff @(posedge clk, negedge nRST) begin
        if(nRST == 1'b0)begin
            count <= '0;
        end else begin
            count <= nxt_count;
        end 
    end
always_comb begin
    adder.add_output= '0;
    nxt_count = count;
    if (adder.start == 1'b1 || count > 0)begin
        nxt_count = count + 1;
    end
    adder.value_ready = 0;
    if (count == 3-1)begin // 3-1
        adder.add_output = adder.add_input1 + adder.add_input2;
        adder.value_ready = 1;
        nxt_count = 0;
    end
end
   
   
endmodule
