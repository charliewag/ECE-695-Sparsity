`include "systolic_array_if.vh"
`include "systolic_array_control_unit_if.vh"
`include "systolic_array_MAC_if.vh"
`include "systolic_array_add_if.vh"
`include "systolic_array_FIFO_if.vh"
`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */
`timescale 1 ps / 1 ps

module systolic_array_tb();
  // clk/reset
  logic tb_nRST;

  // Memory interface instance
  systolic_array_if memory_if();

  // Clock gen
  parameter PERIOD = 10;
  logic tb_clk = 0;
  always #(PERIOD/2) tb_clk++;
  // FILE I/O
  int out_file, file, k, i, j, z, y, r, in, which;
  /* verilator lint_off UNUSEDSIGNAL */
  string line;
  /* verilator lint_off UNUSEDSIGNAL */
  logic [DW-1:0] temp_weights[N][N];
  logic [DW-1:0] temp_inputs[N][N];
  logic [DW-1:0] temp_partials[N][N];
  logic [DW-1:0] temp_outputs[N][N];

  logic [(N*DW)-1:0] m_weights[N];
  logic [(N*DW)-1:0] m_inputs[N];
  logic [(N*DW)-1:0] m_partials[N];
  logic [(N*DW)-1:0] m_outputs[N];
  int loaded_weights;
  // Reset task
  task reset;
    begin
      tb_nRST = 1'b0;
      @(posedge tb_clk);
      @(posedge tb_clk);
      @(negedge tb_clk);
      tb_nRST = 1'b1;
      @(posedge tb_clk);
      @(posedge tb_clk);
    end
  endtask

  task row_load(
    input logic [1:0] rtype,
    input logic [$clog2(N)-1:0] rinnum,
    input logic [$clog2(N)-1:0] rpsnum,
    input logic [(N*DW)-1:0] rinput,
    input logic [(N*DW)-1:0] rpartial
  );
    begin
      if (rtype == 2'b00) begin
        memory_if.weight_en = 1'b1;
      end else if (|rtype) begin
        memory_if.input_en = rtype[0];
        memory_if.partial_en = rtype[1];
      end
      memory_if.row_in_en = rinnum;
      memory_if.row_ps_en = rpsnum;
      memory_if.array_in = rinput;
      memory_if.array_in_partials = rpartial;
      @(posedge tb_clk);
      memory_if.array_in = '0;
      memory_if.array_in_partials = '0;
      memory_if.weight_en = 1'b0;
      memory_if.partial_en = 1'b0;
      memory_if.input_en = 1'b0;
      memory_if.row_in_en = '0;
      memory_if.row_ps_en = '0;
    end
  endtask

  task get_matrices(output int weights);
    begin
      int iterations;
      weights = 0;
      which = 0;
      $fgets(line, file);
      if (line == "Weights\n") begin
        which = 1;
        iterations = 3;
        weights = 1;
      end else if (line == "Inputs\n") begin
        which = 2;
        iterations = 2;
      end
      for (k = 0; k < iterations; k++) begin
        for (i = 0; i < N; i = i + 1) begin
          for (j = 0; j < N; j = j + 1) begin
            if (which == 1)begin
              $fscanf(file, "%d ", temp_weights[i][j]);
            end else if (which == 2) begin
              $fscanf(file, "%d ", temp_inputs[i][j]);
            end else begin
              $fscanf(file, "%d ", temp_partials[i][j]);
            end
          end  
        end
        which = which + 1;
        $fgets(line, file);
      end
      for (i = 0; i < N; i++)begin
        m_weights[i] = {>>{temp_weights[i]}};
        m_inputs[i] = {>>{temp_inputs[i]}};
        m_partials[i] = {>>{temp_partials[i]}};
      end
    end
  endtask
  task get_m_output();
    begin
      for (i = 0; i < N; i = i + 1) begin
        for (j = 0; j < N; j = j + 1) begin
          $fscanf(out_file, "%d ", temp_outputs[i][j]);
        end
      end
      for (i = 0; i < N; i++)begin
        m_outputs[i] = {>>{temp_outputs[i]}};
      end
    end
  endtask
  task load_weights();
    for (r = 0; r < N; r++)begin
      /* verilator lint_off WIDTHTRUNC */
      row_load(.rtype(2'b00), .rinnum(r), .rpsnum('0), .rinput(m_weights[r]), .rpartial('0));
      /* verilator lint_off WIDTHTRUNC */
    end
  endtask
  task load_in_ps(input int delay);
    for (in = 0; in < N; in++)begin
      /* verilator lint_off WIDTHTRUNC */
      row_load(.rtype(2'b11), .rinnum(in), .rpsnum(in), .rinput(m_inputs[in]), .rpartial(m_partials[in]));
      /* verilator lint_off WIDTHTRUNC */
      repeat(delay) @(posedge tb_clk); // everyone else iteration delay
    end
  endtask

  // Instantiate the DUT
  systolic_array DUT (
    .clk    (tb_clk),
    .nRST   (tb_nRST),
    .memory (memory_if.memory_array)
  );
  always @(posedge tb_clk) begin
    if (memory_if.out_en == 1'b1)begin
      $display("\noutput row is %d", memory_if.row_out);
      if (m_outputs[memory_if.row_out] != memory_if.array_output)begin
        $display("OUTPUT INCORRECT");
        $display("Our Output is");
        // for (y = 0; y < N; y++)begin
        for (y = N; y > 0; y--)begin
          $write("%d, ", memory_if.array_output[y*DW-1-:DW]);
        end
        $display("");
      end else begin
        $display("CORRECT OUTPUT");
      end
      $display("Correct Output is");
      // for (z = 0; z < N; z++)begin
      for (z = N; z > 0; z--)begin
          $write("%d, ", m_outputs[memory_if.row_out][z*DW-1-:DW]);
      end
      $display("");
      /* verilator lint_off WIDTHEXPAND */
      if (memory_if.row_out == N-1)begin
      /* verilator lint_off WIDTHEXPAND */
        get_m_output();
      end
    end
  end
  int wait_flag;
  int done;
  // Test Stimulus
  initial begin
    $dumpfile("dump.vcd");  // For VCD format
    $dumpvars(0, systolic_array_tb);
    memory_if.weight_en = '0;
    memory_if.input_en = '0;
    memory_if.partial_en = '0;
    memory_if.row_in_en = '0;
    memory_if.row_ps_en = '0;
    memory_if.array_in = '0;
    memory_if.array_in_partials = '0;
    loaded_weights = 0;
    
    // any file
    file = $fopen("systolic_array_utils/matops2W.txt", "r");
    $system("/bin/python3 systolic_array_utils/matrix_mul.py systolic_array_utils/matops2W");
    out_file = $fopen("systolic_array_utils/matops2W_output.txt", "r");
    reset();
    done = $fgetc(out_file);
    // $display ("C %d", done);
    $ungetc(done, out_file);
    get_m_output();
    while (done >= 0)begin
      $display ("done %d", done);
      get_matrices(.weights(loaded_weights));
      wait_flag = 1;
      if (loaded_weights == 1)begin
        while (wait_flag == 1) begin
          @(posedge tb_clk);
          if (memory_if.drained == 1'b1)begin
            wait_flag = 0;
          end
        end
        // load weights and inputs 
        load_weights();
        load_in_ps(.delay(1));
      end else begin
        while (wait_flag == 1) begin
          @(posedge tb_clk);
          if (memory_if.fifo_has_space == 1'b1)begin
            wait_flag = 0;
          end
        end
        // loads inputs
        load_in_ps(.delay(1));
      end
      done = $fgetc(out_file);
      $ungetc(done, out_file);
    end
    wait_flag = 1;
    while (wait_flag == 1) begin
      @(posedge tb_clk);
      if (memory_if.drained == 1'b1)begin
        wait_flag = 0;
      end
    end

    $fclose(file);
    $fclose(out_file);
    #50;
    $stop;
  end

endmodule
