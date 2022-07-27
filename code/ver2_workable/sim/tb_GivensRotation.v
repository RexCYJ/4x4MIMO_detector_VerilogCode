`timescale 1ns / 1ps

`define WL 16

module tb_GivensRotation();

    parameter N = 8;        // numbers of columns to solve
    parameter cur = 8-N;
    
    integer data_file;
    integer i, j;
    
    reg clk, rst;
    
    reg signed [`WL-1:0] h_i[0:7][0:7];
    reg signed [`WL-1:0] y_i[0:7];
    wire signed [`WL-1:0] h_o[0:7][0:7];
    wire signed [`WL-1:0] y_o[0:7];
    
    wire signed [(`WL*N*N)-1:0] Hmatrix_i; 
    wire signed [(`WL*N)-1:0] Yarray_i;
    wire signed [(`WL*N*N)-1:0] Hmatrix_o;
    wire signed [(`WL*N)-1:0] Yarray_o;
    
    
    GivensRotation #(.N(N)) u_GR(
        .clk(clk),
        .Hmatrix_i(Hmatrix_i),
        .Yarray_i(Yarray_i),
        .Hmatrix_o(Hmatrix_o),
        .Yarray_o(Yarray_o) 
    );
    
    genvar r, c;
    generate
        for (r = 0; r < 8; r = r+1) begin
            for (c = 0; c < 8; c = c+1) begin
                if (r >= cur && c >= cur) begin               
                    assign Hmatrix_i[`WL*N*(r-cur) + `WL*(c-cur) + `WL-1:`WL*N*(r-cur) + `WL*(c-cur)] = h_i[r][c];
                    assign h_o[r][c] = Hmatrix_o[`WL*N*(r-cur) + `WL*(c-cur) + `WL-1:`WL*N*(r-cur) + `WL*(c-cur)];
                end else begin
                    assign h_o[r][c] = h_i[r][c];
                end
            end
        end
        for (r = 0; r < 8; r = r+1) begin
            if (r >= cur) begin
                assign Yarray_i[`WL*(r-cur) + `WL-1:`WL*(r-cur)] = y_i[r];
                assign y_o[r] = Yarray_o[`WL*(r-cur) + `WL-1:`WL*(r-cur)];
            end else begin
                assign y_o[r] = y_i[r];
            end
        end
    endgenerate

    initial begin
        
        clk = 0;
        
        data_file = $fopen("D:/Rex/NTHU/Implementation/cpp_simul/4x4MIMO_16QAM_K-best_detector/dat.txt","r");
        
        for (i = 0; i < 8; i = i+1) begin
            for (j = 0; j < 8; j = j+1) begin
                $fscanf(data_file,"%d", h_i[i][j]);
            end 
        end 
        for (i = 0; i < 8; i = i+1) begin
            $fscanf(data_file,"%d", y_i[i]);
        end

    end
    
    always #5 clk = ~clk;
    
endmodule
