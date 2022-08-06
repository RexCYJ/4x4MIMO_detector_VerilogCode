`timescale 1ns / 1ps

`include "..\imports\ver2_workable\parameters.v"

module PathEnum
    #(parameter N = 2) (
        input clk, rst,
        input [4 * 4 * N * 2 - 1:0]     PATH16_in,
        input [4 * 4 * `ERR_WL - 1:0]   PED16_in,
        output [4 * N * 2 - 1:0]        PATH_out,
        output [4 * `ERR_WL - 1:0]      PED_out
    );
    
    reg  [4 * 2 * N * 2 - 1:0]      path_LV2_buf;
    reg  [4 * 2 * `ERR_WL - 1:0]    ped_LV2_buf;
    wire [N * 2 - 1:0]              path_sel[3:0];
    wire [`ERR_WL - 1:0]            ped_sel[3:0];
    
    BestBranch #(.N(N), .LV(4)) u_BB4(
        .path_i(PATH16_in),  .ped_i(PED16_in),
        .path_sel(path_sel[0]),  .ped_sel(ped_sel[0])
    );
    
    generate
        if (N < 8) begin
            reg  [N * 2 - 1:0]              path_sel_buf[1:0];
            reg  [`ERR_WL - 1:0]            ped_sel_buf[1:0];
            BestBranch #(.N(N), .LV(3)) u_BB3(
                .path_i(u_BB4.path_o),  .ped_i(u_BB4.ped_o),
                .path_sel(path_sel[1]),  .ped_sel(ped_sel[1])
            );
            
            always@(posedge clk or negedge rst) begin
                if (~rst) begin
                    path_LV2_buf <= 0;
                    ped_LV2_buf  <= 0;
                    path_sel_buf[0] <= 0;
                    path_sel_buf[1] <= 0;
                    ped_sel_buf[0] <= 0;
                    ped_sel_buf[1] <= 0;
                end else begin
                    path_LV2_buf <= u_BB3.path_o;
                    ped_LV2_buf  <= u_BB3.ped_o;
                    path_sel_buf[0] <= path_sel[0];
                    path_sel_buf[1] <= path_sel[1];
                    ped_sel_buf[0] <= ped_sel[0];
                    ped_sel_buf[1] <= ped_sel[1];
                end
            end
            
            BestBranch #(.N(N), .LV(2)) u_BB2(
                .path_i(path_LV2_buf),  .ped_i(ped_LV2_buf),
                .path_sel(path_sel[2]),  .ped_sel(ped_sel[2])
            );
            
            BestBranch #(.N(N), .LV(1)) u_BB1(
                .path_i(u_BB2.path_o),  .ped_i(u_BB2.ped_o),
                .path_sel(path_sel[3]),  .ped_sel(ped_sel[3])
            );
            
            assign PATH_out = {path_sel[3], path_sel[2], path_sel_buf[1], path_sel_buf[0]};
            assign PED_out = {ped_sel[3], ped_sel[2], ped_sel_buf[1], ped_sel_buf[0]};
            
        end else begin
            assign PATH_out = path_sel[0];
            assign PED_out = ped_sel[0];
        end
    endgenerate 
    
endmodule

module BestBranch
    #(parameter N = 2, LV = 4) (
        input  [4 * LV * N * 2 - 1:0]       path_i,
        input  [4 * LV * `ERR_WL - 1:0]     ped_i,
        output [4 * (LV-1) * N * 2 - 1:0]   path_o,
        output [4 * (LV-1) * `ERR_WL - 1:0] ped_o,
        output reg [N * 2 - 1:0]            path_sel,
        output reg [`ERR_WL - 1:0]          ped_sel                
    );
    
    wire [N * 2 - 1:0]              path_cand[3:0];
    wire [`ERR_WL - 1:0]            ped_cand[3:0];
    reg  [1:0]                      winnerpath[2:0];
    reg  [`ERR_WL - 1:0]            winnerped[1:0];
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            assign path_cand[i] = path_i[i*LV*N*2 + N*2 - 1:i*LV*N*2];
            assign ped_cand[i] = ped_i[i*LV*`ERR_WL + `ERR_WL - 1:i*LV*`ERR_WL];                              
        end
    endgenerate
    
    always@* begin
        if (ped_cand[0] < ped_cand[1]) begin
            winnerpath[0] = 2'b00;
            winnerped[0]  = ped_cand[0];
        end else begin
            winnerpath[0] = 2'b01;
            winnerped[0]  = ped_cand[1];
        end
    end
    always@* begin
        if (ped_cand[2] < ped_cand[3]) begin
            winnerpath[1] = 2'b10;
            winnerped[1]  = ped_cand[2];
        end else begin
            winnerpath[1] = 2'b11;
            winnerped[1]  = ped_cand[3];
        end
    end
    always@* begin
        if (winnerped[0] < winnerped[1]) begin
            winnerpath[2] = winnerpath[0];
        end else begin
            winnerpath[2] = winnerpath[1];
        end
    end
    
    always@* begin
        case(winnerpath[2])
            2'b00:  begin
                        path_sel = path_cand[0];
                        ped_sel  =  ped_cand[0];
                    end
            2'b01:  begin
                        path_sel = path_cand[1];
                        ped_sel  =  ped_cand[1];
                    end
            2'b10:  begin
                        path_sel = path_cand[2];
                        ped_sel  =  ped_cand[2];
                    end
            2'b11:  begin
                        path_sel = path_cand[3];
                        ped_sel  =  ped_cand[3];
                    end
        endcase
    end
    
    generate
        if (LV > 1) begin
            reg  [(LV-1) * N * 2 - 1:0]     path_nx[3:0];
            reg  [(LV-1) * `ERR_WL - 1:0]   ped_nx[3:0];
            always@* begin
                case(winnerpath[2])
                    2'b00:  begin
                                path_nx[0] = path_i[1 *LV*N*2 - 1: 0 *LV*N*2 + 1 *N*2];
                                path_nx[1] = path_i[1 *LV*N*2 + (LV-1)*N*2 - 1: 1 *LV*N*2];
                                path_nx[2] = path_i[2 *LV*N*2 + (LV-1)*N*2 - 1: 2 *LV*N*2];
                                path_nx[3] = path_i[3 *LV*N*2 + (LV-1)*N*2 - 1: 3 *LV*N*2];
                                ped_nx[0] = ped_i[1 *LV*`ERR_WL - 1: 1 *`ERR_WL];
                                ped_nx[1] = ped_i[1 *LV*`ERR_WL + (LV-1)*`ERR_WL - 1: 1 *LV*`ERR_WL];
                                ped_nx[2] = ped_i[2 *LV*`ERR_WL + (LV-1)*`ERR_WL - 1: 2 *LV*`ERR_WL];
                                ped_nx[3] = ped_i[3 *LV*`ERR_WL + (LV-1)*`ERR_WL - 1: 3 *LV*`ERR_WL];
                            end
                    2'b01:  begin
                                path_nx[0] = path_i[0 *LV*N*2 + (LV-1)*N*2 - 1: 0 *LV*N*2];
                                path_nx[1] = path_i[2 *LV*N*2 - 1: 1 *LV*N*2 + 1 *N*2];
                                path_nx[2] = path_i[2 *LV*N*2 + (LV-1)*N*2 - 1: 2 *LV*N*2];
                                path_nx[3] = path_i[3 *LV*N*2 + (LV-1)*N*2 - 1: 3 *LV*N*2];
                                ped_nx[0] = ped_i[0 *LV*`ERR_WL + (LV-1)*`ERR_WL - 1: 0 *LV*`ERR_WL];
                                ped_nx[1] = ped_i[2 *LV*`ERR_WL - 1: 1 *LV*`ERR_WL + 1 *`ERR_WL];
                                ped_nx[2] = ped_i[2 *LV*`ERR_WL + (LV-1)*`ERR_WL - 1: 2 *LV*`ERR_WL];
                                ped_nx[3] = ped_i[3 *LV*`ERR_WL + (LV-1)*`ERR_WL - 1: 3 *LV*`ERR_WL];
                            end
                    2'b10:  begin
                                path_nx[0] = path_i[0 *LV*N*2 + (LV-1)*N*2 - 1: 0 *LV*N*2];
                                path_nx[1] = path_i[1 *LV*N*2 + (LV-1)*N*2 - 1: 1 *LV*N*2];
                                path_nx[2] = path_i[3 *LV*N*2 - 1: 2 *LV*N*2 + 1 *N*2];
                                path_nx[3] = path_i[3 *LV*N*2 + (LV-1)*N*2 - 1: 3 *LV*N*2];
                                ped_nx[0] = ped_i[0 *LV*`ERR_WL + (LV-1)*`ERR_WL - 1: 0 *LV*`ERR_WL];
                                ped_nx[1] = ped_i[1 *LV*`ERR_WL + (LV-1)*`ERR_WL - 1: 1 *LV*`ERR_WL];
                                ped_nx[2] = ped_i[3 *LV*`ERR_WL - 1: 2 *LV*`ERR_WL + 1 *`ERR_WL];
                                ped_nx[3] = ped_i[3 *LV*`ERR_WL + (LV-1)*`ERR_WL - 1: 3 *LV*`ERR_WL];
                            end
                    2'b11:  begin
                                path_nx[0] = path_i[0 *LV*N*2 + (LV-1)*N*2 - 1: 0 *LV*N*2];
                                path_nx[1] = path_i[1 *LV*N*2 + (LV-1)*N*2 - 1: 1 *LV*N*2];
                                path_nx[2] = path_i[2 *LV*N*2 + (LV-1)*N*2 - 1: 2 *LV*N*2];
                                path_nx[3] = path_i[4 *LV*N*2 - 1: 3 *LV*N*2 + 1 *N*2];
                                ped_nx[0] = ped_i[0 *LV*`ERR_WL + (LV-1)*`ERR_WL - 1: 0 *LV*`ERR_WL];
                                ped_nx[1] = ped_i[1 *LV*`ERR_WL + (LV-1)*`ERR_WL - 1: 1 *LV*`ERR_WL];
                                ped_nx[2] = ped_i[2 *LV*`ERR_WL + (LV-1)*`ERR_WL - 1: 2 *LV*`ERR_WL];
                                ped_nx[3] = ped_i[4 *LV*`ERR_WL - 1: 3 *LV*`ERR_WL + 1 *`ERR_WL];
                            end
                endcase
            end     
            assign path_o = {path_nx[3], path_nx[2], path_nx[1], path_nx[0]};
            assign ped_o = {ped_nx[3], ped_nx[2], ped_nx[1], ped_nx[0]};
        end else begin
            assign path_o = 0;
            assign ped_o = 0;
        end
    endgenerate
    
endmodule
