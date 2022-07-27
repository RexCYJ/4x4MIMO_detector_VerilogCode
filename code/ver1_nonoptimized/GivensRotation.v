`timescale 1ns / 1ps

`include "parameters.v"

module GivensRotation
    #(parameter N = 8) (
        input clk,
        input signed [(`WL*N*N)-1:0] Hmatrix_i,
        input signed [(`WL*N)-1:0] Yarray_i,
        output signed [(`WL*N*N)-1:0] Hmatrix_o,
        output signed [(`WL*N)-1:0] Yarray_o 
    );
    
    wire signed [(`WL*N)-1:0] harray[N-1:1];
    wire signed [`WL-1:0] yarray[N-1:1];
    
    reg signed [(`WL*N)-1:0] harray_0_in[N-2:0];
    reg signed [`WL-1:0] yarray_0_in[N-2:0];
    wire signed [(`WL*N)-1:0] harray_0_out[N-1:1];
    wire signed [`WL-1:0] yarray_0_out[N-1:1];
    
    wire signed [(`WL*N)-1:0] harray_o[N-1:1];
    wire signed [`WL-1:0] yarray_o[N-1:1];
    
    genvar i, j;
    generate    // unpacking H matrix and Y array
        for (i = 1; i < N; i = i + 1) begin
            assign harray[i] = Hmatrix_i[(i+1)*`WL*N - 1:i*`WL*N];
            assign yarray[i] = Yarray_i[(i+1)*`WL - 1:i*`WL]; 
        end
    endgenerate
    
    always@* begin 
        harray_0_in[0] = Hmatrix_i[`WL*N - 1:0];
        yarray_0_in[0] = Yarray_i[`WL-1:0];
    end
    
    generate    // Row rotation
        for (i = 0; i < N-1; i = i + 1) begin
            RowRotation #(.N(N)) uRR(
                .clk(clk),
                .Hin_x(harray_0_in[i]), .Hin_y(harray[i+1]),
                .Yin_x(yarray_0_in[i]), .Yin_y(yarray[i+1]),
                .Hout_x(harray_0_out[i+1]), .Hout_y(harray_o[i+1]),
                .Yout_x(yarray_0_out[i+1]), .Yout_y(yarray_o[i+1])
            );
            if (i != N-2) begin
                always@ (posedge clk) begin
                    harray_0_in[i+1] <= harray_0_out[i+1];
                    yarray_0_in[i+1] <= yarray_0_out[i+1];
                end
            end 
        end
    endgenerate
    
    generate    // packing H matrix and Y array
        for (i = 1; i < N; i = i + 1) begin
            assign Hmatrix_o[(i+1)*`WL*N - 1:i*`WL*N] = harray_o[i];
            assign Yarray_o[(i+1)*`WL - 1:i*`WL] = yarray_o[i];
        end
    endgenerate
    
    assign Hmatrix_o[`WL*N - 1:0] = harray_0_out[N-1];
    assign Yarray_o[`WL-1:0] = yarray_0_out[N-1];
    
endmodule
