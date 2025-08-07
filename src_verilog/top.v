`ifndef NUM_BLOCKS_PARAM
    `define NUM_BLOCKS_PARAM 30
`endif

`ifndef CLOCK_SPEED
    `define CLOCK_SPEED 48_000_000
`endif

module top (
input               clk     , // Top level system clock input.
input   wire        uart_rxd, // UART Recieve pin.
input resetn,
output  wire        uart_txd,  // UART transmit pin.
output wire [2:0] leds
);

// Clock frequency in hertz.
parameter CLK_HZ = `CLOCK_SPEED;
parameter BIT_RATE =   115200;
parameter PAYLOAD_BITS = 8;

// Number of EBRs to initialize
parameter NUM_BLOCKS = `NUM_BLOCKS_PARAM;
localparam NUM_BITS = $clog2(NUM_BLOCKS);

// wires for BRAM
wire [NUM_BITS-1:0] mem_select;
wire [7:0] ib_addr;
wire [15:0] ib_data_out;
wire [15:0] ib_data_in;
wire rd_en;
wire wr_en;

wire [13:0] sp_addr;
wire [15:0] sp_data_out;

wire bram_or_spram;
wire [15:0] data_out;

assign data_out = (bram_or_spram == 0) ? ib_data_out : sp_data_out;

//-------------------------------------------------------------------------
// Controller + UART
//-------------------------------------------------------------------------
uart_controller #(
    .MEM_SELECT_BITS(NUM_BITS),
    .CLK_HZ(CLK_HZ),
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS)
) uart_controller_inst (
    .clk(clk),
    .uart_rxd(uart_rxd),
    .uart_txd(uart_txd),
    .resetn(resetn),
    .mem_out(data_out),
    .mem_select(mem_select),
    .mem_addr(ib_addr),
    .mem_in(ib_data_in),
    .rd_en(rd_en),
    .wr_en(wr_en),
    .leds(leds),
    .bram_or_spram(bram_or_spram),
    .sp_addr(sp_addr)
);

//-------------------------------------------------------------------------
// Memory blocks
//-------------------------------------------------------------------------
// only pass one of implicit_bram.v or explicit_bram.v into yosys
bram #(.NUM_BLOCKS(NUM_BLOCKS)) bram_inst (
.clk(clk), 
.rd_en(rd_en), 
.wr_en(wr_en && (bram_or_spram == 0)), 
.rd_addr({mem_select, ib_addr}), 
.wr_addr({mem_select, ib_addr}), 
.data_in(ib_data_in), 
.data_out(ib_data_out)
);

//-------------------------------------------------------------------------
// SPRAM
//-------------------------------------------------------------------------
`ifdef USE_SPRAM
    spram spram_inst (
    .clk(clk),  
    .wr_en(wr_en && (bram_or_spram == 1)), 
    .cs(mem_select[1:0]),
    .addr(sp_addr), 
    .data_in(ib_data_in), 
    .data_out(sp_data_out)
    );
`endif



endmodule