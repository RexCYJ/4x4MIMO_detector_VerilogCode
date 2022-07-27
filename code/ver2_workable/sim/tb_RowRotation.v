`timescale 1ns / 1ps

`define WL 16


module tb_RowRotation();
    parameter N = 3;
    reg clk;
    reg signed [`WL-1:0] hin_x[0:N-1];
    reg signed [`WL-1:0] hin_y[0:N-1];
    wire signed [(`WL*N)-1:0] Hi_x;
    wire signed [(`WL*N)-1:0] Hi_y;
    reg signed [`WL-1:0] yi_x;
    reg signed [`WL-1:0] yi_y;
    wire signed [(`WL*N)-1:0] Ho_x;
    wire signed [(`WL*N)-1:0] Ho_y;
    wire signed [`WL-1:0] yo_x;
    wire signed [`WL-1:0] yo_y;
    wire signed [`WL-1:0] hout_x[0:N-1];
    wire signed [`WL-1:0] hout_y[0:N-1];
    wire signed [`WL-1:0] yout_x;
    wire signed [`WL-1:0] yout_y;
    
    RowRotation #(.N(N)) u0(
        .clk(clk),
        .Hin_x(Hi_x), .Hin_y(Hi_y),
        .Yin_x(yi_x), .Yin_y(yi_y),
        .Hout_x(Ho_x), .Hout_y(Ho_y),
        .Yout_x(yo_x), .Yout_y(yo_y)
    );
    
//    always@(posedge clk) begin
      assign {hout_x[2], hout_x[1], hout_x[0]} = Ho_x;
      assign {hout_y[2], hout_y[1], hout_y[0]} = Ho_y;
      assign yout_x = yo_x;
      assign yout_y = yo_y;
//    end
    
    assign Hi_x[`WL*N-1:0] = {hin_x[2], hin_x[1], hin_x[0]}; 
    assign Hi_y[`WL*N-1:0] = {hin_y[2], hin_y[1], hin_y[0]};
   
    initial begin
        clk <= 0;
        {hin_x[0], hin_x[1], hin_x[2]} = 0;
        {hin_y[0], hin_y[1], hin_y[2]} = 0;
        yi_x <= 0;
        yi_y <= 0;
        
        #10
        {hin_x[0], hin_x[1], hin_x[2]} <= {16'd573, -16'd921, -16'd146};
        {hin_y[0], hin_y[1], hin_y[2]} <= {16'd488, -16'd83, -16'd1257};
        yi_x <= -16'd2540;
        yi_y <= 16'd720;
        
    end
    
    always #5 clk = ~clk;

endmodule
