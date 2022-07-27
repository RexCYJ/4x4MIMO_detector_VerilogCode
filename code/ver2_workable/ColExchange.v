`timescale 1ns / 1ps

`include "parameters.v"

module ColExchange
    #(parameter TARCOL = 0) (
        input [2:0] mincol,
        input [(64*`WL)-1:0] Hmatrix_i,
        input [((8-TARCOL)*`COLNORM_WL) - 1:0] colnorm_i,
        input [(8-TARCOL)*3 - 1:0] colorder_i,
        output [(64*`WL)-1:0] Hmatrix_o,
        output [((8-TARCOL)*`COLNORM_WL) - 1:0] colnorm_o,
        output [(8-TARCOL)*3 - 1:0] colorder_o
    );
    
    wire [8*`WL - 1:0] Hcol_i[0:7];
    wire [`COLNORM_WL-1:0] norm_i[TARCOL:7];
    wire [2:0] order_i[TARCOL:7];
    reg [8*`WL - 1:0] Hcol_o[0:7];
    reg [`COLNORM_WL-1:0] norm_o[TARCOL:7];
    reg [2:0] order_o[TARCOL:7];
    
    genvar i, j;
    
    generate    // separate matrix H into column vectors
        for (i = 0; i < 8; i = i+1) begin
            for (j = 0; j < 8; j = j+1) begin
                assign Hcol_i[j][i*`WL + `WL-1:i*`WL] 
                       = Hmatrix_i[i*8*`WL + j*`WL + `WL-1:i*8*`WL + j*`WL];                
            end 
        end
        for (i = 0; i < 8-TARCOL; i = i+1) begin
            assign norm_i[i+TARCOL] = colnorm_i[`COLNORM_WL*i + `COLNORM_WL-1: `COLNORM_WL*i];
            assign order_i[i+TARCOL] = colorder_i[3*i + 2: 3*i];
        end
    endgenerate
    
    generate    // assign the frozen column
        for (j = 0; j < TARCOL; j = j+1) begin
            always@ * begin
                Hcol_o[j] = Hcol_i[j];
//                norm_o[j] = norm_i[j];
//                order_o[j] = order_i[j];
            end 
        end
    endgenerate
    
    always@* begin  // put the mincol to the target column
        case(mincol)
            3'd0:   begin 
                        Hcol_o[TARCOL]   = Hcol_i[0];
                        if (TARCOL <= 0) begin
                            norm_o[TARCOL]  =  norm_i[0];
                            order_o[TARCOL] = order_i[0];
                        end
                    end
            3'd1:   begin 
                        Hcol_o[TARCOL]   = Hcol_i[1];
                        if (TARCOL <= 1) begin
                            norm_o[TARCOL]  =  norm_i[1];
                            order_o[TARCOL] = order_i[1];
                        end
                    end
            3'd2:   begin 
                        Hcol_o[TARCOL]   = Hcol_i[2];
                        if (TARCOL <= 2) begin
                            norm_o[TARCOL]  =  norm_i[2];
                            order_o[TARCOL] = order_i[2];
                        end
                    end
            3'd3:   begin 
                        Hcol_o[TARCOL]   = Hcol_i[3];
                        if (TARCOL <= 3) begin
                            norm_o[TARCOL]  =  norm_i[3];
                            order_o[TARCOL] = order_i[3];
                        end
                    end
            3'd4:   begin 
                        Hcol_o[TARCOL]   = Hcol_i[4];
                        if (TARCOL <= 4) begin
                            norm_o[TARCOL]  =  norm_i[4];
                            order_o[TARCOL] = order_i[4];
                        end
                    end
            3'd5:   begin 
                        Hcol_o[TARCOL]   = Hcol_i[5];
                        if (TARCOL <= 5) begin
                            norm_o[TARCOL]  =  norm_i[5];
                            order_o[TARCOL] = order_i[5];
                        end
                    end
            3'd6:   begin 
                        Hcol_o[TARCOL]   = Hcol_i[6];
                        if (TARCOL <= 6) begin
                            norm_o[TARCOL]  =  norm_i[6];
                            order_o[TARCOL] = order_i[6];
                        end
                    end
            3'd7:   begin 
                        Hcol_o[TARCOL]   = Hcol_i[7];
                        norm_o[TARCOL]   = norm_i[7];
                        order_o[TARCOL] = order_i[7];
                    end
        endcase
    end
    
    generate    // assign the rest column from TARCOL+1 Col to 8th Col
        for (j = TARCOL+1; j < 8; j = j+1) begin
            always@ * begin
                if (j == mincol) begin
                    Hcol_o[j]   = Hcol_i[TARCOL];
                    norm_o[j]   = norm_i[TARCOL];
                    order_o[j] = order_i[TARCOL];
                end else begin
                    Hcol_o[j]   = Hcol_i[j];
                    norm_o[j]   = norm_i[j];
                    order_o[j] = order_i[j];
                end
            end 
        end
    endgenerate
    
    generate    // packing column vectors to Hmatrix
        for (i = 0; i < 8; i = i+1) begin
            for (j = 0; j < 8; j = j+1) begin
                assign Hmatrix_o[i*8*`WL + j*`WL + `WL-1: i*8*`WL + j*`WL]
                       = Hcol_o[j][i*`WL + `WL-1: i*`WL];
            end 
//            assign colnorm_o[`COLNORM_WL*i + `COLNORM_WL-1: `COLNORM_WL*i] = norm_o[i];
//            assign colorder_o[3*i + 2: 3*i] = order_o[i];
        end
        for (i = 0; i < 8-TARCOL; i = i+1) begin
            assign colnorm_o[`COLNORM_WL*i + `COLNORM_WL-1: `COLNORM_WL*i] = norm_o[i+TARCOL];
            assign colorder_o[3*i + 2: 3*i] = order_o[i+TARCOL];
        end
    endgenerate
    
endmodule
