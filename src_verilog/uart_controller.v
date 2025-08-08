/*********************************************************************
 * Module: uart_controller
 * Author: Allyn Loyd
 * Date: 2025-08-08
 * Description: Connects the FSM, uart modules, and warmboot primitive together. All modules not related to the NN.
 *********************************************************************/

 /**
 * @brief Connects the FSM, uart modules, and warmboot primitive together. All modules not related to the NN.
 *
 * @tparams:
 *   MEM_SELECT_BITS - the number of bits needed to specify which block we want to write/read from
 *   CLK_HZ          - the clock speed of the FPGA
 *   BIT_RATE        - buad rate for UART
 *   PAYLOAD_BITS    - number of bits to send per transmission
 *
 * @inputs:
 *   clk            - system clock
 *   uart_rxd       - UART receiver line
 *   uart_txd       - UART transmitter line
 *   resetn         - active low reset signal
 *   mem_out        - the data read from BRAM
 *
 * @outputs:
 *   mem_select     - the EBR to read from/write to
 *   mem_addr       - the BRAM address to read from/write to
 *   mem_in         - the data to write to BRAM
 *   rd_en          - enable reading from BRAM
 *   wr_en          - enable writing to BRAM  
 *   leds           - 3 leds used for debugging. Currently tied to CurrentState[2:0]
 *   bram_or_spram  - 0 if doing a BRAM operation, 1 for SPRAM
 *   sp_addr        - SPRAM address
 *
 */
module uart_controller(
    input wire clk,
    input wire uart_rxd,
    input wire uart_txd,
    input wire resetn,
    input wire [15:0] mem_out,
    output reg [MEM_SELECT_BITS-1:0] mem_select,
    output wire [7:0] mem_addr,
    output reg [15:0] mem_in,
    output wire rd_en,
    output wire wr_en,
    output wire [2:0] leds,
    output reg bram_or_spram,
    output wire [13:0] sp_addr
);
parameter MEM_SELECT_BITS = 5;
parameter CLK_HZ = 48_000_000;
parameter BIT_RATE =   115200;
parameter PAYLOAD_BITS = 8;

// wires for receiver
wire [PAYLOAD_BITS-1:0]  uart_rx_data;
wire        uart_rx_valid;
wire        uart_rx_break;

// wires for transmitter
wire        uart_tx_busy;
wire [PAYLOAD_BITS-1:0]  uart_tx_data;
wire        uart_tx_en;

// wires for warmbooting 
wire boot;
wire [1:0] boot_select;

//-------------------------------------------------------------------------
// FSM controller between UART modules and Memory modules
//-------------------------------------------------------------------------
controller #(.MEM_SELECT_BITS(MEM_SELECT_BITS)) i_controller(
    .clk(clk),
    .resetn(resetn),
    .uart_rx_valid(uart_rx_valid),
    .receive_data(uart_rx_data),
    .uart_tx_busy(uart_tx_busy),
    .mem_out(mem_out),
    .uart_tx_en(uart_tx_en),
    .uart_tx_data(uart_tx_data),
    .mem_select(mem_select),
    .mem_addr(mem_addr),
    .write_data(mem_in),
    .rd_en(rd_en),
    .wr_en(wr_en),
    .warmboot(boot),
    .warmboot_select(boot_select),
    .leds(leds),
    .bram_or_spram(bram_or_spram),
    .sp_addr(sp_addr)
);

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
// Warmboot primitive
//-------------------------------------------------------------------------
SB_WARMBOOT warmboot (
.S1(boot_select[1]),
.S0(boot_select[0]),
.BOOT(boot)
);

endmodule