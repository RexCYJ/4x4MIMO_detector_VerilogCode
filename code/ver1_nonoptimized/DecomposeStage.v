`timescale 1ns / 1ps

`include "parameters.v"

module DecomposeStage
    #(parameter N = 7) (
        input clk, rst,
        input [(64*`WL)-1:0] Hmatrix_i,
        input [(8*`WL)-1:0] Yarray_i,
        input [(8*`COLNORM_WL) - 1:0] colnorm_i,
        input [8*3 - 1:0] colorder_i,
        output [(64*`WL)-1:0] Hmatrix_o,
        output [(8*`WL)-1:0] Yarray_o,
        output [(8*`COLNORM_WL) - 1:0] colnorm_o,
        output [8*3 - 1:0] colorder_o
    );
                        
    localparam cur = 8-N;   // current column
    
    wire [(8*`COLNORM_WL) - 1:0] colnorm_0;
    wire [(64*`WL)-1:0] Hmatrix_1;
//    wire [(8*`COLNORM_WL) - 1:0] colnorm_1;
//    wire [8*3 - 1:0] colorder_1;
    
    reg [(N*N*`WL)-1:0] Hmatrix_FF1;
    
    wire [(`WL*N*N)-1:0] Hmatrix_in;
    wire [(`WL*N*N)-1:0] Hmatrix_out;
    wire [(`WL*N)-1:0] Yarray_in;
    wire [(`WL*N)-1:0] Yarray_out;
    
    
    ColumnNormUpdate #(.N(N)) u_ColNormUpdate(
        .Harray_i(Hmatrix_i[`WL*8*cur - 1: `WL*8*(cur-1) + `WL*cur]),           // h_j,j+1, h_j,j+2, ..., h_j,7               
        .colnorm_i(colnorm_i),
        .colnorm_o(colnorm_0)
    );

    
    ColumnPermutation #(.N(N)) u_ColPerm(    // # of column
        .Hmatrix_i(Hmatrix_i),
        .colnorm_i(colnorm_0), 
        .colorder_i(colorder_i),
        .Hmatrix_o(Hmatrix_1),
        .colnorm_o(colnorm_o),
        .colorder_o(colorder_o)
    );
    
    genvar r, c;
    generate    // pack the NxN matrix H for GivensRotation to solve
        for (r = 0; r < 8; r = r+1) begin
            for (c = 0; c < 8; c = c+1) begin
                if (r >= cur && c >= cur) begin               
                    assign Hmatrix_in[`WL*N*(r-cur) + `WL*(c-cur) + `WL-1:`WL*N*(r-cur) + `WL*(c-cur)] 
                            = Hmatrix_1[`WL*8*r + `WL*c + `WL-1:`WL*8*r + `WL*c];
                    assign Hmatrix_o[`WL*8*r + `WL*c + `WL-1:`WL*8*r + `WL*c] 
                            = Hmatrix_out[`WL*N*(r-cur) + `WL*(c-cur) + `WL-1:`WL*N*(r-cur) + `WL*(c-cur)];
                end else begin
                    assign Hmatrix_o[`WL*8*r + `WL*c + `WL-1:`WL*8*r + `WL*c] 
                            = Hmatrix_1[`WL*8*r + `WL*c + `WL-1:`WL*8*r + `WL*c];
                end
            end
        end
        for (r = 0; r < 8; r = r+1) begin
            if (r >= cur) begin
                assign Yarray_in[`WL*(r-cur) + `WL-1:`WL*(r-cur)] 
                        = Yarray_i[`WL*r + `WL-1:`WL*r];
                assign Yarray_o[`WL*r + `WL-1:`WL*r]
                        = Yarray_out[`WL*(r-cur) + `WL-1:`WL*(r-cur)];
            end else begin
                assign Yarray_o[`WL*r + `WL-1:`WL*r] = Yarray_i[`WL*r + `WL-1:`WL*r];
            end
        end
    endgenerate

    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            Hmatrix_FF1 <= 0;
        end else begin
            Hmatrix_FF1 <= Hmatrix_in;
        end
    end

    GivensRotation #(.N(N)) u_GR(
        .clk(clk),
        .Hmatrix_i(Hmatrix_FF1),
        .Yarray_i(Yarray_in),
        .Hmatrix_o(Hmatrix_out),
        .Yarray_o(Yarray_out) 
    );

endmodule

module DecomposeStage1 (
        input clk, rst,
        input [(64*`WL)-1:0] Hmatrix_i,
        input [(8*`WL)-1:0] Yarray_i,
        output [(64*`WL)-1:0] Hmatrix_o,
        output [(8*`WL)-1:0] Yarray_o,
        output [(8*`COLNORM_WL) - 1:0] colnorm_o,
        output [8*3 - 1:0] colorder_o
    );
    
    localparam N = 8;  
    localparam cur = 0;   // current column
    
    wire [8*3 - 1:0] colorder_i;
    wire [(8*`COLNORM_WL) - 1:0] colnorm_0;
    wire [(64*`WL)-1:0] Hmatrix_1;
//    wire [(8*`COLNORM_WL) - 1:0] colnorm_1;
//    wire [8*3 - 1:0] colorder_1;
    
    reg [(N*N*`WL)-1:0] Hmatrix_FF1;
    
    wire [(`WL*N*N)-1:0] Hmatrix_in;
    wire [(`WL*N*N)-1:0] Hmatrix_out;
    wire [(`WL*N)-1:0] Yarray_in;
    wire [(`WL*N)-1:0] Yarray_out;
   
    // initial the column norm
    ColNormCalculator u_ColNormCal(
        .Hmatrix(Hmatrix_i),
        .colnorm(colnorm_0)
    );
    
    // initial the column order
    assign colorder_i = {3'd7, 3'd6, 3'd5, 3'd4, 3'd3, 3'd2, 3'd1, 3'd0};
    
    ColumnPermutation #(.N(N)) u_ColPerm(    // # of column
        .Hmatrix_i(Hmatrix_i),
        .colnorm_i(colnorm_0),
        .colorder_i(colorder_i),
        .Hmatrix_o(Hmatrix_1),
        .colnorm_o(colnorm_o),
        .colorder_o(colorder_o)
    );
    
    genvar r, c;
    generate    // pack the NxN matrix H for GivensRotation to solve
        for (r = 0; r < 8; r = r+1) begin
            for (c = 0; c < 8; c = c+1) begin
                if (r >= cur && c >= cur) begin               
                    assign Hmatrix_in[`WL*N*(r-cur) + `WL*(c-cur) + `WL-1:`WL*N*(r-cur) + `WL*(c-cur)] 
                            = Hmatrix_1[`WL*8*r + `WL*c + `WL-1:`WL*8*r + `WL*c];
                    assign Hmatrix_o[`WL*8*r + `WL*c + `WL-1:`WL*8*r + `WL*c] 
                            = Hmatrix_out[`WL*N*(r-cur) + `WL*(c-cur) + `WL-1:`WL*N*(r-cur) + `WL*(c-cur)];
                end else begin
                    assign Hmatrix_o[`WL*8*r + `WL*c + `WL-1:`WL*8*r + `WL*c] 
                            = Hmatrix_1[`WL*8*r + `WL*c + `WL-1:`WL*8*r + `WL*c];
                end
            end
        end
        for (r = 0; r < 8; r = r+1) begin
            if (r >= cur) begin
                assign Yarray_in[`WL*(r-cur) + `WL-1:`WL*(r-cur)] 
                        = Yarray_i[`WL*r + `WL-1:`WL*r];
                assign Yarray_o[`WL*r + `WL-1:`WL*r]
                        = Yarray_out[`WL*(r-cur) + `WL-1:`WL*(r-cur)];
            end else begin
                assign Yarray_o[`WL*r + `WL-1:`WL*r] = Yarray_i[`WL*r + `WL-1:`WL*r];
            end
        end
    endgenerate

    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            Hmatrix_FF1 <= 0;
        end else begin
            Hmatrix_FF1 <= Hmatrix_in;
        end
    end

    GivensRotation #(.N(N)) u_GR(
        .clk(clk),
        .Hmatrix_i(Hmatrix_FF1),
        .Yarray_i(Yarray_in),
        .Hmatrix_o(Hmatrix_out),
        .Yarray_o(Yarray_out) 
    );

endmodule