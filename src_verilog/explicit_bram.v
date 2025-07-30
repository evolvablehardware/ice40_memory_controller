`ifndef BRAM_INCLUDE_FILE
    `define BRAM_INCLUDE_FILE "build/generated_rams.vh"
`endif

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

wire [NUM_BITS-1:0] rd_select = (NUM_BITS == 0) ? 1'b0 : rd_addr[7 + NUM_BITS:8];
wire [NUM_BITS-1:0] wr_select = (NUM_BITS == 0) ? 1'b0 : wr_addr[7 + NUM_BITS:8];
wire [15:0] data_outs[0:NUM_BLOCKS-1];
assign data_out = data_outs[rd_select];

`include `BRAM_INCLUDE_FILE


endmodule