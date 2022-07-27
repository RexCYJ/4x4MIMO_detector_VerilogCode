`timescale 1ns / 1ps

`define WL 16
`define COLNORM_WL 7 

module tb_Decomposition();

    parameter N = 6;
    parameter cur = 8-N;
    
    integer data_file;
    integer i, j;
    
    reg clk, rst;
    
    reg signed [`WL-1:0] h_i[0:7][0:7];
    reg signed [`WL-1:0] y_i[0:7];
    reg [2:0] order_i[0:7];
    reg [`COLNORM_WL-1:0] norm_i[0:7];
    
    wire signed [`WL-1:0] h_o[0:7][0:7];
    wire signed [`WL-1:0] y_o[0:7];
    wire [2:0] order_o[0:7];
    wire [`COLNORM_WL-1:0] norm_o[0:7];
    
    wire [(`WL*8*8)-1:0] Hmatrix_i; 
    wire [(`WL*8)-1:0] Yarray_i;
    wire [(8*`COLNORM_WL) - 1:0] colnorm_i;
    wire [8*3 - 1:0] colorder_i;
    wire [(`WL*8*8)-1:0] Hmatrix_o;
    wire [(`WL*8)-1:0] Yarray_o;
    wire [(8*`COLNORM_WL) - 1:0] colnorm_o;
    wire [8*3 - 1:0] colorder_o;
    
    genvar r, c;
    generate
        for (r = 0; r < 8; r = r+1) begin
            for (c = 0; c < 8; c = c+1) begin
                assign Hmatrix_i[`WL*8*r + `WL*c + `WL-1:`WL*8*r + `WL*c] = h_i[r][c];
                assign h_o[r][c] = Hmatrix_o[`WL*8*r + `WL*c + `WL-1:`WL*8*r + `WL*c];
            end
        end
        for (r = 0; r < 8; r = r+1) begin
            assign Yarray_i[`WL*r + `WL-1:`WL*r] = y_i[r];
            assign y_o[r] = Yarray_o[`WL*r + `WL-1:`WL*r];
            assign colnorm_i[`COLNORM_WL*r + `COLNORM_WL-1:`COLNORM_WL*r] = norm_i[r];
            assign norm_o[r] = colnorm_o[`COLNORM_WL*r + `COLNORM_WL-1:`COLNORM_WL*r];
            assign colorder_i[3*r + 3-1:3*r] = order_i[r];
            assign order_o[r] = colorder_o[3*r + 3-1:3*r];
        end
    endgenerate

    DecomposeStage #(.N(N)) u_Decom(
        .clk(clk), .rst(rst),
        .Hmatrix_i(Hmatrix_i),
        .Yarray_i(Yarray_i),
        .colnorm_i(colnorm_i),
        .colorder_i(colorder_i),
        .Hmatrix_o(Hmatrix_o),
        .Yarray_o(Yarray_o),
        .colnorm_o(colnorm_o),
        .colorder_o(colorder_o)
    );

    initial begin
        
        clk = 0; rst = 1;
        
//        #2 rst = 0;
//        #4 rst = 1;
//        #1
        
        data_file = $fopen("D:/Rex/NTHU/Implementation/cpp_simul/4x4MIMO_16QAM_K-best_detector/dat.txt","r");
        
        for (i = 0; i < 8; i = i+1) begin
            for (j = 0; j < 8; j = j+1) begin
                $fscanf(data_file,"%d", h_i[i][j]);
            end 
        end 
        for (i = 0; i < 8; i = i+1) begin
            $fscanf(data_file,"%d", y_i[i]);
        end
        for (i = 0; i < 8; i = i+1) begin
            $fscanf(data_file,"%d", order_i[i]);
        end
        for (i = 0; i < 8; i = i+1) begin
            $fscanf(data_file,"%d", norm_i[i]);
        end
    end

    always #5 clk = ~clk;

endmodule
