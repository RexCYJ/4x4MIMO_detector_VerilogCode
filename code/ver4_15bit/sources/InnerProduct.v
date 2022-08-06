`timescale 1ns / 1ps

`include "parameters.v"

module PathGenerator(
        input signed [`WL - 1:0]    R,
        input signed [`WL - 1:0]    Y,
        output [4 * 2 - 1:0]        PATH,
        output [4*`ERR_WL - 1:0]    PED
    );
    
    wire signed [2 * `ERR_WL - 1:0]     prod[1:0];
    wire signed [`ERR_WL - 1:0]         err[3:0];
    wire [2*`ERR_WL - 1:0]              err2[3:0];
    wire [`ERR_WL - 1:0]                ped[3:0];
    wire signed [`WL-1:0]               C0 = -16'd3886;
    wire signed [`WL-1:0]               C1 = -16'd1295;
    
    assign prod[0] = ((C0 * R) >>> `FWL); 
    assign prod[1] = ((C1 * R) >>> `FWL); 
    
    assign err[0] = Y - prod[0];    // x = -3
    assign err[1] = Y - prod[1];    // x = -1
    assign err[2] = Y + prod[1];    // x =  1
    assign err[3] = Y + prod[0];    // x =  3
    
    assign err2[0] = err[0] * err[0];
    assign err2[1] = err[1] * err[1];
    assign err2[2] = err[2] * err[2];
    assign err2[3] = err[3] * err[3];
    
    assign ped[0] = (err2[0] >>> `ERR_FWL);
    assign ped[1] = (err2[1] >>> `ERR_FWL);
    assign ped[2] = (err2[2] >>> `ERR_FWL);
    assign ped[3] = (err2[3] >>> `ERR_FWL);
    
    assign PED  = {ped[3], ped[2], ped[1], ped[0]};
    assign PATH = { 2'b00,  2'b01,  2'b11,  2'b10};
    
endmodule

module PathFinder
    #(parameter N = 2)(
        input clk, rst,
        input [N * `WL - 1:0]           Rarr,
        input signed [`WL - 1:0]        Y,
        input [4 * (N - 1) * 2 - 1:0]   PATH_in,
        input [4 * `ERR_WL - 1:0]       PED_in,
        output [4 * 4 * N * 2 - 1:0]    PATH_out,
        output [4 * 4 * `ERR_WL - 1:0]  PED_out
    );
    
    wire signed [`WL-1:0] C0 = -16'd3886;
    wire signed [`WL-1:0] C1 = -16'd1295;
    wire signed [2 * `WL-1:0]   ChildProd[1:0];
    wire signed [`WL-1:0]       Rpivot;
    wire [1:0]                  RpivotXORerr[3:0];
    wire [4 * N * 2 - 1:0]      PATH4[3:0];
    wire [4 * `ERR_WL - 1:0]    PED4[3:0];
    wire [1:0]                  errsign[3:0];  
    reg  [4 * N * 2 - 1:0]      PATH4_buf[3:0];
    reg  [4 * `ERR_WL - 1:0]    PED4_buf[3:0];
    reg  [1:0]                  RpivotXORerr_buf[3:0];  
    
    assign Rpivot = Rarr[`WL-1:0];
    assign ChildProd[0] = ((C0 * Rpivot) >>> `FWL);
    assign ChildProd[1] = ((C1 * Rpivot) >>> `FWL);
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            // calculate the PED of the 4 branches of each path 
            PED_calculate_1path #(.N(N)) u_PathCal(
                .Rarr(Rarr[N * `WL - 1:`WL]),
                .Y(Y),
                .PATH_in(PATH_in[(i+1) *(N-1)*2 - 1: i *(N-1)*2]),
                .PED_in(PED_in[i*`ERR_WL + `ERR_WL - 1: i*`ERR_WL]),
                .ChildProd0(ChildProd[0]),
                .ChildProd1(ChildProd[1]),
                .PATH_out(PATH4[i]),
                .PED_out(PED4[i]),
                .errsign(errsign[i])
            );
                        
            // derive the direction indicator
            assign RpivotXORerr[i] = {2{Rpivot[`WL-1]}} ~^ errsign[i];
            
            always@(posedge clk or negedge rst) begin
                if (~rst) begin
                    PATH4_buf[i] <= 0;
                    PED4_buf[i]  <= 0;
                    RpivotXORerr_buf[i] <= 0;
                end else begin
                    PATH4_buf[i] <= PATH4[i];
                    PED4_buf[i]  <= PED4[i];
                    RpivotXORerr_buf[i] <= RpivotXORerr[i];
                end
            end
                        
            // find the best branch, and then sort the 4 branches
            BranchSort #(.N(N)) u_BS(
                .PATH_in(PATH4_buf[i]),
                .PED_in(PED4_buf[i]),
                .dir(RpivotXORerr_buf[i]),
                .PATH_out(PATH_out[(i+1) * 4 * N * 2 - 1: i * 4 * N * 2]),
                .PED_out(PED_out[(i+1) * 4 * `ERR_WL - 1: i * 4 * `ERR_WL])
            );
        end
    endgenerate
    
endmodule

// Calculate the PED of the 4 branches of each path
module PED_calculate_1path
    #(parameter N = 2)(
        input [N * `WL - 1:`WL]     Rarr,
        input signed [`WL - 1:0]    Y,
        input [N * 2 - 1:2]         PATH_in,
        input [`ERR_WL - 1:0]       PED_in,
        input [2 * `WL - 1:0]       ChildProd0,
        input [2 * `WL - 1:0]       ChildProd1,        
        output [4 * N * 2 - 1:0]    PATH_out,
        output [4 * `ERR_WL - 1:0]  PED_out,
        output [1:0]                errsign
    );
    
    localparam LEN = N - 1;
    
    wire signed [`WL-1:0] C0 = -16'd3886;
    wire signed [`WL-1:0] C1 = -16'd1295;
    wire signed [`WL-1:0] C2 =  16'd1295;
    wire signed [`WL-1:0] C3 =  16'd3886;
    wire        [1:0]           x[N-1:1];
    wire signed [`WL-1:0]       r[N-1:1];
    reg  signed [2 * `WL-1:0]   prod[N-1:1];
    wire signed [`WL-1:0]       sum[2 * (LEN-1):0];
    wire signed [`ERR_WL - 1:0] err[3:0];
    wire [2 * `ERR_WL - 1:0]    err2[3:0];
    wire [`ERR_WL - 1:0]        ped[3:0];
    
    genvar i;
    generate        
        for (i = 1; i < N; i = i + 1) begin
            assign r[i] = Rarr[i * `WL + `WL - 1: i * `WL];
            assign x[i] = PATH_in[i * 2 + 1: i * 2];
            always@* begin
                case(x[i])
                    2'b10: prod[i] = (r[i] * C0) >>> `FWL;
                    2'b11: prod[i] = (r[i] * C1) >>> `FWL;
                    2'b01: prod[i] = (r[i] * C2) >>> `FWL;
                    2'b00: prod[i] = (r[i] * C3) >>> `FWL;
                endcase
            end
            assign sum[i-1] = prod[i];
        end
    endgenerate
    
    generate        // tree adder
        for (i = 0; i < LEN-1; i = i + 1) begin
            assign sum[i + LEN] = sum[i * 2] + sum[i * 2 + 1];
        end
    endgenerate
    
    assign err[0] = Y - ChildProd0 - sum[2 * (LEN-1)];  // xii = -3
    assign err[1] = Y - ChildProd1 - sum[2 * (LEN-1)];  // xii = -1
    assign err[2] = Y + ChildProd1 - sum[2 * (LEN-1)];  // xii =  1
    assign err[3] = Y + ChildProd0 - sum[2 * (LEN-1)];  // xii =  3
    
    assign err2[0] = (err[0] * err[0] >>> `ERR_FWL);
    assign err2[1] = (err[1] * err[1] >>> `ERR_FWL);
    assign err2[2] = (err[2] * err[2] >>> `ERR_FWL);
    assign err2[3] = (err[3] * err[3] >>> `ERR_FWL);
    
    assign ped[0] = err2[0] + PED_in;
    assign ped[1] = err2[1] + PED_in;
    assign ped[2] = err2[2] + PED_in;
    assign ped[3] = err2[3] + PED_in;
        
    // arrange path by PED 
    assign PATH_out = {PATH_in, 2'b00, PATH_in, 2'b01, PATH_in, 2'b11, PATH_in, 2'b10};
    assign PED_out  = { ped[3],         ped[2],         ped[1],         ped[0]};
    assign errsign  = {err[2][`ERR_WL-1], err[1][`ERR_WL-1]};
    
endmodule
