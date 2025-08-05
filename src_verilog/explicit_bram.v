/*********************************************************************
 * Module: bram [explicit]
 * Author: Allyn Loyd
 * Date: 2025-08-05
 * Description: Interface for interacting with all BRAM blocks (explicitly instantiated)
 *********************************************************************/

`ifndef BRAM_INCLUDE_FILE
    `define BRAM_INCLUDE_FILE "build/generated_rams.vh"
`endif

 /**
 * @brief Interface for interacting with all BRAM modules (explicitly instantiated)
 *
 * @tparams:
 *   NUM_BLOCKS     - the number of EBRs to instantiate
 *
 * @inputs:
 *   clk            - system clock
 *   rd_en          - enable reading
 *   wr_en          - enable writing
 *   rd_addr        - the address to read from (highest bits are the EBR select)
 *   wr_addr        - the address to write to (highest bits are the EBR select)
 *   data_in        - the data to write to memeory
 *
 * @outputs:
 *   data_out       - the data read from memory
 *
 */
module bram(input wire clk, 
            input wire rd_en, 
            input wire wr_en, 
            input wire [7 + NUM_BITS:0] rd_addr, 
            input wire [7 + NUM_BITS:0] wr_addr, 
            input wire [15:0] data_in, 
            output wire [15:0] data_out
);
parameter NUM_BLOCKS = 16;
localparam NUM_BITS = $clog2(NUM_BLOCKS);

// extract the EBR index from the address
// avoid syntax errors if only 1 block is requested
wire [NUM_BITS-1:0] rd_select = (NUM_BITS == 0) ? 1'b0 : rd_addr[7 + NUM_BITS:8];
wire [NUM_BITS-1:0] wr_select = (NUM_BITS == 0) ? 1'b0 : wr_addr[7 + NUM_BITS:8];

// each block needs its own output
wire [15:0] data_outs[0:NUM_BLOCKS-1];
// select the correct block output for the module output
assign data_out = data_outs[rd_select];

`include `BRAM_INCLUDE_FILE

// a bunch of SB_RAM40_4K instantiations that look something like:
// (* BEL = "X6/Y1/ram" *)
// SB_RAM40_4K #(
//     .INIT_FILE("build/data/0.hex"),
//     .READ_MODE(0),
//     .WRITE_MODE(0)
// ) ram_inst_0 (
//     .RDATA(data_outs[0]),
//     .RADDR({3'b000, rd_addr[7:0]}),
//     .WADDR({3'b000, wr_addr[7:0]}),
//     .MASK(16'b0),
//     .WDATA(data_in),
//     .RCLKE(1'b1),
//     .RCLK(clk),
//     .RE(rd_en),
//     .WCLKE(1'b1),
//     .WCLK(clk),
//     .WE(wr_en && (wr_select == 0))
// );

// read/write mode make it 20 it is 256 x 16 bits
// memory is dual port
// mask is active low

endmodule