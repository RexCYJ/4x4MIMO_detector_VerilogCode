`timescale 1ns / 1ps

`define TESTNUM 1
`include "parameters.v"
//`define WL 15 
//`define ERR_WL 16
//`define GA(LEVEL) ((16 - (LEVEL)) * ((LEVEL) + 1) / 2)

module tb_DecompositionFull();
	
	integer data_file, Rdata_file;
    integer t, i, j;
    
    reg clk, rst;

    reg signed [`WL-1:0]    h_i[0:7][0:7];
    reg signed [`WL-1:0]    y_i[0:7];
    wire [(`WL*8*8)-1:0]    Hmatrix_i; 
    wire [(`WL*8)-1:0]      Yarray_i;
    wire signed [`WL-1:0]   R[0:7][0:7];
    wire signed [`WL-1:0]   Y[0:7];
    wire [2:0]              order[0:7];
    wire [(36*`WL)-1:0]     Rmat; 
    wire [(`WL*8)-1:0]      Yarr;
    wire [3 * 8 - 1 : 0]    colorder;
    
    reg signed [`WL-1:0] R_ver[0:7][0:7];
    reg signed [`WL-1:0] Y_ver[0:7];
    wire signed [`WL-1:0] R_diff[0:7][0:7];
    wire signed [`WL-1:0] Y_diff[0:7];
    
    genvar r, c;
    generate
        for (r = 0; r < 8; r = r+1) begin
            for (c = 0; c < 8; c = c+1) begin
                assign Hmatrix_i[`WL*8*r + `WL*c + `WL-1:`WL*8*r + `WL*c] = h_i[r][c];
                if (c >= r) begin
                    assign R[r][c] = Rmat[`WL*`GADD(r-1) + `WL*(c-r) + `WL-1 : `WL*`GADD(r-1) + `WL*(c-r)];
                    assign R_diff[r][c] = R_ver[r][c] - R[r][c];
                end else begin
                    assign R[r][c] = 0;
                    assign R_diff[r][c] = 0;
                end
            end
        end
        for (r = 0; r < 8; r = r+1) begin
            assign Yarray_i[`WL*r + `WL-1:`WL*r] = y_i[r];
            assign Y[r] = Yarr[`WL*r + `WL-1:`WL*r];
            assign order[r] = colorder[3*r + 2:3*r];
            assign Y_diff[r] = Y_ver[r] - Y[r];
        end
    endgenerate

    Decomposition u_Decompose(
        .clk(clk), .rst(rst),
        .Hmatrix_i(Hmatrix_i),
        .Yarray_i(Yarray_i),
        .Rmat(Rmat),
        .Yarr(Yarr),
        .colorder(colorder)
    );
    
    wire [4 * 2 - 1:0] PATH;
    wire [4 * `ERR_WL - 1:0] PED;
    
    PathGenerator u_PathGen(
        .clk(clk), .rst(rst),
        .R(Rmat[36*`WL-1:35*`WL]),
        .Y(Yarr[8*`WL-1:7*`WL]),
        .PATH(PATH),
        .PED(PED)
    );
    
    wire [`ERR_WL - 1:0] ped[3:0];
    assign {ped[3], ped[2], ped[1], ped[0]} = PED;
    
    initial begin
        clk = 1; rst = 0;
        
        data_file = $fopen("D:/Rex/NTHU/Implementation/cpp_simul/4x4MIMO_16QAM_K-best_detector/data/dat.txt","r");
        Rdata_file = $fopen("D:/Rex/NTHU/Implementation/cpp_simul/4x4MIMO_16QAM_K-best_detector/data/Rdat.txt","r");
        
        #10 rst = 1;
        for (t = 0; t < `TESTNUM; t = t + 1) begin
        	for (i = 0; i < 8; i = i+1) begin
				for (j = 0; j < 8; j = j+1) begin
					$fscanf(data_file,"%d", h_i[i][j]);
				end 
			end 
			for (i = 0; i < 8; i = i+1) begin
				$fscanf(data_file,"%d", y_i[i]);
			end
			for (i = 0; i < 8; i = i+1) begin
				for (j = 0; j < 8; j = j+1) begin
					$fscanf(Rdata_file,"%d", R_ver[i][j]);
				end 
			end 
			for (i = 0; i < 8; i = i+1) begin
				$fscanf(Rdata_file,"%d", Y_ver[i]);
			end
			#10 ;
        end
        
        
    end
    
    always #5 clk = ~clk;

endmodule
