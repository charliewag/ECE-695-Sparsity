//By            : Joe Nasti
//Last Updated  : 11/03/2024 by Vinay Pundith - converted to 13b multiplier for TPU Systolic Array
//
//Module Summary:
//    multiplies two 13 bit fraction values with decimal point after the first bit
//
//Inputs:
//    frac_in1/2 - 13 bit fractions with decimal point after first bit
//Outputs:
//    frac_out   - 13 bit result of operation regardless of overflow occuring
//    overflow   - flags if an overflow has occured

/* verilator lint_off UNUSEDSIGNAL */

`timescale 1ns/1ps

module mul_13b (
    input  [12:0] frac_in1,
    input  [12:0] frac_in2,
    output [12:0] frac_out,
    output        overflow,
    output        round_loss
);

    reg [25:0] frac_out_26b;

    assign overflow = frac_out_26b[25];
    assign frac_out = frac_out_26b[24:12];
    assign round_loss = | frac_out_26b[11:0];

    always_comb begin : MULTIPLY
        frac_out_26b = frac_in1 * frac_in2;

    end
endmodule
