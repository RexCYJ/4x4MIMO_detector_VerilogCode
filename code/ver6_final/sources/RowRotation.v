`timescale 1ns / 1ps

`include "parameters.v"

`define BP0 5   // Break point 0
`define BP1 6   // Break point 1
    
// Rotate one vector
module AngleRegulator
    (input signed [`WL-1:0] xi,
     input signed [`WL-1:0] yi,
     input en,
     output reg signed [`WL-1:0] xo,
     output reg signed [`WL-1:0] yo
    );
   
    always@* begin
        if (en == 1) begin
            xo = -xi;
            yo = -yi;
        end else begin 
            xo = xi;
            yo = yi;
        end
    end
    
endmodule

// wrap the regularizing operation
module Row_AngleRegulator
    #(parameter N = 2)
    (input signed [(`WL * N) - 1:0] Hin_x,
     input signed [(`WL * N) - 1:0] Hin_y,
     input signed [`WL-1:0] Yin_x,
     input signed [`WL-1:0] Yin_y,
     output signed [(`WL * N) - 1:0] Hout_x,
     output signed [(`WL * N) - 1:0] Hout_y,
     output signed [`WL-1:0] Yout_x,
     output signed [`WL-1:0] Yout_y
    );
    
    wire signed [`WL-1:0] hin_x[0:N-1];
    wire signed [`WL-1:0] hin_y[0:N-1];
    wire signed [`WL-1:0] hx[0:N-1];
    wire signed [`WL-1:0] hy[0:N-1];
    
    genvar i;  
    generate   // unpacking the arrays
       for (i = 0; i < N; i = i + 1) begin 
           assign hin_x[i] = Hin_x[`WL*i + `WL-1 : `WL*i];
           assign hin_y[i] = Hin_y[`WL*i + `WL-1 : `WL*i];
       end
    endgenerate
    
    // determine whether we need to correct angle
    assign en_rotate = hin_x[0][`WL-1];
    
    // Regularize H
    generate 
       for (i = 0; i < N; i = i + 1) begin
           AngleRegulator AR_H(
               .xi(hin_x[i]), .yi(hin_y[i]),
               .en(en_rotate),
               .xo(hx[i]), .yo(hy[i])
           );
       end
    endgenerate
    
    // Regularize y
    AngleRegulator AR_Y(
               .xi(Yin_x), .yi(Yin_y),
               .en(en_rotate),
               .xo(Yout_x), .yo(Yout_y)
    );
    
    generate   // packing the arrays
       for (i = 0; i < N; i = i + 1) begin 
           assign Hout_x[`WL*i + `WL-1 : `WL*i] = hx[i];
           assign Hout_y[`WL*i + `WL-1 : `WL*i] = hy[i];
       end
    endgenerate
    
endmodule

module RowRotation
	#(parameter N = 8) (
	    input clk, rst,
	    input signed [(`WL * N) - 1:0] Hin_x,
	    input signed [(`WL * N) - 1:0] Hin_y,
	    input signed [`WL-1:0] Yin_x,
	    input signed [`WL-1:0] Yin_y,
	    output signed [(`WL * N) - 1:0] Hout_x,
	    output signed [(`WL * N) - 1:0] Hout_y,
	    output signed [`WL-1:0] Yout_x,
	    output signed [`WL-1:0] Yout_y
	);
	
	wire signed [(`WL * N) - 1:0] Hx_C[0:`CORDIC_iter];
	wire signed [(`WL * N) - 1:0] Hy_C[0:`CORDIC_iter];
	wire signed [`WL-1:0] yx_C[0:`CORDIC_iter];
	wire signed [`WL-1:0] yy_C[0:`CORDIC_iter];
	reg signed [(`WL * N) - 1:0] Hx_FF_0;
	reg signed [(`WL * N) - 1:0] Hy_FF_0;
	reg signed [`WL-1:0] Yx_FF_0;
	reg signed [`WL-1:0] Yy_FF_0;
//	reg signed [(`WL * N) - 1:0] Hx_FF_1;
//	reg signed [(`WL * N) - 1:0] Hy_FF_1;
//	reg signed [`WL-1:0] Yx_FF_1;
//	reg signed [`WL-1:0] Yy_FF_1;
	
	genvar i;
	
	// Regularize H and y
	Row_AngleRegulator #(.N(N)) RowAR(
	    .Hin_x(Hin_x), .Hin_y(Hin_y),
	    .Yin_x(Yin_x), .Yin_y(Yin_y),
	    .Hout_x(Hx_C[0]), .Hout_y(Hy_C[0]),
	    .Yout_x(yx_C[0]), .Yout_y(yy_C[0])
	);
	
	// CORDIC iteration, generate [`CORDIC_iter] Row_CORDICs
	generate
	    // From 0 to BP0-1
	    for (i=0; i < `BP0; i = i + 1) begin
	        Row_CORDIC #(.N(N), .level(i)) u_RowCORDIC_0(
	            .Hin_x(Hx_C[i]), .Hin_y(Hy_C[i]),
	            .Yin_x(yx_C[i]), .Yin_y(yy_C[i]),
	            .Hout_x(Hx_C[i+1]), .Hout_y(Hy_C[i+1]),
	            .Yout_x(yx_C[i+1]), .Yout_y(yy_C[i+1])
	        );
	    end
	    
	    always@(posedge clk or negedge rst) begin      // DFF 1 
	        if (~rst) begin
	            Hx_FF_0 <= 0;
	            Hy_FF_0 <= 0;
	            Yx_FF_0 <= 0;
	            Yy_FF_0 <= 0;
	        end else begin
	            Hx_FF_0 <= Hx_C[`BP0];
	            Hy_FF_0 <= Hy_C[`BP0];
	            Yx_FF_0 <= yx_C[`BP0];
	            Yy_FF_0 <= yy_C[`BP0];
	        end
	    end
	    
	    // BP0 + 1
//	    Row_CORDIC #(.N(N), .level(`BP0)) u_RowCORDIC_1(
//	        .Hin_x(Hx_FF_0), .Hin_y(Hy_FF_0),
//	        .Yin_x(Yx_FF_0), .Yin_y(Yy_FF_0),
//	        .Hout_x(Hx_C[`BP0+1]), .Hout_y(Hy_C[`BP0+1]),
//	        .Yout_x(yx_C[`BP0+1]), .Yout_y(yy_C[`BP0+1])
//	    );
	 
//	    for (i=`BP0+1; i < `BP1; i = i + 1) begin
//	        Row_CORDIC #(.N(N), .level(i)) u_RowCORDIC_2(
//	            .Hin_x(Hx_C[i]), .Hin_y(Hy_C[i]),
//	            .Yin_x(yx_C[i]), .Yin_y(yy_C[i]),
//	            .Hout_x(Hx_C[i+1]), .Hout_y(Hy_C[i+1]),
//	            .Yout_x(yx_C[i+1]), .Yout_y(yy_C[i+1])
//	        );
//	    end
	    
//	    always@(posedge clk or negedge rst) begin      // DFF  
//	        if (~rst) begin
//	            Hx_FF_1 <= 0;
//	            Hy_FF_1 <= 0;
//	            Yx_FF_1 <= 0;
//	            Yy_FF_1 <= 0;
//	        end else begin
//	            Hx_FF_1 <= Hx_C[`BP1];
//	            Hy_FF_1 <= Hy_C[`BP1];
//	            Yx_FF_1 <= yx_C[`BP1];
//	            Yy_FF_1 <= yy_C[`BP1];
//	        end
//	    end
	    
//		Row_CORDIC #(.N(N), .level(`BP1)) u_RowCORDIC_3(
//			.Hin_x(Hx_FF_1), .Hin_y(Hy_FF_1),
//			.Yin_x(Yx_FF_1), .Yin_y(Yy_FF_1),
//			.Hout_x(Hx_C[`BP1+1]), .Hout_y(Hy_C[`BP1+1]),
//			.Yout_x(yx_C[`BP1+1]), .Yout_y(yy_C[`BP1+1])
//		);
	    
	    Row_CORDIC #(.N(N), .level(`BP0)) u_RowCORDIC_3(
	        .Hin_x(Hx_FF_0), .Hin_y(Hy_FF_0),
	        .Yin_x(Yx_FF_0), .Yin_y(Yy_FF_0),
	        .Hout_x(Hx_C[`BP0+1]), .Hout_y(Hy_C[`BP0+1]),
	        .Yout_x(yx_C[`BP0+1]), .Yout_y(yy_C[`BP0+1])
	    );
	    
	    for (i=`BP0+1; i < `CORDIC_iter; i = i + 1) begin
	        Row_CORDIC #(.N(N), .level(i)) u_RowCORDIC_4(
	            .Hin_x(Hx_C[i]), .Hin_y(Hy_C[i]),
	            .Yin_x(yx_C[i]), .Yin_y(yy_C[i]),
	            .Hout_x(Hx_C[i+1]), .Hout_y(Hy_C[i+1]),
	            .Yout_x(yx_C[i+1]), .Yout_y(yy_C[i+1])
	        );
	    end
	endgenerate
	
	Row_Normalization #(.N(N)) u_RowNormalize(
	    .Hin_x(Hx_C[`CORDIC_iter]), .Hin_y(Hy_C[`CORDIC_iter]),
	    .yin_x(yx_C[`CORDIC_iter]), .yin_y(yy_C[`CORDIC_iter]),
	    .Hout_x(Hout_x), .Hout_y(Hout_y),
	    .yout_x(Yout_x), .yout_y(Yout_y)
	);
	
endmodule
