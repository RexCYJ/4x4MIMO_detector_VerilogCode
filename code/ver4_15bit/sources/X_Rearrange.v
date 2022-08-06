`timescale 1ns / 1ps

module X_Rearrange(
        input  [8 * 2 - 1:0] Xi,
        input  [8 * 3 - 1:0] colorder,
        output [8 * 2 - 1:0] Xo
    );
    
    wire [1:0] xi[7:0];
    wire [2:0] order[7:0];
    reg  [1:0] xo[7:0];
    
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            assign xi[i] = Xi[(i+1) * 2 - 1:i * 2];
            assign order[i] = colorder[(i+1) * 3 - 1:i * 3];
            always@ * begin
//                if (i == order[0]) begin
//                    xo[i] = xi[0];
//                end else if (i == order[1]) begin
//                    xo[i] = xi[1];
//                end else if (i == order[2]) begin
//                    xo[i] = xi[2];
//                end else if (i == order[3]) begin
//                    xo[i] = xi[3];
//                end else if (i == order[4]) begin
//                    xo[i] = xi[4];
//                end else if (i == order[5]) begin
//                    xo[i] = xi[5];
//                end else if (i == order[6]) begin
//                    xo[i] = xi[6];
//                end else if (i == order[7]) begin
//                    xo[i] = xi[7];
//                end
                
                case (i)
                    order[0]: xo[i] = xi[0];
                    order[1]: xo[i] = xi[1];
                    order[2]: xo[i] = xi[2];
                    order[3]: xo[i] = xi[3];
                    order[4]: xo[i] = xi[4];
                    order[5]: xo[i] = xi[5];
                    order[6]: xo[i] = xi[6];
                    order[7]: xo[i] = xi[7];
                endcase
            end
        end
    endgenerate
    
    assign Xo = {xo[7], xo[6], xo[5], xo[4], xo[3], xo[2], xo[1], xo[0]};
    
endmodule
