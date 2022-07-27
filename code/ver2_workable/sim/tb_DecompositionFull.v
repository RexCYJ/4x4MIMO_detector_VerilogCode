`timescale 1ns / 1ps

`define WL 16
`define PL_CYCLES 23

module tb_DecompositionFull();

    integer data_file;
    integer i, j;
    
    reg clk, clk_pl, rst;

    reg signed [`WL-1:0] h_i[0:7][0:7];
    reg signed [`WL-1:0] y_i[0:7];
    wire [(`WL*8*8)-1:0] Hmatrix_i; 
    wire [(`WL*8)-1:0] Yarray_i;
    wire signed [`WL-1:0] R[0:7][0:7];
    wire signed [`WL-1:0] Y[0:7];
    wire [2:0] order[0:7];
    wire [(`WL*8*8)-1:0] Rmat; 
    wire [(`WL*8)-1:0] Yarr;
    wire [3 * 8 - 1 : 0] colorder;
    
    reg signed [`WL-1:0] R_ver[0:7][0:7];
    reg signed [`WL-1:0] Y_ver[0:7];
    wire signed [`WL-1:0] R_diff[0:7][0:7];
    wire signed [`WL-1:0] Y_diff[0:7];
    
    genvar r, c;
    generate
        for (r = 0; r < 8; r = r+1) begin
            for (c = 0; c < 8; c = c+1) begin
                assign Hmatrix_i[`WL*8*r + `WL*c + `WL-1:`WL*8*r + `WL*c] = h_i[r][c];
                assign R[r][c] = Rmat[`WL*8*r + `WL*c + `WL-1:`WL*8*r + `WL*c];
                assign R_diff[r][c] = R_ver[r][c] - R[r][c]; 
            end
        end
        for (r = 0; r < 8; r = r+1) begin
            assign Yarray_i[`WL*r + `WL-1:`WL*r] = y_i[r];
            assign Y[r] = Yarr[`WL*r + `WL-1:`WL*r];
            assign order[r] = colorder[3*r + 2:3*r];
            assign Y_diff[r] = Y_ver[r] - Y[r];
        end
    endgenerate

    Decomposition_1 u_Decompose(
        .clk(clk), .clk_pl(clk_pl), .rst(rst),
        .Hmatrix_i(Hmatrix_i),
        .Yarray_i(Yarray_i),
        .Rmat(Rmat),
        .Yarr(Yarr),
        .colorder(colorder)
    );
    
    initial begin
        clk = 0; rst = 0;
        #5       
        rst = 1;
        #10
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
            for (j = 0; j < 8; j = j+1) begin
                $fscanf(data_file,"%d", R_ver[i][j]);
            end 
        end 
        for (i = 0; i < 8; i = i+1) begin
            $fscanf(data_file,"%d", Y_ver[i]);
        end
        
    end
    
    always #5 clk = ~clk;
   
    reg [4:0] cnt_reg;
    reg clk_pl_reg; 
    reg [4:0] cnt;
    
    always@* begin
        if (cnt_reg < `PL_CYCLES - 2) begin
            cnt = cnt_reg + 1;
            clk_pl_reg = 1;
        end else if (cnt_reg == `PL_CYCLES - 2) begin
            cnt = cnt_reg + 1;
            clk_pl_reg = 0;
        end else begin
            cnt = 0;
            clk_pl_reg = 1;
        end
    end
    
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            cnt_reg <= 0;
            clk_pl <= 0;
        end else begin
            cnt_reg <= cnt;
            clk_pl <= clk_pl_reg;
        end
    end

endmodule
