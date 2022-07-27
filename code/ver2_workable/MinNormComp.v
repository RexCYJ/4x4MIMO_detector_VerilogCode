`timescale 1ns / 1ps

`include "parameters.v"

module MinNorm_unit(
        input [`COLNORM_WL-1:0] norm1,
        input [2:0] idx1,
        input [`COLNORM_WL-1:0] norm2,
        input [2:0] idx2,
        output reg [`COLNORM_WL-1:0] norm_o,
        output reg [2:0] idx_o
    );
    
    always@* begin
        if (norm1 < norm2) begin
            norm_o <= norm1;
            idx_o <= idx1;
        end else if (norm1 > norm2) begin
            norm_o <= norm2;
            idx_o <= idx2;
        end else begin
            if (idx1 < idx2) begin
                norm_o <= norm1;
                idx_o <= idx1;
            end else begin
                norm_o <= norm2;
                idx_o <= idx2;
            end
        end
    end
    
endmodule

module MinNormComp
    #(parameter N = 2)(
        input [(N*`COLNORM_WL) - 1:0] colnorm_i, // [[7] [6] ... [8-N]]
        output [2:0] mincol
    );

    wire [`COLNORM_WL-1:0] colnorm[2*(N-1):0];
    wire [2:0] colidx[2*(N-1):0];
    
    genvar i;
    generate    // unpack colnorm_i, and assign column index to colidx
        for (i = 0; i < N; i = i + 1) begin
            assign colnorm[i] = colnorm_i[(i+1)*`COLNORM_WL - 1:i*`COLNORM_WL];
            assign colidx[i] = 8 - N + i;
        end
    endgenerate

    generate    // connect the N-1 comparators to find the minimun norm
        for (i = 0; i < N-1; i = i + 1) begin
            MinNorm_unit uMinUnit(
                         .norm1(colnorm[i*2]), .idx1(colidx[i*2]),
                         .norm2(colnorm[i*2+1]), .idx2(colidx[i*2+1]),
                         .norm_o(colnorm[i+N]), .idx_o(colidx[i+N]));
        end
    endgenerate

    assign mincol = colidx[2*(N-1)];

endmodule
