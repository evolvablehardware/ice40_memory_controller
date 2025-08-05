/*********************************************************************
 * Module: bram [implicit]
 * Author: Allyn Loyd
 * Date: 2025-08-05
 * Description: Interface for interacting with all BRAM blocks (implicitly instantiated)
 *********************************************************************/

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
            output reg [15:0] data_out
);
parameter NUM_BLOCKS = 16;
localparam NUM_BITS = $clog2(NUM_BLOCKS);

// instantiate all blocks as one big array and let yosys handle how they're split up
reg [15:0] memory [0:256*NUM_BLOCKS - 1];

// use a hex file to init memory
initial begin
   $readmemh("build/data.hex", memory);
end

// dual port memory
// we can do a read and write at each clock cycle
always @(posedge clk)
begin
   if(wr_en) begin
      memory[wr_addr] <= data_in;
   end
   if (rd_en) begin
      data_out <= memory[rd_addr];
   end
end
endmodule