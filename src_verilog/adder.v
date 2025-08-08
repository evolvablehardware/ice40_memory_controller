/*********************************************************************
 * Module: adder
 * Author: Allyn Loyd
 * Date: 2025-08-08
 * Description: Sets block 0, address 2 of BRAM to the value stored at block 0, address 1 + 5 
 *********************************************************************/

 /**
 * @brief Sets block 0, address 2 of BRAM to the value stored at block 0, address 1 + 5.
 *
 * @tparams:
 *   MEM_SELECT_BITS - the number of bits needed to specify which block we want to write/read from
 *
 * @inputs:
 *   mem_data_out        - the data read from BRAM
 *
 * @outputs:
 *   mem_select     - the EBR to read from/write to
 *   rd_addr        - the BRAM address to read from
 *   wr_addr        - the BRAM address to write to
 *   data_in        - the data to write to BRAM
 *   rd_en          - enable reading from BRAM
 *   wr_en          - enable writing to BRAM  
 *   bram_or_spram  - 0 if doing a BRAM operation, 1 for SPRAM
 *
 */
module adder(
    input [15:0] mem_data_out,
    output [MEM_SELECT_BITS-1:0] mem_select,
    output [7:0] rd_addr,
    output [7:0] wr_addr,
    output [15:0] data_in,
    output rd_en,
    output wr_en,
    output bram_or_spram
);
parameter MEM_SELECT_BITS = 4;

// use block 0
assign mem_select = 0;

// read address 1
assign rd_addr = 8'd1;

// write to address 2
assign wr_addr = 8'd2;

// bram[0][2] = bram[0][1] + 5
assign data_in = mem_data_out + 16'd5;

// enable reading and writing
assign rd_en = 1'b1;
assign wr_en = 1'b1;

// use bram
assign bram_or_spram = 1'b0;

endmodule