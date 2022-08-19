`timescale 1ns / 1ps

//`define WL 16 

module tb_Detector();

    integer data_file;
    integer i, j;
    
    reg clk, rst;

    wire signed [`WL-1:0]   R[0:7][0:7];
    wire signed [`WL-1:0]   Y[0:7];
    wire [1:0]              x[7:0];
    wire [8 * 2 - 1:0]      X;
    
    wire [36 * `WL - 1:0]   Rmat;
    wire [8 * `WL - 1:0]    Yarr;
    
    Detector u_dtr(
        .clk(clk), .rst(rst),             
        .Rmat(Rmat),
        .Yarr(Yarr),
        .X(X)
    );
    
    genvar r, c;
    generate
        for (r = 0; r < 8; r = r + 1) begin
            for (c = r; c < 8; c = c + 1) begin
                assign Rmat[`GADD(r-1) * `WL + (c - r) * `WL + `WL - 1:`GADD(r-1) * `WL + (c - r) * `WL] = R[r][c];
            end
            assign Yarr[(r + 1) * `WL - 1:r * `WL] = Y[r];
            assign x[r] = X[(r + 1) * 2 - 1:r * 2];
        end
    endgenerate
    
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
