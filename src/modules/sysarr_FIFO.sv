`include "systolic_array_FIFO_if.vh"
`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */

module sysarr_FIFO(
    input logic clk, nRST,
    systolic_array_FIFO_if.FIFO fifo
);
    // Internal storage for FIFO
    logic [DW-1:0] fifo_mem [N-1:0]; //need space for two arrays 1 row
    logic [DW-1:0] nxt_fifo_mem [N-1:0];

    // read and write pointer
    logic [$clog2(N)-1:0] rd_ptr;
    logic [$clog2(N)-1:0] nxt_rd_ptr;
    logic [$clog2(N)-1:0] wrt_ptr;
    logic [$clog2(N)-1:0] nxt_wrt_ptr;

    always_ff @(posedge clk or negedge nRST) begin
        if (!nRST) begin
            fifo_mem <= '{default: '0};     // Reset fifo mem to all zeros
            wrt_ptr <= '0;
            rd_ptr <= '0;
        end else begin
            fifo_mem <= nxt_fifo_mem;
            wrt_ptr <= nxt_wrt_ptr;
            rd_ptr <= nxt_rd_ptr;
        end
    end
    always_comb begin
        nxt_fifo_mem = fifo_mem;
        nxt_rd_ptr = rd_ptr;
        nxt_wrt_ptr = wrt_ptr;
        fifo.out_vals = fifo_mem[rd_ptr];
        if (fifo.load) begin
            nxt_fifo_mem[wrt_ptr] = fifo.load_vals;
            nxt_wrt_ptr = wrt_ptr + 1;
        end
        if (fifo.shift)begin
            nxt_rd_ptr = rd_ptr + 1;    // Shift values forward 
        end
    end

endmodule
