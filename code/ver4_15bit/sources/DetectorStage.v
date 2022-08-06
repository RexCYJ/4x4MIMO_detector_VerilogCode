`timescale 1ns / 1ps

`include "..\imports\ver2_workable\parameters.v"

// 4 clock cycles
module DetectorStage
    #(parameter N = 2) (
        input                           clk, rst,
        input  [N * `WL - 1:0]          Rarr,
        input  signed [`WL - 1:0]       Y,
        input  [4 * (N - 1) * 2 - 1:0]  PATH_in,
        input  [4 * `ERR_WL - 1:0]      PED_in,
        output reg [4 * N * 2 - 1:0]    PATH_out,
        output reg [4 * `ERR_WL - 1:0]  PED_out
    );
    
    reg [4 * 4 * N * 2 - 1:0]    PATH16_buf;
    reg [4 * 4 * `ERR_WL - 1:0]  PED16_buf;
//    reg [N * `WL - 1:0]          Rarr_buf;
//    reg signed [`WL - 1:0]       Y_buf;   
//    reg [4 * (N - 1) * 2 - 1:0]  PATH_in_buf;
//    reg [4 * `ERR_WL - 1:0]      PED_in_buf;
//    always@(posedge clk or negedge rst) begin
//        if (~rst) begin
//            Rarr_buf <= 0;
//            Y_buf <= 0;
//            PATH_in_buf <= 0;
//            PED_in_buf <= 0;            
//        end else begin
//            Rarr_buf <= Rarr;
//            Y_buf <= Y;
//            PATH_in_buf <= PATH_in;
//            PED_in_buf <= PED_in;
//        end
//    end
//    PathFinder #(.N(N)) u_PF(
//        .clk(clk), .rst(rst),
//        .Rarr(Rarr_buf),
//        .Y(Y_buf),
//        .PATH_in(PATH_in_buf),
//        .PED_in(PED_in_buf)
//    );
    
    PathFinder #(.N(N)) u_PF(
        .clk(clk), .rst(rst),
        .Rarr(Rarr),
        .Y(Y),
        .PATH_in(PATH_in),
        .PED_in(PED_in)
    );
    
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            PATH16_buf <= 0;
            PED16_buf  <= 0;
        end else begin
            PATH16_buf <= u_PF.PATH_out;
            PED16_buf  <= u_PF.PED_out;
        end
    end

    PathEnum #(.N(N)) u_PE(
        .clk(clk), .rst(rst),
        .PATH16_in(PATH16_buf),
        .PED16_in(PED16_buf)
    );
    
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            PATH_out <= 0;
            PED_out  <= 0;
        end else begin
            PATH_out <= u_PE.PATH_out;
            PED_out  <= u_PE.PED_out;
        end
    end
    
endmodule
