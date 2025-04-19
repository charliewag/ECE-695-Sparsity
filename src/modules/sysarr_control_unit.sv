`include "systolic_array_control_unit_if.vh"
`include "sys_arr_pkg.vh"
/* verilator lint_off IMPORTSTAR */
import sys_arr_pkg::*;
/* verilator lint_off IMPORTSTAR */

module sysarr_control_unit(
    input logic clk, 
    input logic nRST,
    systolic_array_control_unit_if.control_unit cu
);
    logic PE_start;
    logic PE_shift;
    logic nxt_PE_start;
    logic nxt_PE_shift;
    logic first_start;
    logic nxt_first_start;
    logic input_loading; 
    logic nxt_input_loading;
    logic [$clog2(N)-1:0] input_count;
    logic [$clog2(N)-1:0] nxt_input_count;
    logic [N-1:0] output_done;
    logic [N-1:0] nxt_output_done;
    logic [N-1:0] in_f_shift;
    logic [N-1:0] nxt_in_f_shift;
    logic [N-1:0] ps_f_shift;
    logic [N-1:0] nxt_ps_f_shift;
    logic [N*N-1:0] PE_enables;
    logic [N*N-1:0] nxt_PE_enables;
    logic [N-1:0] add_starts;
    logic [N-1:0] nxt_add_starts;

    always_ff @(posedge clk, negedge nRST) begin
        if(nRST == 1'b0)begin
            input_loading <= '0;
            input_count <= '0;
            first_start <= '0;
            output_done <= '0;
        end else begin
            input_loading <= nxt_input_loading;
            input_count <= nxt_input_count;
            first_start <= nxt_first_start;
            output_done <= nxt_output_done;
        end 
    end
    assign nxt_first_start = nxt_input_loading && ~input_loading;
    always_comb begin  
        nxt_input_loading = input_loading;
        nxt_input_count = input_count;
        nxt_output_done = output_done;
        nxt_output_done = output_done | cu.acc_end_flags;
        // if we change the weights reset all input streams
        // if (cu.weight_en)begin
        //     nxt_input_loading = '0;
        //     nxt_input_count = '0;
        // end
        // if there is an input say we are loading and add to the running input count
        if (cu.input_en)begin
            nxt_input_loading = 1'b1;
            nxt_input_count = input_count + 1;
        end
        if (cu.in_fifo_shift[0])begin
            nxt_input_count = input_count - 1;
        end
        if (input_loading && input_count == '0)begin
            nxt_input_loading = 1'b0;
        end
        if (first_start)begin
            nxt_output_done = '0;
        end
    end
    assign cu.fifo_has_space = PE_enables[0] == 1'b0;
    // fifo shifts and enables
    always_ff @(posedge clk, negedge nRST) begin
        if(nRST == 1'b0)begin
            in_f_shift <= '0;
            ps_f_shift <= '0;
        end else begin
            in_f_shift <= nxt_in_f_shift;
            ps_f_shift <= nxt_ps_f_shift;
        end 
    end
    //shifts it over by one everytime
    always_comb begin
        nxt_in_f_shift = in_f_shift;
        nxt_ps_f_shift = ps_f_shift;
        if (PE_shift) begin
            nxt_in_f_shift = in_f_shift << 1 | {{(N-1){1'b0}},input_count!='0}; // shifts in a 1 if we are still loading
        end
        if (|add_starts == 1'b1)begin
            nxt_ps_f_shift = add_starts;
        end
    end
    always_comb begin
        cu.in_fifo_shift = '0;
        cu.ps_fifo_shift = '0;
        if(PE_start) begin // shift new set in
            cu.in_fifo_shift = in_f_shift;
        end
        cu.ps_fifo_shift = cu.add_value_ready;
    end
    // PE 
    always_ff @(posedge clk, negedge nRST) begin
        if(nRST == 1'b0)begin
            PE_start <= '0;
            PE_shift <= '0;
            PE_enables <= '0;
        end else begin
            PE_start <= nxt_PE_start;
            PE_shift <= nxt_PE_shift;
            PE_enables <= nxt_PE_enables;
        end 
    end
    always_comb begin
        nxt_PE_start = PE_start;
        nxt_PE_shift = PE_shift;
        if ((first_start && ~(|PE_enables)) || (cu.PE_value_ready && (|PE_enables || first_start)))begin
            nxt_PE_shift = 1'b1;
        end
        // shift then start
        if(PE_shift == 1'b1)begin
            nxt_PE_start = 1'b1;
        end
        // only want them high for a cycle
        if (PE_shift == 1'b1)begin
            nxt_PE_shift = '0;
        end
        if (PE_start == 1'b1)begin
            nxt_PE_start = '0;
        end
    end
    int w;
    always_comb begin
        nxt_PE_enables = PE_enables;
        if (first_start)begin //starting
            nxt_PE_enables[0] = 1'b1;
        end
        if (cu.PE_value_ready)begin
            nxt_PE_enables = PE_enables<<1 | PE_enables<<N | {{(N*N-1){1'b0}},input_count!='0};
            for (w=1;w<N;w++)begin
                if (PE_enables[N*w-1] == 1'b1 && PE_enables[N*w-N] == 1'b0) begin
                    nxt_PE_enables[N*w] = 1'b0;
                end
            end
        end
    end
    assign cu.drained = ~(|PE_enables);
    always_comb cu.PE_start = PE_start ? PE_enables : '0;
    always_comb cu.PE_shift = PE_shift ? PE_enables : '0;
    // adder
    always_ff @(posedge clk, negedge nRST) begin
        if(nRST == 1'b0)begin
            add_starts <= '0;
        end else begin
            add_starts <= nxt_add_starts;
        end 
    end
    assign cu.add_start = add_starts;
    int a,b;
    always_comb begin
        nxt_add_starts = add_starts;
        for (a=0;a<N;a++)begin
            if (cu.acc_end_flags[a])begin
                nxt_add_starts[a] = 1'b1;
            end
        end
        for (b=0;b<N;b++)begin
            if (add_starts[b])begin
                nxt_add_starts[b] = 1'b0;
            end
        end
    end


endmodule
