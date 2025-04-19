`timescale 1ns / 1 ns

`include "systolic_array_FIFO_if.vh"

module sysarr_FIFO_tb();

// Parameters
parameter PERIOD = 10;

// Testbench Signals
logic tb_clk = 0;
logic tb_nrst;


// Clk init
always #(PERIOD/2) tb_clk++;
// FIFO_if instance
systolic_array_FIFO_if fifo_if();

sysarr_FIFO DUT (.nRST(tb_nrst), .clk(tb_clk), .fifo(fifo_if.FIFO));
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
integer i;
// Test scenarios
initial begin
    // Initialize signals
    tb_clk = 0;
    tb_nrst = 0;
    fifo_if.load = 0;
    fifo_if.shift = 0;
    fifo_if.load_vals = 0;
    fifo_if.load_inds = '0;

    // Reset 
    reset();
    // Test case 1: Load values into the FIFO
    $display("fifo_if.out_vals before load= %h", fifo_if.out_vals);
    $display("fifo_if.out_inds before load= %h", fifo_if.out_inds);
    // fifo_if.load_vals = 16'h0123456789ABCDEF; // Example data
    fifo_if.load_vals = 16'h0123; // Example data
    fifo_if.load_inds = 'd1;
    fifo_if.load = 1; // Ensure data is only loaded when load signal is high
    @(posedge tb_clk);
    fifo_if.load = 0;
    @(posedge tb_clk);
    fifo_if.load_vals = 16'h4567; // Example data
    fifo_if.load_inds = 'd2;
    fifo_if.load = 1; // Ensure data is only loaded when load signal is high
    @(posedge tb_clk);
    fifo_if.load = 0;
    @(posedge tb_clk);
    fifo_if.load_vals = 16'h89AB; // Example data
    fifo_if.load_inds = 'd3;
    fifo_if.load = 1; // Ensure data is only loaded when load signal is high
    @(posedge tb_clk);
    fifo_if.load = 0;
    @(posedge tb_clk);
    fifo_if.load_vals = 16'hCDEF; // Example data
    fifo_if.load_inds = 'd4;
    fifo_if.load = 1; // Ensure data is only loaded when load signal is high
    @(posedge tb_clk);
    fifo_if.load = 0;
    @(posedge tb_clk);
    $display("fifo_if.out_vals after load= %h", fifo_if.out_vals);
    $display("fifo_if.out_inds after load= %h", fifo_if.out_inds);
    // Shift values out the FIFO
    for (i = 0; i <= 3; i = i + 1) begin
        fifo_if.shift = 1;
        @(posedge tb_clk);
        fifo_if.shift = 0; 
        $display("fifo_if.out_vals = %h", fifo_if.out_vals);
        $display("fifo_if.out_inds = %h", fifo_if.out_inds);
    end

    #50;
    $stop;
end

endmodule
