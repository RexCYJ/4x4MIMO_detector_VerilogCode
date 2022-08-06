`timescale 1ns / 1ps

`include "..\imports\ver2_workable\parameters.v"

module TopInterface(
        input clk, rst,
        input signed [`InWL - 1:0]       In0,
        input signed [`InWL - 1:0]       In1,
        input signed [`InWL - 1:0]       In2,
        input signed [`InWL - 1:0]       In3,
        output [8 * 2 - 1:0]    X 
    );
    
    reg [4:0] cnt_reg;
    reg [4:0] cnt;
    reg [4 * `InWL - 1:0]     BUFFER1[8:0];
    reg [4 * `InWL - 1:0]     BUFFER2[8:0];
    reg [64 * `InWL - 1:0]    Hmat;
    reg [64 * `InWL - 1:0]    Hmat_reg;
    reg [8 * `InWL - 1:0]     Yarr;
    reg [8 * `InWL - 1:0]     Yarr_reg;
    
    always@ (posedge clk or negedge rst) begin 
        if (~rst) begin
            BUFFER1[0] <= 0;
            BUFFER2[0] <= 0; 
        end else begin
            BUFFER1[0] <= {In3, In2, In1, In0};
            BUFFER2[0] <= {-In2, In3, -In0, In1};
        end
    end
            
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @ (posedge clk or negedge rst) begin 
                if (~rst) begin
                    BUFFER1[i + 1] <= 0;
                    BUFFER2[i + 1] <= 0; 
                end else begin
                    BUFFER1[i + 1] <= BUFFER1[i];
                    BUFFER2[i + 1] <= BUFFER2[i];
                end
            end     
        end
    endgenerate
    
    always@* begin 
        if (cnt_reg < 5'd9) begin
            cnt = cnt_reg + 1;
            Hmat = Hmat_reg;
            Yarr = Yarr_reg;
        end else begin
            cnt = 0; 
            Hmat = {BUFFER1[8], BUFFER1[7], 
                    BUFFER2[8], BUFFER2[7], 
                    BUFFER1[6], BUFFER1[5], 
                    BUFFER2[6], BUFFER2[5], 
                    BUFFER1[4], BUFFER1[3], 
                    BUFFER2[4], BUFFER2[3], 
                    BUFFER1[2], BUFFER1[1], 
                    BUFFER2[2], BUFFER2[1]};
            Yarr = {BUFFER1[0], In3, In2, In1, In0};
        end
    end
    
    always @ (posedge clk or negedge rst) begin
        if (~rst) begin
            cnt_reg <= 0;
            Hmat_reg <= 0;
            Yarr_reg <= 0;
        end else begin
            cnt_reg <= cnt;
            Hmat_reg <= Hmat;
            Yarr_reg <= Yarr;
        end
    end    
    
    MIMOdetector u_MIMO_DTR(
        .clk(clk), .rst(rst),
        .Hmatrix_i(Hmat_reg),
        .Yarray_i(Yarr_reg),
        .X(X)
    );
    
endmodule


//module TopInterface(
//        input clk, rst,
//        input [`WL - 1:0]       In0,
//        input [`WL - 1:0]       In1,
//        input [`WL - 1:0]       In2,
//        input [`WL - 1:0]       In3,
//        output [8 * 2 - 1:0]    X 
//    );
    
//    reg [4:0] cnt_reg;
//    reg [4:0] cnt;
//    reg [68 * `WL - 1:0]    BUFFER;
//    reg [68 * `WL - 1:0]    BUFFER_reg;
//    reg [64 * `WL - 1:0]    Hmat;
//    reg [64 * `WL - 1:0]    Hmat_reg;
//    reg [8 * `WL - 1:0]     Yarr;
//    reg [8 * `WL - 1:0]     Yarr_reg;
    
//    always@* begin
//        BUFFER = {BUFFER_reg, In3, In2, In1, In0}; 
//        if (cnt_reg < 5'd17) begin
//            cnt = cnt_reg + 1;
//            Hmat = Hmat_reg;
//            Yarr = Yarr_reg;
//        end else begin
//            cnt = 0; 
//            Hmat = BUFFER_reg[68 * `WL - 1:4 * `WL];
//            Yarr = {BUFFER_reg[4 * `WL - 1:0], In3, In2, In1, In0};
//        end
//    end
    
//    always @ (posedge clk or negedge rst) begin
//        if (~rst) begin
//            cnt_reg <= 0;
//            BUFFER_reg <= 0;
//            Hmat_reg <= 0;
//            Yarr_reg <= 0;
//        end else begin
//            cnt_reg <= cnt;
//            BUFFER_reg <= BUFFER;
//            Hmat_reg <= Hmat;
//            Yarr_reg <= Yarr;
//        end
//    end    
    
//    MIMOdetector u_MIMO_DTR(
//        .clk(clk), .rst(rst),
//        .Hmatrix_i(Hmat_reg),
//        .Yarray_i(Yarr_reg),
//        .X(X)
//    );
    
//endmodule
