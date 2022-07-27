`timescale 1ns / 1ps

`define WL 16
`define FWL 12
`define COLNORM_WL 7
`define COLNORM_FWL 4
`define CORDIC_iter 9

module tb_ColPermutation();
    
    parameter N = 6;
    
    reg clk;
    
    reg signed [`WL-1:0] h_i[0:7][0:7];
    wire signed [(`WL*64)-1:0] Hmatrix_i;
    reg [`COLNORM_WL-1:0] norm_i[0:7];
    wire [(8*`COLNORM_WL) - 1:0] colnorm_i;
    reg [2:0] order_i[0:7];
    wire [(3*8)-1:0] colorder_i;
    
    wire signed [(`WL*64)-1:0] Hmatrix_o;
    wire signed [`WL-1:0] h_o[0:7][0:7];
    wire [(8*`COLNORM_WL) - 1:0] colnorm_o;
    wire [`COLNORM_WL-1:0] norm_o[0:7];
    wire [(3*8)-1:0] colorder_o;
    wire [2:0] order_o[0:7];
    
    genvar i, j; 
    generate
        for (i = 0; i < 8; i = i+1) begin
            for (j = 0; j < 8; j = j+1) begin
                assign Hmatrix_i[8*`WL*i + j*`WL + `WL-1:8*`WL*i + j*`WL] = h_i[i][j];
                assign h_o[i][j] = Hmatrix_o[8*`WL*i + j*`WL + `WL-1:8*`WL*i + j*`WL];
            end
            assign colnorm_i[`COLNORM_WL*i + `COLNORM_WL-1:`COLNORM_WL*i] = norm_i[i];
            assign norm_o[i] = colnorm_o[`COLNORM_WL*i + `COLNORM_WL-1:`COLNORM_WL*i];
            assign colorder_i[i*3 + 2:i*3] = order_i[i];
            assign order_o[i] = colorder_o[i*3 + 2:i*3];
        end
//        for (i = 0; i < N; i = i+1) begin
//            assign colnorm_i[`COLNORM_WL*i + `COLNORM_WL-1:`COLNORM_WL*i] = norm_i[i+8-N];
//            assign norm_o[i+8-N] = colnorm_o[`COLNORM_WL*i + `COLNORM_WL-1:`COLNORM_WL*i];
//            assign colorder_i[i*3 + 2:i*3] = order_i[i+8-N];
//            assign order_o[i+8-N] = colorder_o[i*3 + 2:i*3];
//        end
    endgenerate
    
    ColumnPermutation #(.N(N)) u0(
//        .clk(clk),
        .Hmatrix_i(Hmatrix_i),
        .colnorm_i(colnorm_i), // [[7] [6] ... [8-N]] 
        .colorder_i(colorder_i),
        .Hmatrix_o(Hmatrix_o),
        .colnorm_o(colnorm_o),
        .colorder_o(colorder_o)
    );
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        
        {h_i[0][0], h_i[0][1], h_i[0][2], h_i[0][3], h_i[0][4], h_i[0][5], h_i[0][6], h_i[0][7]}
        = {-16'd461, -16'd3579, 16'd602, 16'd771, -16'd2310, -16'd2056, 16'd216, 16'd1959};
        {h_i[1][0], h_i[1][1], h_i[1][2], h_i[1][3], h_i[1][4], h_i[1][5], h_i[1][6], h_i[1][7]}
        = {16'd3579, -16'd461, -16'd771, 16'd602, 16'd2056, -16'd2310, -16'd1959, 16'd216};
        {h_i[2][0], h_i[2][1], h_i[2][2], h_i[2][3], h_i[2][4], h_i[2][5], h_i[2][6], h_i[2][7]}
        = {-16'd1300, 16'd1779, -16'd1584, 16'd608, -16'd3000, -16'd1339, -16'd379, -16'd859};
        {h_i[3][0], h_i[3][1], h_i[3][2], h_i[3][3], h_i[3][4], h_i[3][5], h_i[3][6], h_i[3][7]}
        = {-16'd1779, -16'd1300, -16'd608, -16'd1584, 16'd1339, -16'd3000, 16'd859, -16'd379};
        {h_i[4][0], h_i[4][1], h_i[4][2], h_i[4][3], h_i[4][4], h_i[4][5], h_i[4][6], h_i[4][7]}
        = {-16'd1269, -16'd3111, -16'd1374, 16'd914, 16'd1265, 16'd1675, -16'd95, -16'd221};
        {h_i[5][0], h_i[5][1], h_i[5][2], h_i[5][3], h_i[5][4], h_i[5][5], h_i[5][6], h_i[5][7]}
        = {16'd3111, -16'd1269, -16'd914, -16'd1374, -16'd1675, 16'd1265, 16'd221, -16'd95};
        {h_i[6][0], h_i[6][1], h_i[6][2], h_i[6][3], h_i[6][4], h_i[6][5], h_i[6][6], h_i[6][7]}
        = {-16'd2773, -16'd2237, 16'd1525, 16'd1526, -16'd33, -16'd2336, -16'd652, -16'd900};
        {h_i[7][0], h_i[7][1], h_i[7][2], h_i[7][3], h_i[7][4], h_i[7][5], h_i[7][6], h_i[7][7]}
        = {16'd2237, -16'd2773, -16'd1526, 16'd1525, 16'd2336, -16'd33, 16'd900, -16'd652};
        {norm_i[0], norm_i[1], norm_i[2], norm_i[3], norm_i[4], norm_i[5], norm_i[6], norm_i[7]}
        = {7'd36, 7'd65, 7'd10, 7'd7, 7'd29, 7'd31, 7'd4, 7'd5};
        {order_i[0], order_i[1], order_i[2], order_i[3], order_i[4], order_i[5], order_i[6], order_i[7]}
        = {3'd0, 3'd1, 3'd2, 3'd3, 3'd4, 3'd5, 3'd6, 3'd7};
    end
    
    
endmodule
