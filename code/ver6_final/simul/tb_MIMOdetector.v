`timescale 1ns / 1ps

`define TESTNUM 1

module tb_MIMOdetector();

    integer data_file, xdata_file;
    integer x_dtc_file;
    integer i, j, t;
    integer cnt, cycle;
    reg clk, rst;

    reg signed [`WL-1:0]    h_i[0:7][0:7];
    reg signed [`WL-1:0]    y_i[0:7];
    wire [(`WL*8*8)-1:0]    Hmatrix_i;
    wire [(`WL*8)-1:0]      Yarray_i;
    wire [8 * 2 - 1:0]      X;
    wire [3:0]              x[3:0];
    wire [3:0]              x_orig[3:0];
    reg  [3:0]              x_ver[0:94][3:0];
    wire [3:0]              err[3:0];
    
    genvar r, c;
    generate 
        for (r = 0; r < 8; r = r + 1) begin
            for (c = 0; c < 8; c = c + 1) begin
                assign Hmatrix_i[r * 8 * `WL + c * `WL + `WL - 1:r * 8 * `WL + c * `WL] = h_i[r][c];
            end
            assign Yarray_i[r * `WL + `WL - 1:r * `WL] = y_i[r];
        end
    endgenerate
    
    generate 
        for (r = 0; r < 4; r = r + 1) begin
            assign x[r] = X[(r + 1) * 4 - 1:r * 4];
            assign x_orig[r] = x_ver[94][r];
            assign err[r] = x[r] ^ x_orig[r];
        end
        for (r = 0; r < 94; r = r + 1) begin
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
    
    MIMOdetector u_MIMODTR(
        .clk(clk), .rst(rst),
        .Hmatrix_i(Hmatrix_i),
        .Yarray_i(Yarray_i),
        .X(X)
    );

    initial begin
        clk = 1; rst = 0;
        x_ver[0][0] = 0;
        x_ver[0][1] = 0;
        x_ver[0][2] = 0;
        x_ver[0][3] = 0;
        cycle = 0;
        data_file = $fopen("D:/Rex/NTHU/Implementation/cpp_simul/4x4MIMO_16QAM_K-best_detector/data/dat.txt","r");
        xdata_file = $fopen("D:/Rex/NTHU/Implementation/cpp_simul/4x4MIMO_16QAM_K-best_detector/data/xdat.txt","r");
        x_dtc_file = $fopen("D:/Rex/NTHU/Implementation/cpp_simul/4x4MIMO_16QAM_K-best_detector/data/xdtc_vivado_dat.txt","w");
        
        #10  rst = 1;
        
        for (t = 0; t < `TESTNUM; t = t + 1) begin
        	if (cycle < 94) begin
        		cycle = cycle + 1;
        	end else begin
        		$fwrite(x_dtc_file, "%d %d %d %d\n", x[3], x[2], x[1], x[0]);
        		cycle = cycle + 1;
        	end
            for (i = 3; i >= 0; i = i - 1) begin
                cnt = $fscanf(xdata_file,"%d", x_ver[0][i]); 
            end
            for (i = 0; i < 8; i = i+1) begin
                for (j = 0; j < 8; j = j+1) begin
                    cnt = $fscanf(data_file,"%d", h_i[i][j]);
                end 
            end 
            for (i = 0; i < 8; i = i+1) begin
                cnt = $fscanf(data_file,"%d", y_i[i]);
            end
            #10 ;
        end
        
		while (cycle < (94 + `TESTNUM)) begin
			$fwrite(x_dtc_file, "%d %d %d %d\n", x[3], x[2], x[1], x[0]);
			cycle = cycle + 1;
			#10 ;
		end
		
		$fclose(x_dtc_file);
		
    end
    
    always #5 clk = ~clk;

endmodule
