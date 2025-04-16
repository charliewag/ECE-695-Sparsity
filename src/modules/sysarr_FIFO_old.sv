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
    logic [2 * DW * N - 1 : 0] fifo_mem; //need space for two arrays 2 rows of matrix rows
    logic [2 * DW * N - 1 : 0] fifo_mem_nxt;
    // write pointer
    logic [$clog2(2 * N) : 0] wrt_ptr;
    logic [$clog2(2 * N) : 0] wrt_ptr_nxt;

    always_ff @(posedge clk or negedge nRST) begin
        if (!nRST) begin
            fifo_mem <= '0;     // Reset fifo mem to all zeros
            wrt_ptr <= '0;
        end else begin
            fifo_mem <= fifo_mem_nxt;
            wrt_ptr <= wrt_ptr_nxt;
        end
    end
    integer i;
    always_comb begin
        fifo_mem_nxt = fifo_mem;
        wrt_ptr_nxt = wrt_ptr;
        fifo.out = fifo_mem[DW - 1 : 0];
        if (fifo.load) begin
            for (i = 0; i < N; i = i + 1) begin
                /* verilator lint_off WIDTHEXPAND */
                fifo_mem_nxt[(N - i + wrt_ptr) * DW - 1 -: DW ] = fifo.load_values[i * DW +: DW ];
                /* verilator lint_off WIDTHEXPAND */
            end
            wrt_ptr_nxt = wrt_ptr_nxt + N;
        end
        if (fifo.shift)begin
            fifo_mem_nxt = fifo_mem_nxt >> DW;    // Shift values forward 
            if (wrt_ptr != '0) begin
                wrt_ptr_nxt = wrt_ptr_nxt - 1;
            end
        end
    end

endmodule
