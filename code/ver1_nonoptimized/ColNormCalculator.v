`timescale 1ns / 1ps

`include "parameters.v"

module ColNormCalculator(
        input signed [(8*8*`WL)-1:0] Hmatrix,
        output [(8*`COLNORM_WL)-1:0] colnorm
    );
    
    wire signed [`WL-1:0] h_wl[0:7][0:7];
    wire signed [`COLNORM_WL-1:0] h[0:7][0:7];
    wire [2*`COLNORM_WL:0] hsq_2l[0:7][0:7];
    wire [`COLNORM_WL:0] hsq[0:7][0:7];
    wire [`COLNORM_WL-1:0] norm[0:7];
    
    genvar i, j;
    generate    // unpacking input and packing output
        for (i = 0; i < 8; i = i+1) begin
            for (j = 0; j < 8; j = j+1) begin
                assign h_wl[i][j] = Hmatrix[i*8*`WL + j*`WL + `WL-1:i*8*`WL + j*`WL];
                assign h[i][j] = h_wl[i][j] >>> (`FWL - `COLNORM_FWL);
//                        = (Hmatrix[i*8*`WL + j*`WL + `WL-1:i*8*`WL + j*`WL] >>> (`FWL - `COLNORM_FWL));
            end
            assign colnorm[i*`COLNORM_WL + `COLNORM_WL-1:i*`COLNORM_WL] = norm[i];
        end
    endgenerate
    
    generate    // add up column norm
        for (i = 0; i < 8; i = i+1) begin
            for (j = 0; j < 8; j = j+1) begin
                assign hsq_2l[i][j] = h[i][j] * h[i][j];
                assign hsq[i][j] = hsq_2l[i][j] >>> `COLNORM_FWL;
            end
            assign norm[i] = hsq[0][i] + hsq[1][i] + hsq[2][i] + hsq[3][i]
                           + hsq[4][i] + hsq[5][i] + hsq[6][i] + hsq[7][i];
        end
    endgenerate    
    
endmodule
