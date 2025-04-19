`timescale 1ns / 1 ns

`include "systolic_array_PE_if.vh"
`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */

module sysarr_PE_tb();

// Parameters
parameter PERIOD = 10;

// Testbench Signals
logic tb_clk = 0;
logic tb_nrst;


// Clk init
always #(PERIOD/2) tb_clk++;
// FIFO_if instance
systolic_array_PE_if pe_if();

sysarr_PE DUT (.nRST(tb_nrst), .clk(tb_clk), .pe(pe_if.PE));
task reset;
    begin
      tb_nrst = 1'b0;
      @(posedge tb_clk);
      @(posedge tb_clk);
      @(negedge tb_clk);
      tb_nrst = 1'b1;
      @(posedge tb_clk);
      @(posedge tb_clk);
    end
endtask
task show_outputs;
    $display( "out_accumulate = %d",pe_if.out_accumulate);
    $display( "value_ready = %d",pe_if.value_ready);
    $display( "val_pass = %d",pe_if.val_pass);
    $display( "weight = %d",pe_if.weight);
    $display( "weight_col = %d",pe_if.weight_col);
    $display( "ind_pass = %d",pe_if.ind_pass);
    $display( "end_pass = %d",pe_if.end_pass);
    $display( "acc_en = %d",pe_if.acc_en);
endtask
int flag;
// Test scenarios
initial begin
    $dumpfile("dump_pe.vcd");  // For VCD format
    $dumpvars(0, sysarr_PE_tb);
    // Initialize signals
    tb_clk = 0;
    tb_nrst = 0;
    pe_if.start = '0;
    pe_if.weight = '0;
    pe_if.in_value = '0;
    pe_if.shift = '0;
    pe_if.in_accumulate = '0;
    pe_if.in_ind = '0;
    pe_if.weight_col = '0;
    pe_if.in_end = '0;

    // Reset 
    reset();
    // Test case 1: matching indices with end
    // setup
    pe_if.weight = 'd5;
    pe_if.weight_col = 'd1;
    pe_if.in_value = 'd2;
    pe_if.in_ind = 'd1;
    pe_if.in_accumulate = 'd11;
    pe_if.in_end = 1'b1;
    // shift in values to mac
    pe_if.shift = 1;
    @(posedge tb_clk);
    pe_if.shift = 0;
    show_outputs();
    pe_if.start = 1;
    @(posedge tb_clk);
    pe_if.start = 0;
    // show_outputs();
    // repeat(15) @(posedge tb_clk);
    flag = 1;
    while (flag == 1) begin
        @(posedge tb_clk);
        if (pe_if.value_ready == 1'b1)begin
            flag = 0;
        end
    end
    @(posedge tb_clk);
    show_outputs();
    // Test case 2: matching indices with no end
    $display("matching indices with no end");
    reset();
    // setup
    pe_if.weight = 'd5;
    pe_if.weight_col = 'd1;
    pe_if.in_value = 'd2;
    pe_if.in_ind = 'd1;
    pe_if.in_accumulate = 'd11;
    pe_if.in_end = 1'b0;
    // shift in values to mac
    pe_if.shift = 1;
    @(posedge tb_clk);
    pe_if.shift = 0;
    show_outputs();
    pe_if.start = 1;
    @(posedge tb_clk);
    pe_if.start = 0;
    // show_outputs();
    repeat(15) @(posedge tb_clk);
    // flag = 1;
    // while (flag == 1) begin
    //     @(posedge tb_clk);
    //     if (pe_if.value_ready == 1'b1)begin
    //         flag = 0;
    //     end
    // end
    // @(posedge tb_clk);
    show_outputs();
    $display("Follow with nonmatching with end");
    // follow with non-matchin with end
    // setup
    pe_if.weight = 'd5;
    pe_if.weight_col = 'd1;
    pe_if.in_value = 'd20;
    pe_if.in_ind = 'd3;
    pe_if.in_accumulate = 'd11;
    pe_if.in_end = 1'b1;
    // shift in values to mac
    pe_if.shift = 1;
    @(posedge tb_clk);
    pe_if.shift = 0;
    show_outputs();
    pe_if.start = 1;
    @(posedge tb_clk);
    pe_if.start = 0;
    show_outputs();
    // repeat(15) @(posedge tb_clk);
    flag = 1;
    while (flag == 1) begin
        @(posedge tb_clk);
        if (pe_if.value_ready == 1'b1)begin
            flag = 0;
        end
    end
    @(posedge tb_clk);
    show_outputs();





    #50;
    $stop;
end

endmodule
