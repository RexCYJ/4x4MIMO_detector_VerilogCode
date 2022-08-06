`timescale 1ns / 1ps



module tb_ColNormUpdate(
        
    );
    
    ColumnNormUpdate #(.N(3)) u_test(
        .Harray_i(),           // h_j,j+1, h_j,j+2, ..., h_j,7               
        .colnorm_i(),
        .colnorm_o()
    );
    
endmodule
