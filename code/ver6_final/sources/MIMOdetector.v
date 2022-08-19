`timescale 1ns / 1ps

`include "parameters.v"

module MIMOdetector(
        input clk, rst,
        input [(64*`WL)-1:0]    Hmatrix_i,
        input [(8*`WL)-1:0]     Yarray_i,
        output reg [8 * 2 - 1:0] X
    );
    
    reg [8 * 3 - 1:0] colorder[0:27];
    
    Decomposition u_decom(
        .clk(clk), .rst(rst),
        .Hmatrix_i(Hmatrix_i),
        .Yarray_i(Yarray_i)
    );
    
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            colorder[0] <= {3'd7, 3'd6, 3'd5, 3'd4, 3'd3, 3'd2, 3'd1, 3'd0};
        end else begin
            colorder[0] <= u_decom.colorder;
        end
    end
    
    genvar i;
    generate
        for (i = 0; i < 27; i = i + 1) begin
            always@(posedge clk or negedge rst) begin
                if (~rst) begin
                    colorder[i + 1] <= {3'd7, 3'd6, 3'd5, 3'd4, 3'd3, 3'd2, 3'd1, 3'd0};
                end else begin
                    colorder[i + 1] <= colorder[i];
                end
            end
        end
    endgenerate
    
    Detector u_dtr(
        .clk(clk), .rst(rst),
        .Rmat(u_decom.Rmat),
        .Yarr(u_decom.Yarr)
    );
    
    X_Rearrange u_rearr(
        .Xi(u_dtr.X),
        .colorder(colorder[27])
    );
    
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            X <= 0;
        end else begin
            X <= u_rearr.Xo;
        end
    end
    
endmodule
