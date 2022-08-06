`timescale 1ns / 1ps

`include "..\imports\ver2_workable\parameters.v"

module BranchSort
    # (parameter N = 2) (
        input [4 * N * 2 - 1:0]         PATH_in,
        input [4 * `ERR_WL - 1:0]       PED_in,
        input [1:0]                     dir,
        output reg [4 * N * 2 - 1:0]    PATH_out,       // sorted path
        output reg [4 * `ERR_WL - 1:0]  PED_out         // sorted PED
    );
    
    wire [`ERR_WL - 1: 0]       ped[3:0];
    wire [N * 2 - 1: 0]         path[3:0];
    reg  [1:0]                  winnerchild[2:0];
    reg  [`ERR_WL-1:0]          smallped[1:0];
    reg  [0:0]                  bcdir;
        
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            assign path[i] = PATH_in[i * N * 2 + N * 2 - 1: i * N * 2];
            assign ped[i] = PED_in[i * `ERR_WL + `ERR_WL-1: i * `ERR_WL];
        end
    endgenerate
    
    // binary tree comparator
    always@* begin
        if (ped[0] < ped[1]) begin
            winnerchild[0] = 2'b10;
            smallped[0]    = ped[0];
        end else begin
            winnerchild[0] = 2'b11;
            smallped[0]    = ped[1];
        end
    end
    always@* begin
        if (ped[2] < ped[3]) begin
            winnerchild[1] = 2'b01;
            smallped[1]    = ped[2];
        end else begin
            winnerchild[1] = 2'b00;
            smallped[1]    = ped[3];
        end
    end
    always@* begin
        if (smallped[0] < smallped[1]) begin
            winnerchild[2] = winnerchild[0];
        end else begin
            winnerchild[2] = winnerchild[1];
        end
    end
    
    always@* begin
        case(winnerchild[2])
            2'b10:  begin
                        PATH_out = {path[3], path[2], path[1], path[0]};
                        PED_out  = { ped[3],  ped[2],  ped[1],  ped[0]};
                    end
            2'b11:  if (~dir[0]) begin
                        PATH_out = {path[3], path[2], path[0], path[1]};
                        PED_out  = { ped[3],  ped[2],  ped[0],  ped[1]};
                    end else begin
                        PATH_out = {path[3], path[0], path[2], path[1]};
                        PED_out  = { ped[3],  ped[0],  ped[2],  ped[1]};
                    end
            2'b01:  if (~dir[1]) begin
                        PATH_out = {path[0], path[3], path[1], path[2]};
                        PED_out  = { ped[0],  ped[3],  ped[1],  ped[2]};
                    end else begin
                        PATH_out = {path[0], path[1], path[3], path[2]};
                        PED_out  = { ped[0],  ped[1],  ped[3],  ped[2]};
                    end
            2'b00:  begin
                        PATH_out = {path[0], path[1], path[2], path[3]};
                        PED_out  = { ped[0],  ped[1],  ped[2],  ped[3]};
                    end
        endcase
    end
    
endmodule
