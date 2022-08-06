`timescale 1ns / 1ps

`include "parameters.v"

module Decomposition(
        input clk, rst,
        input [(64*`WL)-1:0]    Hmatrix_i,
        input [(8*`WL)-1:0]     Yarray_i,
        output reg [(64*`WL)-1:0]   Rmat,
        output reg [(8*`WL)-1:0]    Yarr,
        output reg [8 * 3 - 1 : 0]  colorder
    );
    
    reg  [(8*8*`WL)-1:0]            Hmatrix_in[0:6];
    reg  [(8*`WL)-1:0]              Yarray_in[0:6];
    reg  [(8*`COLNORM_WL) - 1:0]    colnorm_in[1:6];
    reg  [8*3 - 1:0]                colorder_in[1:6];
    wire [(8*8*`WL)-1:0]            Hmatrix_out[0:6];
    wire [(8*`WL)-1:0]              Yarray_out[0:6];
    wire [(8*`COLNORM_WL) - 1:0]    colnorm_out[0:6];
    wire [8*3 - 1:0]                colorder_out[0:6];
    
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            Hmatrix_in[0]   <= 0;
            Yarray_in[0]    <= 0;
        end else begin
            Hmatrix_in[0]   <= Hmatrix_i;
            Yarray_in[0]    <= Yarray_i;
        end
    end
    
    DecomposeStage_first u_S0(
        .clk(clk), .rst(rst),
        .Hmatrix_i(Hmatrix_in[0]),  .Yarray_i(Yarray_in[0]),
        .Hmatrix_o(Hmatrix_out[0]), .Yarray_o(Yarray_out[0]),
        .colnorm_o(colnorm_out[0]),
        .colorder_o(colorder_out[0])
    );
    
    genvar s;
    generate 
        for (s = 1; s < 7; s = s + 1) begin
            always@(posedge clk or negedge rst) begin
                if (~rst) begin
                    Hmatrix_in[s] <= 0;
                    Yarray_in[s] <= 0;
                    colnorm_in[s] <= 0;
                    colorder_in[s] <= 0;
                end else begin
                    Hmatrix_in[s] <= Hmatrix_out[s - 1];
                    Yarray_in[s] <= Yarray_out[s - 1];
                    colnorm_in[s] <= colnorm_out[s - 1];
                    colorder_in[s] <= colorder_out[s - 1];
                end
            end
            DecomposeStage #(.N(8-s)) u_Ss(
                .clk(clk), .rst(rst),
                .Hmatrix_i(Hmatrix_in[s]),  .Yarray_i(Yarray_in[s]),
                .colnorm_i(colnorm_in[s]), .colorder_i(colorder_in[s]),
                .Hmatrix_o(Hmatrix_out[s]), .Yarray_o(Yarray_out[s]),
                .colnorm_o(colnorm_out[s]), .colorder_o(colorder_out[s])
            );        
        end 
    endgenerate
    
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            Rmat <= 0;
            Yarr <= 0;
            colorder <= 0;
        end else begin
            Rmat <= Hmatrix_out[6];
            Yarr <= Yarray_out[6];
            colorder <= colorder_out[6];
        end
    end
    
endmodule
