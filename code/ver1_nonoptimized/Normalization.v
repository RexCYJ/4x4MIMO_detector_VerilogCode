`timescale 1ns / 1ps

`include "parameters.v"

module Normalization_unit (
     input signed [`WL-1:0] in,
     output reg signed [`WL-1:0] out
    );
    
    always@* begin
        out =  (in >>> 12)
             + (in >>> 11)
             + (in >>> 10)
             + (in >>> 8)
             + (in >>> 7)
             + (in >>> 5)
             + (in >>> 4)
             + (in >>> 1);
    end

endmodule

module Row_Normalization
    #(parameter N = 1)
    (input signed [(`WL * N) - 1:0] Hin_x,
     input signed [(`WL * N) - 1:0] Hin_y,
     input signed [`WL-1:0] yin_x,
     input signed [`WL-1:0] yin_y,
     output signed [(`WL * N) - 1:0] Hout_x,
     output signed [(`WL * N) - 1:0] Hout_y,
     output signed [`WL-1:0] yout_x,
     output signed [`WL-1:0] yout_y
    );
    
    wire signed [`WL-1:0] hin_x[0:N-1];
    wire signed [`WL-1:0] hin_y[0:N-1];
    wire signed [`WL-1:0] hout_x[0:N-1];
    wire signed [`WL-1:0] hout_y[0:N-1];
    
    genvar i;
    generate   // unpacking the arrays
        for (i = 0; i < N; i = i + 1) begin 
            assign hin_x[i] = Hin_x[`WL*i + `WL-1 : `WL*i];
            assign hin_y[i] = Hin_y[`WL*i + `WL-1 : `WL*i];
        end
    endgenerate
    
    generate   // normalize hx
        for (i = 0; i < N; i = i + 1) begin
            Normalization_unit uhx(
                .in(hin_x[i]), .out(hout_x[i]));
        end
    endgenerate
    
    generate   // normalize hy
        for (i = 0; i < N; i = i + 1) begin
            Normalization_unit uhy(
                .in(hin_y[i]), .out(hout_y[i]));
        end
    endgenerate
    
    // normalize Y
    Normalization_unit uyx(.in(yin_x), .out(yout_x));
    Normalization_unit uyy(.in(yin_y), .out(yout_y));
    
    generate   // packing the arrays
        for (i = 0; i < N; i = i + 1) begin
            assign Hout_x[`WL*i + `WL-1 : `WL*i] = hout_x[i];
            assign Hout_y[`WL*i + `WL-1 : `WL*i] = hout_y[i];
        end
    endgenerate
    
endmodule
