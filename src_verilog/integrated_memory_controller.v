`ifndef NUM_BLOCKS_PARAM
    `define NUM_BLOCKS_PARAM 16
`endif

`ifndef CLOCK_SPEED
    `define CLOCK_SPEED 12_000_000
`endif

module integrated_memory_controller (
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
parameter NUM_BITS = $clog2(NUM_BLOCKS);

// wires for receiver
wire [PAYLOAD_BITS-1:0]  uart_rx_data;
wire        uart_rx_valid;
wire        uart_rx_break;

// wires for transmitter
wire        uart_tx_busy;
wire [PAYLOAD_BITS-1:0]  uart_tx_data;
wire        uart_tx_en;

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

`ifndef USE_SPRAM
    assign data_out = ib_data_out;
`endif

wire boot;

//-------------------------------------------------------------------------
// FSM controller between UART modules and Memory modules
//-------------------------------------------------------------------------
controller #(.MEM_SELECT_BITS(NUM_BITS)) i_controller(
    .clk(clk),
    .resetn(resetn),
    .uart_rx_valid(uart_rx_valid),
    .receive_data(uart_rx_data),
    .uart_tx_busy(uart_tx_busy),
    .mem_out(data_out),
    .uart_tx_en(uart_tx_en),
    .uart_tx_data(uart_tx_data),
    .mem_select(mem_select),
    .mem_addr(ib_addr),
    .write_data(ib_data_in),
    .rd_en(rd_en),
    .wr_en(wr_en),
    .warmboot(boot),
    .leds(leds),
    .bram_or_spram(bram_or_spram),
    .sp_addr(sp_addr)
);

// //-------------------------------------------------------------------------
// // Converts built-in 12 MHz clock to desired frequency
// //-------------------------------------------------------------------------
// pll pll_instance (
//     .clock_in(in_clk),
//     .clock_out(clk),
//     .locked(pll_lock)
// );

//-------------------------------------------------------------------------
// UART receiever
//-------------------------------------------------------------------------
uart_rx #(
.BIT_RATE(BIT_RATE),
.PAYLOAD_BITS(PAYLOAD_BITS),
.CLK_HZ  (CLK_HZ  )
) i_uart_rx(
.clk          (clk          ), // Top level system clock input.
.resetn       (resetn       ), // Asynchronous active low reset.
.uart_rxd     (uart_rxd     ), // UART Recieve pin.
.uart_rx_en   (1'b1         ), // Recieve enable
.uart_rx_break(uart_rx_break), // Did we get a BREAK message?
.uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
.uart_rx_data (uart_rx_data )  // The recieved data.
);

//-------------------------------------------------------------------------
// UART transmitter
//-------------------------------------------------------------------------
uart_tx #(
.BIT_RATE(BIT_RATE),
.PAYLOAD_BITS(PAYLOAD_BITS),
.CLK_HZ  (CLK_HZ  )
) i_uart_tx(
.clk          (clk          ),
.resetn       (resetn       ),
.uart_txd     (uart_txd     ),
.uart_tx_en   (uart_tx_en   ),
.uart_tx_busy (uart_tx_busy ),
.uart_tx_data (uart_tx_data ) 
);

//-------------------------------------------------------------------------
// Memory blocks
//-------------------------------------------------------------------------
bram #(.NUM_BLOCKS(NUM_BLOCKS)) bram_inst (
.clk(clk), 
.rd_en(rd_en), 
.wr_en(wr_en && (bram_or_spram == 0)), 
.rd_addr({mem_select, ib_addr}), 
.wr_addr({mem_select, ib_addr}), 
.data_in(ib_data_in), 
.data_out(ib_data_out)
);

`ifdef USE_SPRAM
    assign data_out = (bram_or_spram == 0) ? ib_data_out : sp_data_out;

    spram spram_inst (
    .clk(clk),  
    .wr_en(wr_en && (bram_or_spram == 1)), 
    .cs(mem_select[1:0]),
    .addr(sp_addr), 
    .data_in(ib_data_in), 
    .data_out(sp_data_out)
    );
`endif

//-------------------------------------------------------------------------
// Warmboot primitive
//-------------------------------------------------------------------------
SB_WARMBOOT warmboot (
.S1(1'b0),
.S0(1'b1),
.BOOT(boot)
);



endmodule