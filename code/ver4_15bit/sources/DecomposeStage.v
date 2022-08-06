`timescale 1ns / 1ps

`include "parameters.v"

module DecomposeStage
    #(parameter N = 7) (
        input clk, rst,
        input [(64*`WL)-1:0]            Hmatrix_i,
        input [(8*`WL)-1:0]             Yarray_i,
        input [(8*`COLNORM_WL) - 1:0]   colnorm_i,
        input [8*3 - 1:0]               colorder_i,
        output [(64*`WL)-1:0]           Hmatrix_o,
        output [(8*`WL)-1:0]            Yarray_o,
        output [(8*`COLNORM_WL) - 1:0]  colnorm_o,
        output [8*3 - 1:0]              colorder_o
    );
                        
    localparam cur = 8-N;           // current column
    localparam CC = (N-2) * 3 + 2;  // # of clock cycles
    
    wire [(8*`COLNORM_WL) - 1:0]    colnorm_new;
    
    wire [2:0]                      mincol;
    reg  [2:0]                      mincol_FF;
    reg  [(64*`WL)-1:0]             Hmat_all_BUF;
    reg  [(8*`WL)-1:0]              Yarr_all_BUF;
    wire [(64*`WL)-1:0]             Hmatrix_perm;
    wire [(8*`COLNORM_WL) - 1:0]    colnorm__perm;
    wire [(8*3)-1:0]                colorder_perm;
    
    reg [(8*`COLNORM_WL) - 1:0] colnorm__BUF[0:CC];
    reg [(8*3)-1:0]             colorder_BUF[0:CC];
    reg [(8*cur*`WL)-1:0]       Hup_BUF[1:CC];  // upper part of H, which is unused
    reg [(cur*`WL)-1:0]         Yup_BUF[1:CC];
    
    // partial Hmatrix that is fed to GivensRotation
    wire [(`WL*N*N)-1:0]    Hmatrix_in;
    wire [(`WL*N*N)-1:0]    Hmatrix_out;
    wire [(`WL*N)-1:0]      Yarray_in;
    wire [(`WL*N)-1:0]      Yarray_out;
    
    ColumnNormUpdate #(.N(N)) u_ColNormUpdate(
        .Harray_i(Hmatrix_i[`WL*8*cur - 1: `WL*8*(cur-1) + `WL*cur]),           // h_j,j+1, h_j,j+2, ..., h_j,7               
        .colnorm_i(colnorm_i),
        .colnorm_o(colnorm_new)
    );
    
    
    MinNormComp #(.N(N)) uMinNorm(
        .colnorm_i(colnorm_new[`COLNORM_WL*8-1:`COLNORM_WL*(8-N)]),
        .mincol(mincol)
    );
    
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            mincol_FF <= cur;
            colnorm__BUF[0] <= 0;
            colorder_BUF[0] <= 0;
            Hmat_all_BUF <= 0;
            Yarr_all_BUF <= 0;
        end else begin
            mincol_FF <= mincol;
            colnorm__BUF[0] <= colnorm_new;
            colorder_BUF[0] <= colorder_i;
            Hmat_all_BUF <= Hmatrix_i;
            Yarr_all_BUF <= Yarray_i;
        end
    end
    
    ColExchange #(.TARCOL(cur)) uColXchg(
        .mincol(mincol_FF),
        .Hmatrix_i(Hmat_all_BUF),
        .colnorm_i(colnorm__BUF[0][`COLNORM_WL*8-1:`COLNORM_WL*cur]), 
        .colorder_i(colorder_BUF[0][3*8-1:3*cur]),
        .Hmatrix_o(Hmatrix_perm),
        .colnorm_o(colnorm__perm[`COLNORM_WL*8-1:`COLNORM_WL*cur]),
        .colorder_o(colorder_perm[3*8-1:3*cur])
    );
    
    assign colnorm__perm[`COLNORM_WL*cur - 1: 0] = colnorm__BUF[0][`COLNORM_WL*cur - 1: 0];
    assign colorder_perm[3*cur - 1: 0] = colorder_BUF[0][3*cur - 1: 0];
    
    // BUFFER unused elements ------------------------------------------------------------- 
    
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            colnorm__BUF[1] <= 0;
            colorder_BUF[1] <= 0;
            Hup_BUF[1] <= 0;
            Yup_BUF[1] <= 0;
        end else begin
            colnorm__BUF[1] <= colnorm__perm;
            colorder_BUF[1] <= colorder_perm;
            Hup_BUF[1] <= Hmatrix_perm[cur *  8 * `WL - 1: 0];
            Yup_BUF[1] <= Yarr_all_BUF[cur * `WL - 1: 0];
        end
    end
    
    genvar i;
    generate
        for (i = 2; i <= CC; i = i + 1) begin
            always@(posedge clk or negedge rst) begin
                if (~rst) begin
                    colnorm__BUF[i] <= 0;
                    colorder_BUF[i] <= 0;
                    Hup_BUF[i]      <= 0;
                    Yup_BUF[i]      <= 0;
                end else begin
                    colnorm__BUF[i] <= colnorm__BUF[i-1];
                    colorder_BUF[i] <= colorder_BUF[i-1];
                    Hup_BUF[i] <= Hup_BUF[i-1];
                    Yup_BUF[i] <= Yup_BUF[i-1];
                end
            end
        end
    endgenerate
    
    // Givens Rotation ----------------------------------------------------------------
    
    genvar r, c;
    generate    // assign N * N H matrix to GivensRotation
        for (r = cur; r < 8; r = r + 1) begin
            assign Hmatrix_in[(r - cur + 1) * N * `WL - 1 : (r - cur) * N * `WL] 
                    = Hmatrix_perm[(r + 1) * 8 * `WL - 1 : r * 8 * `WL + cur * `WL];
            assign Yarray_in[(r - cur + 1) * `WL - 1 : (r - cur) * `WL]
                    = Yarr_all_BUF[(r + 1) * `WL - 1 : r * `WL];
        end 
    endgenerate
    
    GivensRotation #(.N(N)) u_GR(
        .clk(clk), .rst(rst),
        .Hmatrix_i(Hmatrix_in),
        .Yarray_i(Yarray_in),
        .Hmatrix_o(Hmatrix_out),
        .Yarray_o(Yarray_out) 
    );
    
    // OUTPUT -------------------------------------------------------------------------
    
    assign Hmatrix_o[cur *  8 * `WL - 1: 0] = Hup_BUF[CC];
    assign Yarray_o[cur * `WL - 1: 0]       = Yup_BUF[CC];
    assign colnorm_o  = colnorm__BUF[CC];
    assign colorder_o = colorder_BUF[CC];
    
    generate    // assign N * N rotated H matrix from GivensRotation to output. 
        for (r = cur; r < 8; r = r + 1) begin
            assign  Hmatrix_o[(r + 1) * 8 * `WL - 1 : r * 8 * `WL + cur * `WL]
                    = Hmatrix_out[(r - cur + 1) * N * `WL - 1 : (r - cur) * N * `WL];
            assign Yarray_o[(r + 1) * `WL - 1 : r * `WL]
                    = Yarray_out[(r - cur + 1) * `WL - 1 : (r - cur) * `WL];
            assign  Hmatrix_o[r * 8 * `WL + cur * `WL - 1 : r * 8 * `WL] = 0;
        end 
    endgenerate

endmodule

module DecomposeStage_first (
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
    wire [(8*`COLNORM_WL) - 1:0] colnorm_perm;
    wire [8*3 - 1:0] colorder_perm;
    
    reg [(8*`COLNORM_WL) - 1:0] colnorm_BUF[0:21];
    reg [(8*3) - 1:0]           colorder_BUF[1:21];
    
    wire [(64*`WL)-1:0] Hmatrix_0;
//    reg  [(64*`WL)-1:0] Hmatrix_1;
    
//    wire [(`WL*N*N)-1:0] Hmatrix_in;
//    wire [(`WL*N*N)-1:0] Hmatrix_out;
//    wire [(`WL*N)-1:0] Yarray_in;
//    wire [(`WL*N)-1:0] Yarray_out;
    
    reg [(`WL*N*N)-1:0]    Hmat_BUF[0:1];
    reg [(`WL*N)-1:0]      Yarr_BUF[0:1];
    
    // initial the column norm
    ColNormCalculator u_ColNormCal(
        .Hmatrix(Hmatrix_i),
        .colnorm(colnorm_0)
    );
    
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            colnorm_BUF[0] <= 0;
            Hmat_BUF[0] <= 0;
            Yarr_BUF[0] <= 0;
        end else begin
            colnorm_BUF[0] <= colnorm_0;
            Hmat_BUF[0] <= Hmatrix_i;
            Yarr_BUF[0] <= Yarray_i;
        end
    end
    
    // initial the column order
    assign colorder_i = {3'd7, 3'd6, 3'd5, 3'd4, 3'd3, 3'd2, 3'd1, 3'd0};
    
    ColumnPermutation #(.N(N)) u_ColPerm(    // # of column
        .Hmatrix_i(Hmat_BUF[0]),
        .colnorm_i(colnorm_BUF[0]),
        .colorder_i(colorder_i),
        .Hmatrix_o(Hmatrix_0),
        .colnorm_o(colnorm_perm),
        .colorder_o(colorder_perm)
    );
    
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            colnorm_BUF[1] <= 0;
            colorder_BUF[1] <= 0;
            Hmat_BUF[1] <= 0;
            Yarr_BUF[1] <= 0;
        end else begin
            colnorm_BUF[1] <= colnorm_perm;
            colorder_BUF[1] <= colorder_perm;
            Hmat_BUF[1] <= Hmatrix_0;
            Yarr_BUF[1] <= Yarr_BUF[0];
        end
    end

    GivensRotation #(.N(N)) u_GR(
        .clk(clk), .rst(rst),
        .Hmatrix_i(Hmat_BUF[1]),
        .Yarray_i(Yarr_BUF[1]),
        .Hmatrix_o(Hmatrix_o),
        .Yarray_o(Yarray_o) 
    );
    
    genvar i;
    generate
        for (i = 2; i < 22; i = i + 1) begin
            always@(posedge clk or negedge rst) begin
                if (~rst) begin
                    colnorm_BUF[i] <= 0;
                    colorder_BUF[i] <= 0;
                end else begin
                    colnorm_BUF[i] <= colnorm_BUF[i-1]; 
                    colorder_BUF[i] <= colorder_BUF[i-1];
                end
            end
        end 
    endgenerate
    
    assign colnorm_o  = colnorm_BUF[21];
    assign colorder_o = colorder_BUF[21];
    
endmodule