`timescale 1ns / 1ps

`define TESTNUM 1

module tb_Top2();
    
    integer data0_file, data1_file, data2_file, xdata_file;
    integer i, t;
    integer cnt;
    
    reg clk, rst;
    
    reg  [`InWL-1:0]	In[2:0];
    wire [8 * 2 - 1:0]	X;
    wire [3:0]			x[3:0];
    reg  [3:0]			x_ver[0:109][3:0];
    wire [3:0]			x_orig[3:0];
    wire [3:0]			err[3:0];
    
    genvar r, c;
    generate 
        for (r = 0; r < 4; r = r + 1) begin
            assign x[r] = X[(r + 1) * 4 - 1:r * 4];
            assign x_orig[r] = x_ver[109][r];
            assign err[r] = x[r] ^ x_orig[r];
        end
        for (r = 0; r < 109; r = r + 1) begin
            always@ (posedge clk or negedge rst) begin
                if (~rst) begin
                    x_ver[r + 1][0] <= 0;
                    x_ver[r + 1][1] <= 0;
                    x_ver[r + 1][2] <= 0;
                    x_ver[r + 1][3] <= 0;
                end else begin
                    x_ver[r + 1][0] <= x_ver[r][0];
                    x_ver[r + 1][1] <= x_ver[r][1];
                    x_ver[r + 1][2] <= x_ver[r][2];
                    x_ver[r + 1][3] <= x_ver[r][3];
                end
            end
        end
    endgenerate
    
    TopInterface_2 u_top(
        .clk(clk), .rst(rst),
        .In0(In[0]),
        .In1(In[1]),
        .In2(In[2]),
        .X(X)
    );

    initial begin
        clk = 1; 
        rst = 0;
        x_ver[0][0] = 0;
        x_ver[0][1] = 0;
        x_ver[0][2] = 0;
        x_ver[0][3] = 0;
        data2_file = $fopen("D:/Rex/NTHU/Implementation/cpp_simul/4x4MIMO_16QAM_K-best_detector/data/data2.txt","r");
        data1_file = $fopen("D:/Rex/NTHU/Implementation/cpp_simul/4x4MIMO_16QAM_K-best_detector/data/data1.txt","r");
        data0_file = $fopen("D:/Rex/NTHU/Implementation/cpp_simul/4x4MIMO_16QAM_K-best_detector/data/data0.txt","r");
        xdata_file = $fopen("D:/Rex/NTHU/Implementation/cpp_simul/4x4MIMO_16QAM_K-best_detector/data/xdat.txt","r");
        cnt = $fscanf(data2_file,"%d", In[2]);
        cnt = $fscanf(data1_file,"%d", In[1]);
        cnt = $fscanf(data0_file,"%d", In[0]);
        
        #10  rst = 1;
        
        for (t = 0; t < `TESTNUM; t = t + 1) begin
            for (i = 3; i >= 0; i = i - 1) begin
                $fscanf(xdata_file,"%d", x_ver[0][i]); 
            end
            for (i = 0; i < 14; i = i+1) begin
                cnt = $fscanf(data2_file,"%d", In[2]);
                cnt = $fscanf(data1_file,"%d", In[1]);
                cnt = $fscanf(data0_file,"%d", In[0]);
                #10 ;
            end
        end
        
    end
    
    always #5 clk = ~clk;

endmodule
