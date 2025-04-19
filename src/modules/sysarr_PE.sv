`include "systolic_array_MAC_if.vh"
`include "systolic_array_PE_if.vh"
`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */

module sysarr_PE(
    /* verilator lint_off UNUSEDSIGNAL */
    input logic clk, nRST,
    /* verilator lint_off UNUSEDSIGNAL */
    systolic_array_PE_if.PE pe
);
    systolic_array_MAC_if mac_if(); 
    sysarr_MAC MAC_inst (.clk(clk), .nRST(nRST), .mac_if(mac_if.MAC));
    //input  start, weight, in_value, shift, in_accumulate, in_ind, weight_col, in_end
    //output out_accumulate, val_pass, value_ready, ind_pass, end_pass, acc_en
    logic end_reg; // end flag
    logic acc_en_reg; // acc enable flag
    logic [IND-1:0] ind_reg; // index 
    logic [DW-1:0] value_reg; // input value
    logic [DW-1:0] acc_reg; // accumulation input
    logic [DW-1:0] out_acc_reg; // accumulation output
    logic [DW-1:0] mac_in_reg; // mac input reg
    // next signals
    logic nxt_end_reg; // end flag
    logic nxt_acc_en_reg; // acc enable flag
    logic [IND-1:0] nxt_ind_reg; // index 
    logic [DW-1:0] nxt_value_reg; // input value
    logic [DW-1:0] nxt_acc_reg; // accumulation input
    logic [DW-1:0] nxt_out_acc_reg; // accumulation output
    logic [DW-1:0] nxt_mac_in_reg; // mac input reg
    logic ready_or_not;
    // helper signal
    logic [5:0] count;
    logic [5:0] nxt_count;
    assign ready_or_not = count == MAC_TIME;
    always_ff @(posedge clk, negedge nRST) begin
        if(nRST == 1'b0)begin
            end_reg <= '0;
            acc_en_reg <= '0;
            ind_reg <= '0;
            value_reg <= '0;
            acc_reg <= '0;
            out_acc_reg <= '0;
            mac_in_reg <= '0;
            count <= '0;
        end else begin
            end_reg <= nxt_end_reg;
            acc_en_reg <= nxt_acc_en_reg;
            ind_reg <= nxt_ind_reg;
            value_reg <= nxt_value_reg;
            acc_reg <= nxt_acc_reg;
            out_acc_reg <= nxt_out_acc_reg;
            mac_in_reg <= nxt_mac_in_reg;
            count <= nxt_count;
        end 
    end
    logic equal;
    assign equal = ind_reg == pe.weight_col;
    always_comb begin
        nxt_end_reg = end_reg;
        nxt_acc_en_reg = acc_en_reg;
        nxt_ind_reg = ind_reg;
        nxt_value_reg = value_reg;
        nxt_acc_reg = acc_reg;
        nxt_out_acc_reg = out_acc_reg; // what comes out
        nxt_mac_in_reg = mac_in_reg;
        if (pe.shift)begin
            nxt_end_reg = pe.in_end;
            nxt_ind_reg = pe.in_ind;
            nxt_value_reg = pe.in_value;
            nxt_acc_reg = pe.in_accumulate;
            if (pe.in_ind == pe.weight_col)begin
                nxt_mac_in_reg = pe.in_value;
            end
        end
        // pe ready and it was an ender
        if (ready_or_not && end_reg)begin
            nxt_out_acc_reg = mac_if.out_accumulate;
            nxt_acc_en_reg = end_reg;
        end
        // only high for one pls :D
        if (acc_en_reg)begin
            nxt_acc_en_reg = '0;
        end
        
    end
    always_comb begin
        nxt_count = count;
        if (ready_or_not || pe.shift)begin //if (count == 3 || pe.shift)begin
            nxt_count = '0;
        end else if (pe.start || count > 0)begin// we don't actually rely on stupid MAC
            nxt_count = count + 1;
        end
    end
    always_comb begin : pe_out
        pe.out_accumulate = out_acc_reg;
        pe.val_pass = value_reg;
        pe.ind_pass = ind_reg;
        pe.end_pass = end_reg;
        pe.acc_en = acc_en_reg;
        // pe.value_ready = mac_if.value_ready;
        pe.value_ready = ready_or_not; //3
    end
    always_comb begin : mac_connections
        mac_if.start = pe.start && end_reg;
        mac_if.weight = pe.weight;
        mac_if.in_value = mac_in_reg;
        mac_if.in_accumulate = acc_reg;
    end

endmodule
