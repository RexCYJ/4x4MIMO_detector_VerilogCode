`timescale 1ns / 1ps

`include "parameters.v"

//`define PARSE 3

//module GivensRotation
//    #(parameter N = 8) (
//        input clk, rst,
//        input signed [(`WL*N*N)-1:0] Hmatrix_i,
//        input signed [(`WL*N)-1:0] Yarray_i,
//        output signed [(`WL*N*N)-1:0] Hmatrix_o,
//        output signed [(`WL*N)-1:0] Yarray_o 
//    );
   
//    wire signed [(`WL*N)-1:0]   harray_o[1:N-1];     // [level][row] 
//    wire signed [`WL-1:0]       yarray_o[1:N-1];
    
//    reg signed [(`WL*N)-1:0]    harray_BUF[0:N-2][N-1:1];   // [level][row]
//    reg signed [`WL-1:0]        yarray_BUF[0:N-2][N-1:1];
//    reg signed [(`WL*N)-1:0]    harray_interBUF[1:N-1][1:2][N-2:1];
//    reg signed [`WL-1:0]        yarray_interBUF[1:N-1][1:2][N-2:1];
            
//    reg signed [(`WL*N)-1:0]    harray_0_BUF[0:N-2];
//    reg signed [`WL-1:0]        yarray_0_BUF[0:N-2];
//    wire signed [(`WL*N)-1:0]   harray_0_out[1:N-1];
//    wire signed [`WL-1:0]       yarray_0_out[1:N-1];
    
//    genvar i, j, k;
//    generate    // unpacking H matrix and Y array
//        for (i = 1; i < N; i = i + 1) begin
//            always@* begin
//                harray_BUF[0][i] = Hmatrix_i[(i+1)*`WL*N - 1:i*`WL*N];
//                yarray_BUF[0][i] = Yarray_i[(i+1)*`WL - 1:i*`WL];
//            end 
//        end
//    endgenerate
    
//    always@* begin 
//        harray_0_BUF[0] = Hmatrix_i[`WL*N - 1:0];
//        yarray_0_BUF[0] = Yarray_i[`WL-1:0];
//    end
    
//    // Row Rotation --------------------------------------------------------
//    generate    
//        for (i = 1; i < N-1; i = i + 1) begin
//            RowRotation #(.N(N)) u_RR(
//                .clk(clk), .rst(rst),
//                .Hin_x(harray_0_BUF[i-1]), .Hin_y(harray_BUF[i-1][i]),
//                .Yin_x(yarray_0_BUF[i-1]), .Yin_y(yarray_BUF[i-1][i]),
//                .Hout_x(harray_0_out[i]), .Hout_y(harray_o[i]),
//                .Yout_x(yarray_0_out[i]), .Yout_y(yarray_o[i])
//            );
            
//            // Store the unused rows
//            for (j = 1; j < N; j = j + 1) begin
//                if (j < i) begin
//                    // First Inter buffer
//                    always@ (posedge clk or negedge rst) begin
//                        if (~rst) begin
//                            harray_interBUF[i][1][j] <= 0; 
//                            yarray_interBUF[i][1][j] <= 0; 
//                        end else begin
//                            harray_interBUF[i][1][j] <= harray_BUF[i-1][j];
//                            yarray_interBUF[i][1][j] <= yarray_BUF[i-1][j];
//                        end
//                    end
//                    // Second Inter buffer
//                    always@ (posedge clk or negedge rst) begin
//                        if (~rst) begin
//                            harray_interBUF[i][2][j] <= 0; 
//                            yarray_interBUF[i][2][j] <= 0; 
//                        end else begin         
//                            harray_interBUF[i][2][j] <= harray_interBUF[i][1][j];
//                            yarray_interBUF[i][2][j] <= yarray_interBUF[i][1][j];
//                        end
//                    end
//                    // FF for current column
//                    always@ (posedge clk or negedge rst) begin
//                        if (~rst) begin
//                            harray_BUF[i][j] <= 0;
//                            yarray_BUF[i][j] <= 0;
//                        end else begin
//                            harray_BUF[i][j] <= harray_interBUF[i][2][j];
//                            yarray_BUF[i][j] <= yarray_interBUF[i][2][j];
//                        end
//                    end
//                end else if (j > i) begin
//                    always@ (posedge clk or negedge rst) begin
//                        if (~rst) begin
//                            harray_interBUF[i][1][j-1] <= 0; 
//                            yarray_interBUF[i][1][j-1] <= 0; 
//                        end else begin
//                            harray_interBUF[i][1][j-1] <= harray_BUF[i-1][j];
//                            yarray_interBUF[i][1][j-1] <= yarray_BUF[i-1][j];
//                        end
//                    end
//                    // Second Inter buffer
//                    always@ (posedge clk or negedge rst) begin
//                        if (~rst) begin
//                            harray_interBUF[i][2][j-1] <= 0; 
//                            yarray_interBUF[i][2][j-1] <= 0; 
//                        end else begin         
//                            harray_interBUF[i][2][j-1] <= harray_interBUF[i][1][j-1];
//                            yarray_interBUF[i][2][j-1] <= yarray_interBUF[i][1][j-1];
//                        end
//                    end
//                    // FF for current column
//                    always@ (posedge clk or negedge rst) begin
//                        if (~rst) begin
//                            harray_BUF[i][j] <= 0;
//                            yarray_BUF[i][j] <= 0;
//                        end else begin
//                            harray_BUF[i][j] <= harray_interBUF[i][2][j-1];
//                            yarray_BUF[i][j] <= yarray_interBUF[i][2][j-1];
//                        end
//                    end
//                end
//            end
//            // FF for current column
//            always@ (posedge clk or negedge rst) begin
//                if (~rst) begin
//                    harray_0_BUF[i] <= 0;
//                    yarray_0_BUF[i] <= 0;
//                    harray_BUF[i][i] <= 0; 
//                    yarray_BUF[i][i] <= 0; 
//                end else begin
//                    harray_0_BUF[i] <= harray_0_out[i];
//                    yarray_0_BUF[i] <= yarray_0_out[i];
//                    harray_BUF[i][i] <= harray_o[i];
//                    yarray_BUF[i][i] <= yarray_o[i];
//                end
//            end
//        end
//    endgenerate
    
//    // The last one row -------------------------------------------------------
//    RowRotation #(.N(N)) u_RRlast(
//        .clk(clk), .rst(rst),
//        .Hin_x(harray_0_BUF[N-2]), .Hin_y(harray_BUF[N-2][N-1]),
//        .Yin_x(yarray_0_BUF[N-2]), .Yin_y(yarray_BUF[N-2][N-1]),
//        .Hout_x(harray_0_out[N-1]), .Hout_y(harray_o[N-1]),
//        .Yout_x(yarray_0_out[N-1]), .Yout_y(yarray_o[N-1])
//    );
    
//    generate
//        for (j = 1; j < N - 1; j = j + 1) begin
//            // First Inter buffer
//            always@ (posedge clk or negedge rst) begin
//                if (~rst) begin
//                    harray_interBUF[N-1][1][j] <= 0; 
//                    yarray_interBUF[N-1][1][j] <= 0; 
//                end else begin
//                    harray_interBUF[N-1][1][j] <= harray_BUF[N-2][j];
//                    yarray_interBUF[N-1][1][j] <= yarray_BUF[N-2][j];
//                end
//            end
//            // Second Inter buffer
//            always@ (posedge clk or negedge rst) begin
//                if (~rst) begin
//                    harray_interBUF[N-1][2][j] <= 0; 
//                    yarray_interBUF[N-1][2][j] <= 0; 
//                end else begin         
//                    harray_interBUF[N-1][2][j] <= harray_interBUF[N-1][1][j];
//                    yarray_interBUF[N-1][2][j] <= yarray_interBUF[N-1][1][j];
//                end
//            end
//            assign Hmatrix_o[j*N*`WL + N*`WL-1:j*N*`WL] = harray_interBUF[N-1][2][j];
//            assign Yarray_o[j*`WL + `WL-1:j*`WL]        = yarray_interBUF[N-1][2][j];
//        end
//    endgenerate
    
//    assign Hmatrix_o[(N-1)*N*`WL + N*`WL-1: (N-1)*N*`WL]    = harray_o[N-1];
//    assign Yarray_o[(N-1)*`WL + `WL-1: (N-1)*`WL]           = yarray_o[N-1];
//    assign Hmatrix_o[`WL*N - 1:0]                       = harray_0_out[N-1];
//    assign Yarray_o[`WL-1:0]                            = yarray_0_out[N-1];
    
//endmodule

module GivensRotation
    #(parameter N = 8) (
        input clk, rst,
        input signed [(`WL*N*N)-1:0] Hmatrix_i,
        input signed [(`WL*N)-1:0] Yarray_i,
        output signed [(`WL*N*N)-1:0] Hmatrix_o,
        output signed [(`WL*N)-1:0] Yarray_o 
    );
   
    wire signed [(`WL*N)-1:0]   harray_o[1:N-1];     // [level][row] 
    wire signed [`WL-1:0]       yarray_o[1:N-1];
    
    reg signed [(`WL*N)-1:0]    harray_BUF[0:N-2][N-1:1];   // [level][row]
    reg signed [`WL-1:0]        yarray_BUF[0:N-2][N-1:1];
    reg signed [(`WL*N)-1:0]    harray_interBUF[1:N-1][N-2:1];
    reg signed [`WL-1:0]        yarray_interBUF[1:N-1][N-2:1];
            
    reg signed [(`WL*N)-1:0]    harray_0_BUF[0:N-2];
    reg signed [`WL-1:0]        yarray_0_BUF[0:N-2];
    wire signed [(`WL*N)-1:0]   harray_0_out[1:N-1];
    wire signed [`WL-1:0]       yarray_0_out[1:N-1];
    
    genvar i, j, k;
    generate    // unpacking H matrix and Y array
        for (i = 1; i < N; i = i + 1) begin
            always@* begin
                harray_BUF[0][i] = Hmatrix_i[(i+1)*`WL*N - 1:i*`WL*N];
                yarray_BUF[0][i] = Yarray_i[(i+1)*`WL - 1:i*`WL];
            end 
        end
    endgenerate
    
    always@* begin 
        harray_0_BUF[0] = Hmatrix_i[`WL*N - 1:0];
        yarray_0_BUF[0] = Yarray_i[`WL-1:0];
    end
    
    // Row Rotation --------------------------------------------------------
    generate    
        for (i = 1; i < N - 1; i = i + 1) begin
            RowRotation #(.N(N)) u_RR(
                .clk(clk), .rst(rst),
                .Hin_x(harray_0_BUF[i-1]), .Hin_y(harray_BUF[i-1][i]),
                .Yin_x(yarray_0_BUF[i-1]), .Yin_y(yarray_BUF[i-1][i]),
                .Hout_x(harray_0_out[i]), .Hout_y(harray_o[i]),
                .Yout_x(yarray_0_out[i]), .Yout_y(yarray_o[i])
            );
            
            // Store the unused rows
            for (j = 1; j < N; j = j + 1) begin
                if (j < i) begin
                    // First Inter buffer
                    always@ (posedge clk or negedge rst) begin
                        if (~rst) begin
                            harray_interBUF[i][j] <= 0; 
                            yarray_interBUF[i][j] <= 0; 
                        end else begin
                            harray_interBUF[i][j] <= harray_BUF[i-1][j];
                            yarray_interBUF[i][j] <= yarray_BUF[i-1][j];
                        end
                    end
                    
                    // FF for current column
                    always@ (posedge clk or negedge rst) begin
                        if (~rst) begin
                            harray_BUF[i][j] <= 0;
                            yarray_BUF[i][j] <= 0;
                        end else begin
                            harray_BUF[i][j] <= harray_interBUF[i][j];
                            yarray_BUF[i][j] <= yarray_interBUF[i][j];
                        end
                    end
                end else if (j > i) begin
                    always@ (posedge clk or negedge rst) begin
                        if (~rst) begin
                            harray_interBUF[i][j-1] <= 0; 
                            yarray_interBUF[i][j-1] <= 0; 
                        end else begin
                            harray_interBUF[i][j-1] <= harray_BUF[i-1][j];
                            yarray_interBUF[i][j-1] <= yarray_BUF[i-1][j];
                        end
                    end
                    
                    // FF for current column
                    always@ (posedge clk or negedge rst) begin
                        if (~rst) begin
                            harray_BUF[i][j] <= 0;
                            yarray_BUF[i][j] <= 0;
                        end else begin
                            harray_BUF[i][j] <= harray_interBUF[i][j-1];
                            yarray_BUF[i][j] <= yarray_interBUF[i][j-1];
                        end
                    end
                end
            end
            // FF for current column
            always@ (posedge clk or negedge rst) begin
                if (~rst) begin
                    harray_0_BUF[i] <= 0;
                    yarray_0_BUF[i] <= 0;
                    harray_BUF[i][i] <= 0; 
                    yarray_BUF[i][i] <= 0; 
                end else begin
                    harray_0_BUF[i] <= harray_0_out[i];
                    yarray_0_BUF[i] <= yarray_0_out[i];
                    harray_BUF[i][i] <= harray_o[i];
                    yarray_BUF[i][i] <= yarray_o[i];
                end
            end
        end
    endgenerate
    
    // The last one row -------------------------------------------------------
    RowRotation #(.N(N)) u_RRlast(
        .clk(clk), .rst(rst),
        .Hin_x(harray_0_BUF[N-2]), .Hin_y(harray_BUF[N-2][N-1]),
        .Yin_x(yarray_0_BUF[N-2]), .Yin_y(yarray_BUF[N-2][N-1]),
        .Hout_x(harray_0_out[N-1]), .Hout_y(harray_o[N-1]),
        .Yout_x(yarray_0_out[N-1]), .Yout_y(yarray_o[N-1])
    );
    
    generate
        for (j = 1; j < N - 1; j = j + 1) begin
            // First Inter buffer
            always@ (posedge clk or negedge rst) begin
                if (~rst) begin
                    harray_interBUF[N-1][j] <= 0; 
                    yarray_interBUF[N-1][j] <= 0; 
                end else begin
                    harray_interBUF[N-1][j] <= harray_BUF[N-2][j];
                    yarray_interBUF[N-1][j] <= yarray_BUF[N-2][j];
                end
            end
            assign Hmatrix_o[j*N*`WL + N*`WL-1:j*N*`WL] = harray_interBUF[N-1][j];
            assign Yarray_o[j*`WL + `WL-1:j*`WL]        = yarray_interBUF[N-1][j];
        end
    endgenerate
    
    assign Hmatrix_o[(N-1)*N*`WL + N*`WL-1: (N-1)*N*`WL]    = harray_o[N-1];
    assign Yarray_o[(N-1)*`WL + `WL-1: (N-1)*`WL]           = yarray_o[N-1];
    assign Hmatrix_o[`WL*N - 1:0]                       = harray_0_out[N-1];
    assign Yarray_o[`WL-1:0]                            = yarray_0_out[N-1];
    
endmodule