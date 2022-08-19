`timescale 1ns / 1ps

`include "parameters.v"

// InWL less than 16 bits
//module TopInterface(
//        input clk, rst,
//        input signed [`InWL - 1:0]       In0,
//        input signed [`InWL - 1:0]       In1,
//        input signed [`InWL - 1:0]       In2,
//        input signed [`InWL - 1:0]       In3,
//        output [8 * 2 - 1:0]    X 
//    );
    
//    reg [4:0] cnt_reg;
//    reg [4:0] cnt;
//    reg [4 * `InWL - 1:0]     BUFFER1[8:0];
//    reg [4 * `InWL - 1:0]     BUFFER2[8:0];
//    reg [64 * `InWL - 1:0]    Hmat;
//    reg [64 * `InWL - 1:0]    Hmat_reg;
//    reg [8 * `InWL - 1:0]     Yarr;
//    reg [8 * `InWL - 1:0]     Yarr_reg;
    
//    always@ (posedge clk or negedge rst) begin 
//        if (~rst) begin
//            BUFFER1[0] <= 0;
//            BUFFER2[0] <= 0; 
//        end else begin
//            BUFFER1[0] <= {In3, In2, In1, In0};
//            BUFFER2[0] <= {-In2, In3, -In0, In1};
//        end
//    end
            
//    genvar i;
//    generate
//        for (i = 0; i < 8; i = i + 1) begin
//            always @ (posedge clk or negedge rst) begin 
//                if (~rst) begin
//                    BUFFER1[i + 1] <= 0;
//                    BUFFER2[i + 1] <= 0; 
//                end else begin
//                    BUFFER1[i + 1] <= BUFFER1[i];
//                    BUFFER2[i + 1] <= BUFFER2[i];
//                end
//            end     
//        end
//    endgenerate
    
//    always@* begin 
//        if (cnt_reg < 5'd9) begin
//            cnt = cnt_reg + 1;
//            Hmat = Hmat_reg;
//            Yarr = Yarr_reg;
//        end else begin
//            cnt = 0; 
//            Hmat = {BUFFER1[8], BUFFER1[7], 
//                    BUFFER2[8], BUFFER2[7], 
//                    BUFFER1[6], BUFFER1[5], 
//                    BUFFER2[6], BUFFER2[5], 
//                    BUFFER1[4], BUFFER1[3], 
//                    BUFFER2[4], BUFFER2[3], 
//                    BUFFER1[2], BUFFER1[1], 
//                    BUFFER2[2], BUFFER2[1]};
//            Yarr = {BUFFER1[0], In3, In2, In1, In0};
//        end
//    end
    
//    always @ (posedge clk or negedge rst) begin
//        if (~rst) begin
//            cnt_reg <= 0;
//            Hmat_reg <= 0;
//            Yarr_reg <= 0;
//        end else begin
//            cnt_reg <= cnt;
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

// InWL 16 bits or more
// consume 14 cycles to read in a batch of data 
module TopInterface_2(
        input clk, rst,
        input signed [`InWL - 1:0]	In0,
        input signed [`InWL - 1:0]	In1,
        input signed [`InWL - 1:0]	In2,
        output [8 * 2 - 1:0]    X 
    );
    
	reg  		[4:0]				cnt_reg;
	reg  		[4:0] 				cnt;
	reg  signed	[`InWL - 1:0]		BUFFER[41:0];
	wire signed [`WL - 1:0]			h[0:7][0:7];
	wire signed [`WL - 1:0]			y[0:7];
	wire 		[64 * `WL - 1:0]	Hmat_temp;
	wire 		[8 * `WL - 1:0]		Yarr_temp;
	reg  		[64 * `WL - 1:0]	Hmat;
	reg  		[64 * `WL - 1:0]	Hmat_reg;
	reg  		[8 * `WL - 1:0]		Yarr;
	reg  		[8 * `WL - 1:0]		Yarr_reg;
    
	always@ (posedge clk or negedge rst) begin 
		if (~rst) begin
			BUFFER[0] <= 0;
			BUFFER[1] <= 0;
			BUFFER[2] <= 0;
		end else begin
			BUFFER[0] <= In0;
			BUFFER[1] <= In1;
			BUFFER[2] <= In2;
		end
	end
            
	genvar i, j;
	generate
		// buffer the inputs
		for (i = 0; i <= 36; i = i + 3) begin
			always@ (posedge clk or negedge rst) begin 
				if (~rst) begin
					BUFFER[i + 3] <= 0;
					BUFFER[i + 4] <= 0;
					BUFFER[i + 5] <= 0;
				end else begin
					BUFFER[i + 3] <= BUFFER[i + 0];
					BUFFER[i + 4] <= BUFFER[i + 1];
					BUFFER[i + 5] <= BUFFER[i + 2];
				end
			end
		end
		// assign h and y
		for (i = 0; i < 4; i = i + 1) begin
			for (j = 0; j < 4; j = j + 1) begin
				assign h[2 * i][2 * j] 			=  BUFFER[i * 8 + 2 * j + 1 + 10];
				assign h[2 * i][2 * j + 1] 		= -BUFFER[i * 8 + 2 * j + 10];
				assign h[2 * i + 1][2 * j] 		=  BUFFER[i * 8 + 2 * j + 10];
				assign h[2 * i + 1][2 * j + 1] 	=  BUFFER[i * 8 + 2 * j + 1 + 10];
			end
		end
		for (i = 0; i < 8; i = i + 1) begin
			assign y[i] = BUFFER[i + 2];
		end
		// pack up H and Y
		for (i = 0; i < 8; i = i + 1) begin
			for (j = 0; j < 8; j = j + 1) begin
				assign Hmat_temp[i * 8 * `WL + j * `WL + `WL - 1: i * 8 * `WL + j * `WL] = h[i][j]; 
			end
		end
		assign Yarr_temp = {y[7], y[6], y[5], y[4], y[3], y[2], y[1], y[0]}; 
	endgenerate
    
	always@* begin 
		if (cnt_reg < 5'd13) begin
			cnt = cnt_reg + 1;
			Hmat = Hmat_reg;
			Yarr = Yarr_reg;
		end else begin
			cnt = 0; 
			Hmat = Hmat_temp;
			Yarr = Yarr_temp;
		end
	end
	
	always @ (posedge clk or negedge rst) begin
	    if (~rst) begin
	        cnt_reg	 <= 5'd13;
	        Hmat_reg <= 0;
	        Yarr_reg <= 0;
	    end else begin
	        cnt_reg  <= cnt;
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
