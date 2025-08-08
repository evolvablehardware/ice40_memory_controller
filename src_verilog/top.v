`ifndef NUM_BLOCKS_PARAM
    `define NUM_BLOCKS_PARAM 16
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
wire [7:0] rd_addr;
wire [7:0] wr_addr;
wire [15:0] b_data_out;
wire [15:0] data_in;
wire rd_en;
wire wr_en;
wire [13:0] sp_addr;
wire [15:0] sp_data_out;
wire bram_or_spram;
wire [15:0] data_out;

assign data_out = (bram_or_spram == 0) ? b_data_out : sp_data_out;

// wires for controller
wire [NUM_BITS-1:0] controller_mem_select;
wire [7:0] controller_addr;
wire [15:0] controller_data_in;
wire controller_rd_en;
wire controller_wr_en;
wire controller_bram_or_spram;
wire active;

// wires for adder
wire [NUM_BITS-1:0] adder_mem_select;
wire [7:0] adder_rd_addr;
wire [7:0] adder_wr_addr;
wire [15:0] adder_data_in;
wire adder_rd_en;
wire adder_wr_en;
wire adder_bram_or_spram;

// if the controller is not active, then:
// block 0, addr 2 of BRAM = block 0, addr 1 of BRAM + 5

// interpret each line as:
// if the memeory controller is in the actively doing an operation, use its control signals. 
// Otherwise, use the memory control signal provided by the adder module.
assign mem_select = (active == 0) ? adder_mem_select : controller_mem_select;
assign rd_addr = (active == 0) ? adder_rd_addr : controller_addr;
assign wr_addr = (active == 0) ? adder_wr_addr : controller_addr;
assign data_in = (active == 0) ? adder_data_in : controller_data_in;
assign rd_en = (active == 0) ? adder_rd_en : controller_rd_en;
assign wr_en = (active == 0) ? adder_wr_en : controller_wr_en;
assign bram_or_spram = (active == 0) ? adder_bram_or_spram : controller_bram_or_spram;

//-------------------------------------------------------------------------
// Adder (replace with neural network)
//-------------------------------------------------------------------------
adder #(.MEM_SELECT_BITS(NUM_BITS)) adder_inst (
    .mem_data_out(data_out),
    .mem_select(adder_mem_select),
    .rd_addr(adder_rd_addr),
    .wr_addr(adder_wr_addr),
    .data_in(adder_data_in),
    .rd_en(adder_rd_en),
    .wr_en(adder_wr_en),
    .bram_or_spram(adder_bram_or_spram)
);

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
    .mem_select(controller_mem_select),
    .mem_addr(controller_addr),
    .mem_in(controller_data_in),
    .rd_en(controller_rd_en),
    .wr_en(controller_wr_en),
    .leds(leds),
    .bram_or_spram(controller_bram_or_spram),
    .sp_addr(sp_addr),
    .active(active)
);

//-------------------------------------------------------------------------
// Memory blocks
//-------------------------------------------------------------------------
// only pass one of implicit_bram.v or explicit_bram.v into yosys
bram #(.NUM_BLOCKS(NUM_BLOCKS)) bram_inst (
.clk(clk), 
.rd_en(rd_en), 
.wr_en(wr_en && (bram_or_spram == 0)), 
.rd_addr({mem_select, rd_addr}), 
.wr_addr({mem_select, wr_addr}), 
.data_in(data_in), 
.data_out(b_data_out)
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
    .data_in(data_in), 
    .data_out(sp_data_out)
    );
`endif



endmodule