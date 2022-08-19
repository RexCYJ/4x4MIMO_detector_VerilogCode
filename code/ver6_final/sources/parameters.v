`timescale 1ns / 1ps

`define PACK_ARRAY(PK_WIDTH,PK_LEN,PK_SRC,PK_DEST)    genvar pk_idx; generate for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) begin; assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; end; endgenerate
`define UNPACK_ARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC)  genvar unpk_idx; generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) begin; assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; end; endgenerate

`define GADD(LEVEL) ((16 - (LEVEL)) * ((LEVEL) + 1) / 2)	// Gaussian sum

`define InWL        16  // In word length
`define WL          16  // General word length
`define FWL         12  // General fractional word length
`define ERR_WL      16  // PED error word length
`define ERR_FWL     12  // PED error fractional word length 
`define COLNORM_WL  11   // column norm word length
`define COLNORM_FWL 7   // column norm fractional word length
//`define CORDIC_WL   16
`define CORDIC_iter 9   // number of CORDIC iteration

// FWL = 12
`define C0  (-16'd3886) // unused value of possible solution
`define C1  (-16'd1295)
`define C2   (16'd1295)
`define C3   (16'd3886)

// FWL = 11
//`define C0  (-16'd1943) // unused value of possible solution
//`define C1  (-16'd648)
//`define C2   (16'd648)
//`define C3   (16'd1943)
