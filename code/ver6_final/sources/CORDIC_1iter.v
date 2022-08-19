`timescale 1ns / 1ps

`include "parameters.v"

module CORDIC_unit
    #(parameter level = 0)
    (input signed [`WL-1:0] xi, signed [`WL-1:0] yi,
     input d,
     output reg signed [`WL-1:0] xo, reg signed [`WL-1:0] yo);

    always@* begin
        case (d)
            0:  begin
                xo = xi - (yi >>> level);
                yo = (xi >>> level) + yi; 
                end
            1:  begin
                xo = xi + (yi >>> level);
                yo = yi - (xi >>> level);
                end
        endcase
    end

endmodule

module Row_CORDIC
    #(parameter N = 2,
      parameter level = 0)
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
    wire signed [`WL-1:0] hout_x[0:N-1];
    wire signed [`WL-1:0] hout_y[0:N-1];
    wire d;
    
    genvar i;
    generate   // unpacking the arrays
        for (i = 0; i < N; i = i + 1) begin 
            assign hin_x[i] = Hin_x[`WL*i + `WL-1 : `WL*i];
            assign hin_y[i] = Hin_y[`WL*i + `WL-1 : `WL*i];
        end
    endgenerate
    
    assign d = (hin_y[0] < 0)? 0: 1;     // direction indication
    
    generate   // rotate the x and y on the row of H one time
        for (i = 0; i < N; i = i + 1) begin
            CORDIC_unit #(.level(level)) u_H_CORDIC(
                .xi(hin_x[i]),  .yi(hin_y[i]), .d(d), 
                .xo(hout_x[i]), .yo(hout_y[i])
            );
       end
    endgenerate
    
    // rotate Y
    CORDIC_unit #(.level(level)) u_y_CORDIC(
        .xi(Yin_x),  .yi(Yin_y), .d(d), 
        .xo(Yout_x), .yo(Yout_y)
    );
    
    generate   // packing the arrays
        for (i = 0; i < N; i = i + 1) begin 
            assign Hout_x[`WL*i + `WL-1 : `WL*i] = hout_x[i];
            assign Hout_y[`WL*i + `WL-1 : `WL*i] = hout_y[i];
        end
    endgenerate
    
endmodule