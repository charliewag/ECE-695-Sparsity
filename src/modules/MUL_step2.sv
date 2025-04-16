//By            : Joe Nasti
//Last Updated  : 11/03/2024 by Vinay Pundith - updated to reduce to FP16 from FP32 for TPU Systolic Array MAC Unit
//
//Module Summary:
//    Second step of multiplication in three-step pipeline
//    Adds exponents together and xor's sign bits
//
//Inputs:
//    sign1/2 - signs to be xor'ed
//    exp1/2  - exponents to be added together
//Outputs:
//    sign_out - result of xor operation
//    sum_exp  - result of addition
//    ovf      - signal if an overflow has occurred
//    unf      - signal if an undeflow has occurred

/* verilator lint_off UNUSEDSIGNAL */

`timescale 1ns/1ps

module MUL_step2 (
    input            sign1,
    input            sign2,
    input      [4:0] exp1,
    input      [4:0] exp2,
    output           sign_out,
    output     [4:0] sum_exp,
    output reg       ovf,
    output reg       unf,
    input            carry
);


    adder_5b add_EXPs (
        .carry(carry),
        .exp1 (exp1),
        .exp2 (exp2),
        .sum  (sum_exp),
        .ovf  (ovf),
        .unf  (unf)
    );

    assign sign_out = sign1 ^ sign2;

endmodule
