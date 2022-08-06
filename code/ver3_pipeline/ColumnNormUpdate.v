`timescale 1ns / 1ps

`include "parameters.v"

module ColumnNormUpdate
    #(parameter N = 2) (
        input [(N*`WL)-1:0] Harray_i,           // h_j,j+1, h_j,j+2, ..., h_j,7               
        input [(8*`COLNORM_WL) - 1:0] colnorm_i,
        output [(8*`COLNORM_WL) - 1:0] colnorm_o
    );
    
    wire signed [`WL-1:0] h_i_wl[0:N-1];    
    wire signed [`COLNORM_WL-1:0] h_i[0:N-1];
    wire signed [`COLNORM_WL-1:0] norm_i[0:7];
    wire signed [2*`COLNORM_WL-1:0] h_i_sq_2l[0:N-1];
    wire signed [`COLNORM_WL-1:0] h_i_sq[0:N-1];
    wire signed [`COLNORM_WL-1:0] norm_o[0:7];
    
    genvar i, j;
    
    generate    // separate matrix H into column vectors
        for (i = 0; i < 8; i = i+1) begin
            assign norm_i[i] = colnorm_i[`COLNORM_WL*i + `COLNORM_WL-1: `COLNORM_WL*i];
        end
        for (i = 0; i < N; i = i+1) begin
            assign h_i_wl[i] = Harray_i[i*`WL + `WL-1:i*`WL];
            assign h_i[i] = h_i_wl[i] >>> (`FWL - `COLNORM_FWL);
        end
    endgenerate
    
    generate    // assign the frozen column norm
        for (j = 0; j < 8-N; j = j+1) begin
            assign norm_o[j] = norm_i[j];
        end
    endgenerate
    
    generate    // update column norm
        for (j = 0; j < N; j = j+1) begin
            assign h_i_sq_2l[j] = h_i[j] * h_i[j];
            assign h_i_sq[j] = h_i_sq_2l[j] >>> `COLNORM_FWL;
            assign norm_o[j+8-N] = norm_i[j+8-N] - h_i_sq[j];
        end
    endgenerate
    
    generate    // packing column norm
        for (i = 0; i < 8; i = i+1) begin
            assign colnorm_o[`COLNORM_WL*i + `COLNORM_WL-1: `COLNORM_WL*i] = norm_o[i];
        end
    endgenerate
    
endmodule
