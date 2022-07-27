`timescale 1ns / 1ps

`include "parameters.v"

module ColumnPermutation
    #(parameter N = 2) (    // # of column
//        input clk,
        input [(64*`WL)-1:0] Hmatrix_i,
        input [(8*`COLNORM_WL) - 1:0] colnorm_i,
        input [3*8 - 1:0] colorder_i,
        output [(64*`WL)-1:0] Hmatrix_o,
        output [(8*`COLNORM_WL) - 1:0] colnorm_o,
        output [3*8 - 1:0] colorder_o
    );
    
    wire [2:0] mincol;
//    wire [(64*`WL)-1:0] Hmatrix_FF;
//    wire [(N*`COLNORM_WL) - 1:0] colnorm_FF;
//    wire [3*N - 1:0] colorder_FF;
    
    MinNormComp #(.N(N)) uMinNorm(
        .colnorm_i(colnorm_i[`COLNORM_WL*8-1:`COLNORM_WL*(8-N)]),
        .mincol(mincol)
    );
    
    genvar i;
    generate
        for (i = 0; i < 8-N; i = i+1) begin
            assign colnorm_o[`COLNORM_WL*i + `COLNORM_WL-1:`COLNORM_WL*i] = colnorm_i[`COLNORM_WL*i + `COLNORM_WL-1:`COLNORM_WL*i];
            assign colorder_o[3*i+2:3*i] = colorder_i[3*i+2:3*i];
        end
    endgenerate
    
    ColExchange #(.TARCOL(8-N)) uColXchg(
        .mincol(mincol),
        .Hmatrix_i(Hmatrix_i),
        .colnorm_i(colnorm_i[`COLNORM_WL*8-1:`COLNORM_WL*(8-N)]), 
        .colorder_i(colorder_i[3*8-1:3*(8-N)]),
        .Hmatrix_o(Hmatrix_o),
        .colnorm_o(colnorm_o[`COLNORM_WL*8-1:`COLNORM_WL*(8-N)]),
        .colorder_o(colorder_o[3*8-1:3*(8-N)])
    );
    
//    always@(posedge clk) begin
//        Hmatrix_o <= Hmatrix_FF;
//        colnorm_o <= colnorm_FF;
//        colorder_o <= colorder_FF;
//    end
    
endmodule
