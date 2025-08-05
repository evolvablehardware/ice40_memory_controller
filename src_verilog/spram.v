/*********************************************************************
 * Module: spram
 * Author: Allyn Loyd
 * Date: 2025-08-05
 * Description: Interface for interacting with all SPRAM blocks. Only can be used with the UP5K devices
 *********************************************************************/

 /**
 * @brief Interface for interacting with all SPRAM blocks. Only can be used with the UP5K devices
 *
 * @tparams:
 *   NUM_BLOCKS     - the number of EBRs to instantiate
 *
 * @inputs:
 *   clk            - system clock
 *   wr_en          - enable writing
 *   cs             - chip select for which block to use
 *   addr           - the address to read from or write to
 *   data_in        - the data to write to memeory
 *
 * @outputs:
 *   data_out       - the data read from memory
 *
 */
module spram(input wire clk, 
            input wire wr_en, 
            input wire [1:0] cs,
            input wire [13:0] addr,  
            input wire [15:0] data_in, 
            output wire [15:0] data_out
);

wire [15:0] data_outs[3:0];
assign data_out = data_outs[cs];

// UP5K has 4 blocks of SPRAM
genvar i;
generate
    for(i = 0; i < 4; i = i + 1) begin
        SB_SPRAM256KA spram_inst (
            .ADDRESS(addr),
            .DATAIN(data_in),
            // SPRAM supports selectively writing to each nibble
            .MASKWREN(4'b1111),
            .WREN(wr_en && (cs == i[1:0])),
            .CHIPSELECT(cs == i[1:0]),
            .CLOCK(clk),
            .STANDBY(1'b0),
            .SLEEP(1'b0),
            // active low
            .POWEROFF(1'b1),
            .DATAOUT(data_outs[i[1:0]])
        );
    end
endgenerate

endmodule