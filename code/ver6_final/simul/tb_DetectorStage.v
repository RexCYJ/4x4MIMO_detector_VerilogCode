`timescale 1ns / 1ps

//`define WL 16

module tb_DetectorStage();

    integer data_file;
    integer i, j;
    
    reg clk, rst;

    wire signed [`WL-1:0]   R[0:7][0:7];
    wire signed [`WL-1:0]   Y[0:7];
    wire [3:0]              x[3:0];
    wire [`WL-1:0]          PED[3:0];
    
    PathGenerator u_PGen(
        .clk(clk), .rst(rst),
        .R(R[7][7]),
        .Y(Y[7])
    );
    
    DetectorStage #(.N(2)) uDetectorStage(
        .clk(clk), .rst(rst),
        .Rarr({R[6][7], R[6][6]}),
        .Y(Y[6]),
        .PATH_in(u_PGen.PATH),
        .PED_in(u_PGen.PED),
        .PATH_out({x[3], x[2], x[1], x[0]}),
        .PED_out({PED[3], PED[2], PED[1], PED[0]})
    );
    
    initial begin
        clk = 0; rst = 1;
        
        data_file = $fopen("D:/Rex/NTHU/Implementation/cpp_simul/4x4MIMO_16QAM_K-best_detector/dat.txt","r");
        
        for (i = 0; i < 8; i = i+1) begin
            for (j = 0; j < 8; j = j+1) begin
                $fscanf(data_file,"%d", R[i][j]);
            end 
        end 
        for (i = 0; i < 8; i = i+1) begin
            $fscanf(data_file,"%d", Y[i]);
        end
        
        #2  rst = 0;
        #3  rst = 1;
        
    end
    
    always #5 clk = ~clk;
    
endmodule
