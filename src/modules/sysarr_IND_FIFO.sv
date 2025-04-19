`include "systolic_array_IND_FIFO_if.vh"
`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */

module sysarr_IND_FIFO(
    input logic clk, nRST,
    systolic_array_IND_FIFO_if.IND_FIFO ind_fifo
);
    // Internal storage for ind_FIFO
    logic [DW-1:0] ind_fifo_mem [N-1:0]; //need space for two arrays 2 rows of matrix rows
    logic [DW-1:0] nxt_ind_fifo_mem [N-1:0];
    logic [IND-1:0] ind_fifo_ind [N-1:0]; //need space for two arrays 2 rows of matrix rows
    logic [IND-1:0] nxt_ind_fifo_ind [N-1:0];
    logic ind_fifo_end [N-1:0]; //need space for two arrays 2 rows of matrix rows
    logic nxt_ind_fifo_end [N-1:0];

    // read and write pointer
    logic [$clog2(N)-1:0] rd_ptr;
    logic [$clog2(N)-1:0] nxt_rd_ptr;
    logic [$clog2(N)-1:0]wrt_ptr;
    logic [$clog2(N)-1:0]nxt_wrt_ptr;

    always_ff @(posedge clk or negedge nRST) begin
        if (!nRST) begin
            ind_fifo_mem <= '{default: '0};     // Reset ind_fifo mem to all zeros
            ind_fifo_ind <= '{default: '0};     // Reset ind_fifo mem to all zeros
            ind_fifo_end <= '{default: '0};
            wrt_ptr <= '0;
            rd_ptr <= '0;
        end else begin
            ind_fifo_mem <= nxt_ind_fifo_mem;
            ind_fifo_ind <= nxt_ind_fifo_ind;
            ind_fifo_end <= nxt_ind_fifo_end;
            wrt_ptr <= nxt_wrt_ptr;
            rd_ptr <= nxt_rd_ptr;
        end
    end
    always_comb begin
        nxt_ind_fifo_mem = ind_fifo_mem;
        nxt_ind_fifo_ind = ind_fifo_ind;
        nxt_ind_fifo_end = ind_fifo_end;
        nxt_rd_ptr = rd_ptr;
        nxt_wrt_ptr = wrt_ptr;
        ind_fifo.out_vals = ind_fifo_mem[rd_ptr];
        ind_fifo.out_inds = ind_fifo_ind[rd_ptr];
        ind_fifo.out_ends = ind_fifo_end[rd_ptr];
        if (ind_fifo.load) begin
            nxt_ind_fifo_mem[wrt_ptr] = ind_fifo.load_vals;
            nxt_ind_fifo_ind[wrt_ptr] = ind_fifo.load_inds;
            nxt_ind_fifo_end[wrt_ptr] = ind_fifo.load_ends;
            nxt_wrt_ptr = wrt_ptr + 1;
        end
        if (ind_fifo.shift)begin
            nxt_rd_ptr = rd_ptr + 1;    // Shift values forward 
        end
    end

endmodule
