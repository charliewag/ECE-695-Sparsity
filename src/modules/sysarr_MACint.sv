`include "systolic_array_MAC_if.vh"
`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */

module sysarr_MAC(
    /* verilator lint_off UNUSEDSIGNAL */
    input logic clk, nRST,
    /* verilator lint_off UNUSEDSIGNAL */
    systolic_array_MAC_if.MAC mac_if
);
    logic [2:0] count;
    logic [2:0] nxt_count;

    always_ff @(posedge clk, negedge nRST) begin
        if(nRST == 1'b0)begin
            count <= '0;
        end else begin
            count <= nxt_count;
        end 
    end

   always_comb begin
    mac_if.out_accumulate = '0;
    nxt_count = count;
    if (mac_if.start == 1'b1 || count > 0)begin
        nxt_count = count + 1;
    end
    mac_if.value_ready = 0;
    if (count == 3)begin //1+3-1
        mac_if.out_accumulate = (mac_if.in_value * mac_if.weight) + mac_if.in_accumulate;
        nxt_count = 0;
        mac_if.value_ready = 1;
    end
end
endmodule
