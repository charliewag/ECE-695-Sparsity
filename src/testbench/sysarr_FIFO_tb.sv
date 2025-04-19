`timescale 1ns / 1 ns

`include "systolic_array_PS_FIFO_if.vh"

module sysarr_PS_FIFO_tb();

// Parameters
parameter PERIOD = 10;

// Testbench Signals
logic tb_clk = 0;
logic tb_nrst;


// Clk init
always #(PERIOD/2) tb_clk++;
// ps_fifo instance
systolic_array_PS_FIFO_if ps_fifo_if();

sysarr_PS_FIFO DUT (.nRST(tb_nrst), .clk(tb_clk), .ps_fifo(ps_fifo_if.PS_FIFO));
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
    ps_fifo_if.load = 0;
    ps_fifo_if.shift = 0;
    ps_fifo_if.load_vals = 0;

    // Reset 
    reset();
    // Test case 1: Load values into the FIFO
    $display("ps_fifo.out_vals before load= %h", ps_fifo_if.out_vals);
    // ps_fifo.load_vals = 16'h0123456789ABCDEF; // Example data
    ps_fifo_if.load_vals = 16'h0123; // Example data
    ps_fifo_if.load = 1; // Ensure data is only loaded when load signal is high
    @(posedge tb_clk);
    ps_fifo_if.load = 0;
    @(posedge tb_clk);
    ps_fifo_if.load_vals = 16'h4567; // Example data
    ps_fifo_if.load = 1; // Ensure data is only loaded when load signal is high
    @(posedge tb_clk);
    ps_fifo_if.load = 0;
    @(posedge tb_clk);
    ps_fifo_if.load_vals = 16'h89AB; // Example data
    ps_fifo_if.load = 1; // Ensure data is only loaded when load signal is high
    @(posedge tb_clk);
    ps_fifo_if.load = 0;
    @(posedge tb_clk);
    ps_fifo_if.load_vals = 16'hCDEF; // Example data
    ps_fifo_if.load = 1; // Ensure data is only loaded when load signal is high
    @(posedge tb_clk);
    ps_fifo_if.load = 0;
    @(posedge tb_clk);
    $display("ps_fifo.out_vals after load= %h", ps_fifo_if.out_vals);
    // Shift values out the FIFO
    for (i = 0; i <= 3; i = i + 1) begin
        ps_fifo_if.shift = 1;
        @(posedge tb_clk);
        ps_fifo_if.shift = 0; 
        $display("ps_fifo.out_vals = %h", ps_fifo_if.out_vals);
    end

    #50;
    $stop;
end

endmodule
