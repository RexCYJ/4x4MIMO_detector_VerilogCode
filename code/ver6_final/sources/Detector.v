`timescale 1ns / 1ps

`include "parameters.v"

module Detector(
        input  clk, rst,
        input  [(36*`WL)-1:0]   Rmat,   
        input  [(8*`WL)-1:0]    Yarr,
        output [8 * 2 - 1:0]    X
    );
    
    reg  [8 * `WL - 1:0] Rarr0[0:24];
    reg  [7 * `WL - 1:0] Rarr1[0:20];
    reg  [6 * `WL - 1:0] Rarr2[0:16];
    reg  [5 * `WL - 1:0] Rarr3[0:12];
    reg  [4 * `WL - 1:0] Rarr4[0:8];
    reg  [3 * `WL - 1:0] Rarr5[0:4];
    reg  [2 * `WL - 1:0] Rarr6;
    reg  [`WL - 1:0]     Y0[0:24];
    reg  [`WL - 1:0]     Y1[0:20];
    reg  [`WL - 1:0]     Y2[0:16];
    reg  [`WL - 1:0]     Y3[0:12];
    reg  [`WL - 1:0]     Y4[0:8]; 
    reg  [`WL - 1:0]     Y5[0:4]; 
    reg  [`WL - 1:0]     Y6;      
        
    PathGenerator u_PGen(
        .clk(clk), .rst(rst),
        .R(Rmat[36*`WL - 1:35*`WL]),
        .Y(Yarr[8*`WL - 1:7*`WL])
    );
    
    // -----STAGE 6------------------------------------------------------
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            Rarr6 <= 0;
            Y6    <= 0;
        end else begin
            Rarr6 <= Rmat[`GADD(6) * `WL - 1:`GADD(5) * `WL];
            Y6    <= Yarr[7 * `WL - 1: 6 * `WL];
        end
    end
    
    DetectorStage #(.N(2)) uDetectorStage6(
        .clk(clk),      .rst(rst),
        .Rarr(Rarr6),   .Y(Y6),
        .PATH_in(u_PGen.PATH),  .PED_in(u_PGen.PED)
    );
    
    // -----STAGE 5------------------------------------------------------  
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            Rarr5[0] <= 0;
            Y5[0]    <= 0;
        end else begin
            Rarr5[0] <= Rmat[`GADD(5) * `WL - 1:`GADD(4) * `WL];
            Y5[0]    <= Yarr[6 * `WL - 1: 5 * `WL];
        end
    end
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            always@(posedge clk or negedge rst) begin
                if (~rst) begin
                    Rarr5[i + 1] <= 0;
                    Y5[i + 1]    <= 0;
                end else begin
                    Rarr5[i + 1] <= Rarr5[i];
                    Y5[i + 1]    <= Y5[i];
                end
            end            
        end
    endgenerate
    
    DetectorStage #(.N(3)) uDetectorStage5(
        .clk(clk),      .rst(rst),
        .Rarr(Rarr5[4]),   .Y(Y5[4]),
        .PATH_in(uDetectorStage6.PATH_out),  .PED_in(uDetectorStage6.PED_out)
    );
    
    // -----STAGE 4------------------------------------------------------  
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            Rarr4[0] <= 0;
            Y4[0]    <= 0;
        end else begin
            Rarr4[0] <= Rmat[`GADD(4) * `WL - 1:`GADD(3) * `WL];
            Y4[0]    <= Yarr[5 * `WL - 1: 4 * `WL];
        end
    end

    generate
        for (i = 0; i < 8; i = i + 1) begin
            always@(posedge clk or negedge rst) begin
                if (~rst) begin
                    Rarr4[i + 1] <= 0;
                    Y4[i + 1]    <= 0;
                end else begin
                    Rarr4[i + 1] <= Rarr4[i];
                    Y4[i + 1]    <= Y4[i];
                end
            end            
        end
    endgenerate
    
    DetectorStage #(.N(4)) uDetectorStage4(
        .clk(clk),      .rst(rst),
        .Rarr(Rarr4[8]),   .Y(Y4[8]),
        .PATH_in(uDetectorStage5.PATH_out),  .PED_in(uDetectorStage5.PED_out)
    );
    
    // -----STAGE 3------------------------------------------------------  
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            Rarr3[0] <= 0;
            Y3[0]    <= 0;
        end else begin
            Rarr3[0] <= Rmat[`GADD(3) * `WL - 1:`GADD(2) * `WL];
            Y3[0]    <= Yarr[4 * `WL - 1: 3 * `WL];
        end
    end

    generate
        for (i = 0; i < 12; i = i + 1) begin
            always@(posedge clk or negedge rst) begin
                if (~rst) begin
                    Rarr3[i + 1] <= 0;
                    Y3[i + 1]    <= 0;
                end else begin
                    Rarr3[i + 1] <= Rarr3[i];
                    Y3[i + 1]    <= Y3[i];
                end
            end            
        end
    endgenerate
    
    DetectorStage #(.N(5)) uDetectorStage3(
        .clk(clk),      .rst(rst),
        .Rarr(Rarr3[12]),   .Y(Y3[12]),
        .PATH_in(uDetectorStage4.PATH_out),  .PED_in(uDetectorStage4.PED_out)
    );
    
    // -----STAGE 2------------------------------------------------------  
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            Rarr2[0] <= 0;
            Y2[0]    <= 0;
        end else begin
            Rarr2[0] <= Rmat[`GADD(2) * `WL - 1:`GADD(1) * `WL];
            Y2[0]    <= Yarr[3 * `WL - 1: 2 * `WL];
        end
    end

    generate
        for (i = 0; i < 16; i = i + 1) begin
            always@(posedge clk or negedge rst) begin
                if (~rst) begin
                    Rarr2[i + 1] <= 0;
                    Y2[i + 1]    <= 0;
                end else begin
                    Rarr2[i + 1] <= Rarr2[i];
                    Y2[i + 1]    <= Y2[i];
                end
            end            
        end
    endgenerate
    
    DetectorStage #(.N(6)) uDetectorStage2(
        .clk(clk),      .rst(rst),
        .Rarr(Rarr2[16]),   .Y(Y2[16]),
        .PATH_in(uDetectorStage3.PATH_out),  .PED_in(uDetectorStage3.PED_out)
    );
    
    // -----STAGE 1------------------------------------------------------  
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            Rarr1[0] <= 0;
            Y1[0]    <= 0;
        end else begin
            Rarr1[0] <= Rmat[`GADD(1) * `WL - 1:`GADD(0) * `WL];
            Y1[0]    <= Yarr[2 * `WL - 1: 1 * `WL];
        end
    end

    generate
        for (i = 0; i < 20; i = i + 1) begin
            always@(posedge clk or negedge rst) begin
                if (~rst) begin
                    Rarr1[i + 1] <= 0;
                    Y1[i + 1]    <= 0;
                end else begin
                    Rarr1[i + 1] <= Rarr1[i];
                    Y1[i + 1]    <= Y1[i];
                end
            end            
        end
    endgenerate
    
    DetectorStage #(.N(7)) uDetectorStage1(
        .clk(clk),      .rst(rst),
        .Rarr(Rarr1[20]),   .Y(Y1[20]),
        .PATH_in(uDetectorStage2.PATH_out),  .PED_in(uDetectorStage2.PED_out)
    );
    
    // -----STAGE 0------------------------------------------------------  
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            Rarr0[0] <= 0;
            Y0[0]    <= 0;
        end else begin
            Rarr0[0] <= Rmat[`GADD(0) * `WL - 1:0 * `WL];
            Y0[0]    <= Yarr[1 * `WL - 1: 0 * `WL];
        end
    end

    generate
        for (i = 0; i < 24; i = i + 1) begin
            always@(posedge clk or negedge rst) begin
                if (~rst) begin
                    Rarr0[i + 1] <= 0;
                    Y0[i + 1]    <= 0;
                end else begin
                    Rarr0[i + 1] <= Rarr0[i];
                    Y0[i + 1]    <= Y0[i];
                end
            end
        end
    endgenerate
    
    DetectorStage #(.N(8)) uDetectorStage0(
        .clk(clk),      .rst(rst),
        .Rarr(Rarr0[24]),   .Y(Y0[24]),
        .PATH_in(uDetectorStage1.PATH_out),  .PED_in(uDetectorStage1.PED_out)
    );
    
    assign X = uDetectorStage0.PATH_out[8 * 2 - 1:0];
    
endmodule
