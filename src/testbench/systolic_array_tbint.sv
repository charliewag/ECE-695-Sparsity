`include "systolic_array_if.vh"
`include "systolic_array_control_unit_if.vh"
`include "systolic_array_MAC_if.vh"
`include "systolic_array_add_if.vh"
`include "systolic_array_IND_FIFO_if.vh"
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
  parameter PERIOD = 1016;
  logic tb_clk = 0;
  always #(PERIOD/2) tb_clk++;
  // FILE I/O
  /* verilator lint_off UNUSEDSIGNAL */
  int out_file, file, k, i, j, z, y, r, in, which;
  /* verilator lint_off UNUSEDSIGNAL */
  /* verilator lint_off UNUSEDSIGNAL */
  string line;
  /* verilator lint_off UNUSEDSIGNAL */
  logic [DW-1:0] temp_weights[N][N];
  logic [IND-1:0] temp_weight_cols[N][N];
  logic [DW-1:0] temp_inputs[N][N];
  logic [IND-1:0] temp_indices[N][N];
  logic temp_ends[N][N];
  logic [DW-1:0] temp_partials[N];
  logic [DW-1:0] temp_outputs[N];

  logic [(N*DW)-1:0] m_weights[N];
  logic [(N*IND)-1:0] m_weight_cols[N];
  logic [(N*DW)-1:0] v_inputs[N];
  logic [(N*IND)-1:0] v_indices[N];
  logic [N-1:0] v_ends[N];
  logic [(N*DW)-1:0] v_partials;
  logic [(N*DW)-1:0] v_outputs;
  int loaded_weights;
  int input_rows;
  int done_out;
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

  task vec_load(
    input logic [1:0] rtype,
    input logic [$clog2(N)-1:0] rinnum,
    input logic [(N*DW)-1:0] rinput,
    input logic [(N*IND)-1:0] rindex,
    input logic [N-1:0] rend,
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
      memory_if.vals_in = rinput;
      memory_if.inds_in = rindex;
      memory_if.ends_in = rend;
      memory_if.array_in_partials = rpartial;
      @(posedge tb_clk);
      memory_if.vals_in = '0;
      memory_if.array_in_partials = '0;
      memory_if.weight_en = 1'b0;
      memory_if.partial_en = 1'b0;
      memory_if.input_en = 1'b0;
      memory_if.row_in_en = '0;
    end
  endtask

  task get_matrices(output int weights, output int rows);
    begin
      int iterations;
      int c;
      int unused;
      weights = 0;
      rows = -1;
      which = 0;
      unused = $fgets(line, file);
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
              unused = $fscanf(file, "(%d,%d) ", temp_weights[i][j],temp_weight_cols[i][j]);
            end else if (which == 2) begin
              c = $fgetc(file);
              // $display("char %d %d", c, i);
              unused = $ungetc(c, file);
              if (c==40)begin // another ( which means more inputs
                unused = $fscanf(file, "(%d,%d,%d) ", temp_inputs[i][j],temp_indices[i][j],temp_ends[i][j]);
              end else if (rows == -1)begin
                rows = i;
              end
              if (rows == -1 && i == N-1)begin
                rows = N;
              end
            end else if (i == 0) begin
              unused = $fscanf(file, "%d ", temp_partials[j]);
            end
          end
        end
        which = which + 1;
        unused = $fgets(line, file);
        // $display("getmats line %s", line);
        // $display("what what %d %d", weights, rows);
      end
      for (i = 0; i < N; i++)begin
        m_weights[i] = {>>{temp_weights[i]}};
        m_weight_cols[i] = {>>{temp_weight_cols[i]}};
        v_inputs[i] = {>>{temp_inputs[i]}};
        v_indices[i] = {>>{temp_indices[i]}};
        v_ends[i] = {>>{temp_ends[i]}};
      end
      v_partials = {>>{temp_partials}}; 
    end
  endtask
  task get_v_output();
    begin
      int unused;
      for (i = 0; i < N; i = i + 1) begin
        unused = $fscanf(out_file, "%d ", temp_outputs[i]);
      end
      v_outputs = {>>{temp_outputs}};
    end
  endtask
  task load_weights();
    for (r = 0; r < N; r++)begin
      /* verilator lint_off WIDTHTRUNC */
      vec_load(.rtype(2'b00), .rinnum(r), .rinput(m_weights[r]), .rindex(m_weight_cols[r]), .rend('0), .rpartial('0));
      /* verilator lint_off WIDTHTRUNC */
    end
  endtask
  task load_inputs(input int rows);
    vec_load(.rtype(2'b11), .rinnum('0), .rinput(v_inputs[0]), .rindex(v_indices[0]), .rend(v_ends[0]), .rpartial(v_partials));
    @(posedge tb_clk);
    for (in = 1; in < rows; in++)begin
      vec_load(.rtype(2'b01), .rinnum('0), .rinput(v_inputs[in]), .rindex(v_indices[in]), .rend(v_ends[in]), .rpartial('0));
      @(posedge tb_clk); 
    end
  endtask
  // Instantiate the DUT
  systolic_array DUT (
    .clk    (tb_clk),
    .nRST   (tb_nRST),
    .memory (memory_if.memory_array)
  );
  int unused;
  int count;
  always @(posedge tb_clk) begin
    count = count + 1;
    if (memory_if.out_en == 1'b1)begin
      done_out = $fgetc(out_file);
      unused = $ungetc(done_out, out_file);
      if (done_out > 0)begin
        get_v_output();
      end
      if (v_outputs != memory_if.array_output)begin
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
          $write("%d, ", v_outputs[z*DW-1-:DW]);
      end
      $display("");
    end
  end
  int done;
  // Test Stimulus
  initial begin
    memory_if.weight_en = '0;
    memory_if.input_en = '0;
    memory_if.partial_en = '0;
    memory_if.vals_in = '0;
    memory_if.inds_in = '0;
    memory_if.ends_in = '0;
    memory_if.array_in_partials = '0;
    loaded_weights = 0;
    input_rows = 0;
    count = 0;
    // any file
    // $system("/bin/python3 systolic_array_utils/matvec_creation.py sparse_test int 4 16");
    // $system("/bin/python3 systolic_array_utils/matmul_creation.py sparse_test int 4 16");
    // $system("/bin/python3 systolic_array_utils/pack_matvec_creation.py testing int 32 256");
    $system("/bin/python3 systolic_array_utils/pack_matmul_creation.py testing int 32 256");
    file = $fopen("systolic_array_utils/testing.txt", "r");
    out_file = $fopen("systolic_array_utils/testing_output.txt", "r");

    reset();
    done = $fgetc(file);
    unused = $ungetc(done, file);
    // get_v_output();
    while (done >= 0)begin
      get_matrices(.weights(loaded_weights), .rows(input_rows));
      // $display("%d %d", loaded_weights, input_rows);
      if (loaded_weights == 1)begin
        $display("Load new weights");
        load_weights();                          // DOUBLE BUFFERED WEIGHTS
        wait(memory_if.drained == 1'b1);
        // load weights and inputs 
        // load_weights();                          // NO DOUBLE BUFFERED WEIGHTS
        load_inputs(.rows(input_rows));
      end else begin
        // $display("Pipeline new inputs");
        wait(memory_if.fifo_has_space == 1'b1);
        // loads inputs
        load_inputs(.rows(input_rows));
      end
      @(posedge tb_clk); // need for matrix matrix
      done = $fgetc(file);
      unused = $ungetc(done, file);
    end
    // unused = $fgets(line, file);
    // 
    // repeat(150) @(posedge tb_clk);
    wait(memory_if.drained == 1'b1);
    // wait (memory_if.out_en == 1'b1);
    done = $fgetc(out_file);
    unused = $ungetc(done, out_file);
    while (done > 0) begin
      wait (memory_if.out_en == 1'b1);
      done = $fgetc(out_file);
      unused = $ungetc(done, out_file);
      @(posedge tb_clk);
    end
    // repeat(150) @(posedge tb_clk);
    $display("Count = %d", count);
    #50;
    $stop;
    $fclose(file);
    $fclose(out_file);
  end

endmodule
