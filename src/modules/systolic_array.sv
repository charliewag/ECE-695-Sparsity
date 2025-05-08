`include "systolic_array_if.vh"
`include "systolic_array_control_unit_if.vh"
`include "systolic_array_PE_if.vh"
`include "systolic_array_add_if.vh"
`include "systolic_array_IND_FIFO_if.vh"
`include "systolic_array_FIFO_if.vh"
`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */


module systolic_array(
    input logic clk, nRST,
    systolic_array_if.memory_array memory
);
    // Input to systolic array
    logic [DW*N-1:0] input_vals;
    logic [IND*N-1:0] input_inds;
    logic [N-1:0] input_ends;
    logic [DW*N-1:0] weights_input;
    logic [IND*N-1:0] in_weights_cols;
    logic [N*N-1:0] any_ready;
    // logic [DW*N-1:0] partial_sums;
    // Load signals within systolic array
    logic [N-1:0] load_row_w;
    // how to know when we are done
    logic [N-1:0] acc_ens;
    // Partial Sum adder inputs
    logic [DW-1:0] ps_add_inputs [N-1:0];
    // Weight Registers
    logic [DW*N-1:0] weights [N-1:0];
    logic [IND*N-1:0] weight_cols [N-1:0];
    // double buff
    logic [DW*N-1:0] weights2 [N-1:0];
    logic [IND*N-1:0] weight_cols2 [N-1:0];
    // use weights 
    logic [DW*N-1:0] use_weights [N-1:0];
    logic [IND*N-1:0] use_weight_cols [N-1:0];
    logic load_weight_ptr;
    logic nxt_load_weight_ptr;
    logic use_weight_ptr;
    logic nxt_use_weight_ptr;
    logic [N-1:0] weights_loaded;
    logic [N-1:0] nxt_weights_loaded;
    // Output Registers
    logic [DW-1:0] outputs [N-1:0];
    logic out_rdy;
    logic nxt_out_rdy;
    logic [N-1:0] add_rdy;
    logic [DW*N-1:0] flat_output;
    logic out_fifo_shift;
    logic nxt_drained;
    logic start;
    logic nxt_start;
    // Generate variables
    genvar i,j,l,m,n,o,p;
    int q;

    // Instantiate Control Unit interface
    systolic_array_control_unit_if control_unit_if();

    // Instantiate the control unit
    sysarr_control_unit cu_inst(
        .clk(clk),
        .nRST(nRST),
        .cu(control_unit_if.control_unit)
    );

    // Instantiate PE unit interfaces
    systolic_array_PE_if pe_ifs[N*N-1:0] (); 
    // Instantiate partial sum adder interfaces
    systolic_array_add_if add_ifs[N-1:0] (); 
    // Instantiate Input Fifos
    systolic_array_IND_FIFO_if input_fifos_ifs[N-1:0] (); 
    // Instantiate Partial Fifos
    systolic_array_FIFO_if ps_fifos_ifs[N-1:0] ();
    // Instantiate Output Fifos
    systolic_array_FIFO_if out_fifos_ifs[N-1:0] ();

    always_ff @(posedge clk, negedge nRST) begin
        if(nRST == 1'b0)begin
            memory.drained <= '1;
            start <= 1'b1;
        end else begin
            start <= nxt_start;
            memory.drained <= nxt_drained && (|any_ready || start);
        end
    end
    always_comb begin
        nxt_start = start;
        if (memory.input_en)begin
            nxt_start = 1'b0;
        end
    end
    always_comb begin : control_unit_connections
        // control_unit_if.weight_en = memory.weight_en;
        control_unit_if.input_en = memory.input_en;
        control_unit_if.partial_en = memory.partial_en;
        control_unit_if.acc_end_flags = acc_ens;
        nxt_drained = control_unit_if.drained;
        memory.fifo_has_space = control_unit_if.fifo_has_space;
    end
    //Selection Muxes for the input bus
    always_comb begin : input_bus_identity
        input_vals = '0;
        weights_input = '0; //'{default: '0};
        input_inds = '0;
        input_ends = '0;
        in_weights_cols = '0;
        load_row_w = '0;
        if (memory.input_en) begin
            input_vals = memory.vals_in;
            input_inds = memory.inds_in;
            input_ends = memory.ends_in;
        end else if (memory.weight_en) begin
            weights_input = memory.vals_in;
            in_weights_cols = memory.inds_in;
            load_row_w[memory.row_in_en] = 1'b1;
        end
    end
    // Weight Registers Generation
    always_ff @(posedge clk, negedge nRST) begin : weights_pointer
        if(nRST == 1'b0)begin
            load_weight_ptr <= '0;
            use_weight_ptr <= '0;
            weights_loaded <= '0;
        end else begin
            load_weight_ptr <= nxt_load_weight_ptr;
            use_weight_ptr <= nxt_use_weight_ptr;
            weights_loaded <= nxt_weights_loaded;
        end
    end
    always_comb begin
        nxt_use_weight_ptr = use_weight_ptr;
        nxt_load_weight_ptr = load_weight_ptr;
        nxt_weights_loaded = weights_loaded;
        if (memory.weight_en)begin
            nxt_weights_loaded[memory.row_in_en] = 1'b1;
        end
        if (weights_loaded == '1)begin
            nxt_load_weight_ptr = !load_weight_ptr;
            nxt_weights_loaded = '0;
        end
        
        if (load_weight_ptr == use_weight_ptr)begin
            if (memory.drained)begin
                nxt_use_weight_ptr = !use_weight_ptr;
            end
        end
    end
    generate
        for (i = 0; i < N; i++) begin
            always_ff @(posedge clk, negedge nRST) begin : weights_registers
                if(nRST == 1'b0)begin
                    weights[i] <= '0;
                    weight_cols[i] <= '0;
                    weights2[i] <= '0;
                    weight_cols2[i] <= '0;
                end else if (load_row_w[i] == 1'b1) begin
                    if (load_weight_ptr == '0)begin
                        weights[i] <= weights_input;
                        weight_cols[i] <= in_weights_cols;
                    end else begin
                        weights2[i] <= weights_input;
                        weight_cols2[i] <= in_weights_cols;
                    end
                end
            end
        end
    endgenerate    
    assign use_weights = use_weight_ptr ? weights2 : weights;
    assign use_weight_cols = use_weight_ptr ? weight_cols2 : weight_cols;
    // Input Fifo Generation
    generate
        for (j = 0; j < N; j++) begin
            sysarr_IND_FIFO i_fifo (
                .clk(clk),
                .nRST(nRST),
                .ind_fifo(input_fifos_ifs[j].IND_FIFO));
            assign input_fifos_ifs[j].load = memory.input_en;
            assign input_fifos_ifs[j].shift = control_unit_if.in_fifo_shift[j];
            assign input_fifos_ifs[j].load_vals = input_vals[(N-1-j) * DW +: DW]; // top gets 0th
            assign input_fifos_ifs[j].load_inds = input_inds[(N-1-j) * IND +: IND];
            assign input_fifos_ifs[j].load_ends = input_ends[(N-1-j)];
        end
    endgenerate
    // Partial Sum Generation
    generate
        for (l = 0; l < N; l++) begin
            // sysarr_FIFO #(.SIZE(2*N)) ps_fifos (
            sysarr_FIFO #(.SIZE(2*N)) ps_fifos (
                .clk(clk),
                .nRST(nRST),
                .fifo(ps_fifos_ifs[l].FIFO));
            assign ps_fifos_ifs[l].load = memory.partial_en;
            assign ps_fifos_ifs[l].shift = control_unit_if.ps_fifo_shift[l];
            assign ps_fifos_ifs[l].load_vals = memory.array_in_partials[(N-1-l) * DW +: DW]; //load vector across each
            assign ps_add_inputs[l] = ps_fifos_ifs[l].out_vals;
        end
    endgenerate
    // PE Generation
    generate
        for (m = 0; m < N; m++) begin
            for (n = 0; n < N; n++) begin
                sysarr_PE PE_inst (
                    .clk(clk),
                    .nRST(nRST),
                    .pe(pe_ifs[m*N + n].PE)
                );
                // if (m==0 && n==0) begin : PE_ready
                assign any_ready[m*N + n] = pe_ifs[m*N + n].value_ready;
                // end
                assign pe_ifs[m*N + n].start = control_unit_if.PE_start[m*N + n];
                assign pe_ifs[m*N + n].weight = use_weights[n][(N - m) * DW - 1 -: DW];
                assign pe_ifs[m*N + n].weight_col = use_weight_cols[n][(N - m) * IND - 1 -: IND];
                if (n != 0)begin : PEInputForwarding
                    assign pe_ifs[m*N + n].in_value = pe_ifs[m*N + (n-1)].val_pass;
                    assign pe_ifs[m*N + n].in_ind = pe_ifs[m*N + (n-1)].ind_pass;
                    assign pe_ifs[m*N + n].in_end = pe_ifs[m*N + (n-1)].end_pass;
                end else begin : PEinputfromfifo
                    assign pe_ifs[m*N + n].in_value = input_fifos_ifs[m].out_vals;
                    assign pe_ifs[m*N + n].in_ind = input_fifos_ifs[m].out_inds;
                    assign pe_ifs[m*N + n].in_end = input_fifos_ifs[m].out_ends;
                end
                assign pe_ifs[m*N + n].shift = control_unit_if.PE_shift[m*N + n];
                if (m == 0) begin : no_accumulate
                    assign pe_ifs[m*N + n].in_accumulate = '0;
                end else begin : accumulation_blk
                    assign pe_ifs[m*N + n].in_accumulate = pe_ifs[(m-1)*N + n].out_accumulate;
                end
                if (m == N-1) begin : acc_enables
                    assign acc_ens[n] = pe_ifs[m*N + n].acc_en;
                end
            end
        end
    endgenerate
    assign control_unit_if.PE_value_ready = |any_ready;
    // Partial Sum Output Adders Generation
    generate
        for (o = 0; o < N; o++) begin
            sysarr_add add_inst (
                .clk(clk),
                .nRST(nRST),
                .adder(add_ifs[o].add)
            );
            assign control_unit_if.add_value_ready[o] = add_ifs[o].value_ready;
            assign add_ifs[o].start = control_unit_if.add_start[o];
            assign add_ifs[o].add_input1 = ps_add_inputs[o];
            assign add_ifs[o].add_input2 = pe_ifs[(N-1)*N + o].out_accumulate;
            assign add_rdy[o] = add_ifs[o].value_ready;
        end
    endgenerate
    // Output FIFOs
    generate
        for (p = 0; p < N; p++) begin
            sysarr_FIFO out_fifos (
                .clk(clk),
                .nRST(nRST),
                .fifo(out_fifos_ifs[p].FIFO));
            assign out_fifos_ifs[p].load = add_rdy[p];
            assign out_fifos_ifs[p].shift = out_fifo_shift;
            assign out_fifos_ifs[p].load_vals = add_ifs[p].add_output; //load vector across each
            assign outputs[p]= out_fifos_ifs[p].out_vals;
        end
    endgenerate

    always_ff @(posedge clk, negedge nRST) begin
        if(nRST == 1'b0)begin
            out_rdy <= '0;
        end else begin
            out_rdy <= nxt_out_rdy;
        end 
    end
    assign nxt_out_rdy = add_rdy[N-1];
    // output time :D
    // always_comb begin
    //     nxt_out_rdy = out_rdy | add_rdy;
    //     if (out_rdy == '1)begin
    //         nxt_out_rdy = '0;
    //     end
    // end 
    assign memory.array_output = flat_output;
    always_comb begin
        flat_output = '0;
        memory.out_en = '0;
        out_fifo_shift = '0;
        if (out_rdy == 1'b1)begin
            for (q=0;q<N;q++)begin
                flat_output[(q+1)*DW - 1 -: DW] = outputs[N-1-q];
            end
            memory.out_en = 1'b1;
            out_fifo_shift = 1'b1;
        end
    end

endmodule
