`timescale 1ns / 1ps

`include "parameters.v"

`define PARSE 3

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

module GivensRotation_divide
    #(parameter N = 8) (
        input clk, clk_pl, rst,
        input signed [(`WL*N*N)-1:0] Hmatrix_i,
        input signed [(`WL*N)-1:0] Yarray_i,
        output signed [(`WL*N*N)-1:0] Hmatrix_o,
        output signed [(`WL*N)-1:0] Yarray_o 
    );
    
    wire signed [(`WL*N)-1:0] harray[N-1:1];
    wire signed [`WL-1:0] yarray[N-1:1];
    wire signed [(`WL*N)-1:0] harray_out[3:1];
    wire signed [`WL-1:0] yarray_out[3:1];
    reg signed [(`WL*N)-1:0] harray_BUF[N-1:1];
    reg signed [`WL-1:0] yarray_BUF[N-1:1];
    
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
    
    // First three row ----------------------------------------------
    RowRotation #(.N(N)) uRR0(
        .clk(clk),
        .Hin_x(harray_0_in[0]), .Hin_y(harray[1]),
        .Yin_x(yarray_0_in[0]), .Yin_y(yarray[1]),
        .Hout_x(harray_0_out[1]), .Hout_y(harray_out[1]),
        .Yout_x(yarray_0_out[1]), .Yout_y(yarray_out[1]));
    always@ (posedge clk) begin
        harray_0_in[1] <= harray_0_out[1];
        yarray_0_in[1] <= yarray_0_out[1];
    end
    RowRotation #(.N(N)) uRR1(
        .clk(clk),
        .Hin_x(harray_0_in[1]), .Hin_y(harray[2]),
        .Yin_x(yarray_0_in[1]), .Yin_y(yarray[2]),
        .Hout_x(harray_0_out[2]), .Hout_y(harray_out[2]),
        .Yout_x(yarray_0_out[2]), .Yout_y(yarray_out[2]));
    always@ (posedge clk) begin
        harray_0_in[2] <= harray_0_out[2];
        yarray_0_in[2] <= yarray_0_out[2];
    end
    RowRotation #(.N(N)) uRR2(
        .clk(clk),
        .Hin_x(harray_0_in[2]), .Hin_y(harray[3]),
        .Yin_x(yarray_0_in[2]), .Yin_y(yarray[3]),
        .Hout_x(harray_0_out[3]), .Hout_y(harray_out[3]),
        .Yout_x(yarray_0_out[3]), .Yout_y(yarray_out[3]));
    
    // PIPELINE divider ---------------------------------------------
    always@(posedge clk_pl or negedge rst) begin
        if (~rst) begin
            harray_0_in[3] <= 0;
            yarray_0_in[3] <= 0;
        end else begin
            harray_0_in[3] <= harray_0_out[3];
            yarray_0_in[3] <= yarray_0_out[3];
        end
    end
    
    generate
        for (i = 1; i <= 3; i = i + 1) begin
            always@(posedge clk_pl or negedge rst) begin
                if (~rst) begin
                    harray_BUF[i] <= 0;
                    yarray_BUF[i] <= 0;
                end else begin
                    harray_BUF[i] <= harray_out[i];
                    yarray_BUF[i] <= yarray_out[i];
                end
            end
            assign harray_o[i] = harray_BUF[i];
            assign yarray_o[i] = yarray_BUF[i];
        end
        for (i = 4; i < N; i = i + 1) begin  
            always@(posedge clk_pl or negedge rst) begin
                if (~rst) begin
                    harray_BUF[i] <= 0;
                    yarray_BUF[i] <= 0;
                end else begin
                    harray_BUF[i] <= harray[i];
                    yarray_BUF[i] <= yarray[i];
                end
            end
        end
    endgenerate
    
    // ----------------------------------------------------------
    generate    // Row rotation
        for (i = 3; i < N-1; i = i + 1) begin
            RowRotation #(.N(N)) uRR(
                .clk(clk),
                .Hin_x(harray_0_in[i]), .Hin_y(harray_BUF[i+1]),
                .Yin_x(yarray_0_in[i]), .Yin_y(yarray_BUF[i+1]),
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