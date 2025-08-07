/*********************************************************************
 * Module: controller
 * Author: Allyn Loyd
 * Date: 2025-06-25
 * Description: Controls using the UART transmitter + reciever to
                facilitate reading to and writing from BRAM
 *********************************************************************/

 /**
 * @brief Control module connecting UART to the memory interface
 *
 * @tparams:
 *   MEM_SELECT_BITS - the number of bits needed to specify which block we want to write/read from
 *
 * @inputs:
 *   clk            - system clock
 *   resetn         - active low reset signal
 *   uart_rx_valid  - high for one pulse when we recieve a byte from the UART lines
 *   receive data   - the byte read off the UART lines
 *   uart_tx_busy   - high when the UART interface is transmitting a byte
 *   mem_out        - the data read from BRAM
 *
 * @outputs:
 *   uart_tx_en     - trigger transmission or uart_tx_data
 *   uart_tx_data   - the data to transmit
 *   mem_select     - the EBR to read from/write to
 *   mem_addr       - the BRAM address to read from/write to
 *   write_data     - the data to write to BRAM
 *   rd_en          - enable reading from BRAM
 *   wr_en          - enable writing to BRAM  
 *   warmboot       - trigger to warmboot 
 *   leds           - 3 leds used for debugging. Currently tied to CurrentState[2:0]
 *   bram_or_spram  - 0 if doing a BRAM operation, 1 for SPRAM
 *   sp_addr        - SPRAM address
 *
 */
module controller(
    input clk,
    input resetn,
    input wire uart_rx_valid,
    input wire [7:0] receive_data,
    input wire uart_tx_busy,
    input wire [15:0] mem_out,
    output wire uart_tx_en,
    output wire [7:0] uart_tx_data,
    output reg [MEM_SELECT_BITS-1:0] mem_select,
    output wire [7:0] mem_addr,
    output reg [15:0] write_data,
    output wire rd_en,
    output wire wr_en,
    output reg warmboot,
    output reg [1:0] warmboot_select,
    output wire [2:0] leds,
    output reg bram_or_spram,
    output wire [13:0] sp_addr
);
parameter MEM_SELECT_BITS = 4;

//-------------------------------------------------------------------------
// State variables
//-------------------------------------------------------------------------
// using current + next versions allows us to have the variable keep its value w/out needing combinatorial loops/latches
reg [5:0] CurrentState, NextState;
reg [8:0] CurrentAddrOffset, NextAddrOffset;
reg [7:0] CurrentSize, NextSize;
reg [7:0] CurrentAddr, NextAddr;
reg CurrentRDorWR, NextRDorWR;
reg [MEM_SELECT_BITS-1:0] NextBlockSelect;
reg [15:0] NextWriteBuffer;
reg NextWarmboot;
reg [1:0] NextWarmbootImage;
reg NextBRorSP;
reg [13:0] CurrentSpAddr, NextSpAddr;

//-------------------------------------------------------------------------
// Parameters for the states
//-------------------------------------------------------------------------
// states both reading and writing operations go through
parameter COMMAND = 5'd0, ADDR = 5'd1, SIZE=5'd14;
// states for reading. Read mem, then transmit the high and low bytes
// setup states enable transmission and set uart_tx_data
parameter READ_MEM = 5'd2, T_SETUP_HIGH = 5'd3, T_HIGH = 5'd4, T_SETUP_LOW = 5'd5, T_LOW = 5'd6;
// states for writing. Recive high and low bytes, and then put them into memory
parameter RX_HIGH = 5'd7, RX_LOW = 5'd8, WRITE_MEM = 5'd9;
// states for stalling to make sure we don't 'skip' a state on one pulse of uart_rx_valid
// then states are switched to when uart_rx_valid goes low, then to the next state when uart_rx_valid goes high
parameter COMMAND_STALL = 5'd10, ADDR_STALL = 5'd11, RX_HIGH_STALL = 5'd12, RX_LOW_STALL = 5'd13, SIZE_STALL=5'd15;
// states for receiving the spram address
parameter SP_ADDR_HIGH = 5'd16, SP_ADDR_HIGH_STALL = 5'd17, SP_ADDR_LOW = 5'd18, SP_ADDR_LOW_STALL = 5'd19;

//-------------------------------------------------------------------------
// Outputs: assign outputs based on current states
//-------------------------------------------------------------------------
assign mem_addr = CurrentAddr + CurrentAddrOffset;
assign sp_addr = CurrentSpAddr + CurrentAddrOffset;
assign rd_en = (CurrentState != WRITE_MEM);
assign wr_en = (CurrentState == WRITE_MEM);
assign uart_tx_en = (CurrentState == T_SETUP_HIGH) || (CurrentState == T_SETUP_LOW);
assign uart_tx_data = (CurrentState == T_SETUP_HIGH) ? mem_out[15:8] : mem_out[7:0];
assign leds = {warmboot, warmboot_select};

//-------------------------------------------------------------------------
// Update current state and handle resets
//-------------------------------------------------------------------------
always @ (posedge clk) begin
    CurrentState <= (resetn == 0) ? COMMAND : NextState;
    CurrentAddrOffset <= (resetn == 0) ? 9'b0 : NextAddrOffset;
    CurrentSize <= (resetn == 0) ? 8'b0 : NextSize;
    CurrentAddr <= (resetn == 0) ? 8'b0 : NextAddr;
    CurrentRDorWR <= (resetn == 0) ? 1'b0 : NextRDorWR;
    mem_select <= (resetn == 0) ? 3'b0 : NextBlockSelect;
    write_data <= (resetn == 0) ? 16'b0 : NextWriteBuffer;
    warmboot <= (resetn == 0) ? 1'b0 : NextWarmboot;
    warmboot_select <= (resetn == 0) ? 2'b0 : NextWarmbootImage;
    bram_or_spram <= (resetn == 0) ? 1'b0 : NextBRorSP;
    CurrentSpAddr <= (resetn == 0) ? 14'b0 : NextSpAddr;
end

//-------------------------------------------------------------------------
// Next state logic
//-------------------------------------------------------------------------
always @ (CurrentState or uart_rx_valid or uart_tx_busy) begin
    // set default values so we don't have to specify every variable in our cases
    // blocking (= vs <=) so that these execute before our cases
    NextAddrOffset = CurrentAddrOffset;
    NextSize = CurrentSize;
    NextAddr = CurrentAddr;
    NextState = CurrentState;
    NextWriteBuffer = write_data;
    NextBlockSelect = mem_select;
    NextRDorWR = CurrentRDorWR;
    NextWarmboot = warmboot;
    NextWarmbootImage = warmboot_select;
    NextBRorSP = bram_or_spram;
    NextSpAddr = CurrentSpAddr;

    case(CurrentState)
        // receive r/w and the EBR to use
        COMMAND: begin
            if (uart_rx_valid == 1) begin
                NextState <= COMMAND_STALL;
                NextBlockSelect <= receive_data[MEM_SELECT_BITS-1:0];
                NextBRorSP <= receive_data[7];
                NextRDorWR <= receive_data[6];
                NextWarmboot <= receive_data[5];
                NextWarmbootImage <= receive_data[1:0];
            end
        end
        // wait for uart_rx_valid to go low so we can start to wait to receive the next byte
        COMMAND_STALL: NextState <= (uart_rx_valid == 0) ? ((bram_or_spram == 0) ? ADDR : SP_ADDR_HIGH) : COMMAND_STALL;
        // receive address
        ADDR: begin
            if(uart_rx_valid == 1) begin
                NextState <= ADDR_STALL;
                NextAddr <= receive_data;
                NextAddrOffset <= 9'b0;
            end
        end
        // wait for uart_rx_valid to go low so we can start to wait to receive the next byte
        ADDR_STALL: NextState <= (uart_rx_valid == 0) ? SIZE : ADDR_STALL;
        // receive the number of locations to read from/write to
        SIZE: begin
            if (uart_rx_valid == 1) begin
                NextState <= SIZE_STALL;
                // add 1 to the received data so that we send between 1 and 2^n values, not 0 to 2^n-1
                NextSize <= receive_data;
            end
        end
        // wait for uart_rx_valid to go low so we can start to wait to receive the next byte
        SIZE_STALL: begin
            if(uart_rx_valid == 0) begin
                NextState <= (CurrentRDorWR == 0) ? READ_MEM : RX_HIGH;
            end
        end
        
        // READING FROM MEMORY
        // read data from memory
        READ_MEM: NextState <= T_SETUP_HIGH;
        // trigger sending the high byte read from memory
        T_SETUP_HIGH: NextState <= T_HIGH;
        // wait until the byte is done being transmitted
        T_HIGH: NextState <= (uart_tx_busy == 0) ? T_SETUP_LOW : T_HIGH;
        // trigger sending the low bytes read from memory
        T_SETUP_LOW: NextState <= T_LOW;
        // wait until the bytes is done being transmitted
        // check if we transmitted the right number of bytes
        T_LOW: begin
            if (uart_tx_busy == 0) begin
                NextState <= (CurrentAddrOffset >= CurrentSize) ? COMMAND : READ_MEM;
                NextAddrOffset <=  CurrentAddrOffset + 8'b1;
            end
        end

        // WRITING FROM MEMORY
        // receive the high byte from UART
        RX_HIGH: begin
            if(uart_rx_valid == 1) begin
                NextState <= RX_HIGH_STALL;
                NextWriteBuffer[15:8] <= receive_data;
            end
        end
        // wait for uart_rx_valid to go low so we can start to wait to receive the next byte
        RX_HIGH_STALL: NextState <= (uart_rx_valid == 0) ? RX_LOW : RX_HIGH_STALL;
        // receive the low byte from UART
        RX_LOW: begin
            if(uart_rx_valid == 1) begin
                NextState <= RX_LOW_STALL;
                NextWriteBuffer[7:0] <= receive_data;
            end
        end
        // wait for uart_rx_valid to go low so we can start to wait to receive the next byte
        RX_LOW_STALL: NextState <= (uart_rx_valid == 0) ? WRITE_MEM : RX_LOW_STALL;
        // write received data to memory and check if we've written to the correct number of locations
        WRITE_MEM: begin
            if (uart_tx_busy == 0) begin
                NextState <= (CurrentAddrOffset >= CurrentSize) ? COMMAND : RX_HIGH;
                NextAddrOffset <=  CurrentAddrOffset + 9'b1;
            end
        end

        // SPRAM
        // receive first part of spram address
        SP_ADDR_HIGH: begin
            if(uart_rx_valid == 1) begin
                NextState <= SP_ADDR_HIGH_STALL;
                NextSpAddr[13:8] <= receive_data[5:0];
                NextAddrOffset <= 9'b0;
            end
        end
        // wait for uart_rx_valid to go low so we can start to wait to receive the next byte
        SP_ADDR_HIGH_STALL: NextState <= (uart_rx_valid == 0) ? SP_ADDR_LOW : SP_ADDR_HIGH_STALL;
        // receive second part of spram address
        SP_ADDR_LOW: begin
            if(uart_rx_valid == 1) begin
                NextState <= SP_ADDR_LOW_STALL;
                NextSpAddr[7:0] <= receive_data;
            end
        end
        // wait for uart_rx_valid to go low so we can start to wait to receive the next byte
        SP_ADDR_LOW_STALL: NextState <= (uart_rx_valid == 0) ? SIZE : SP_ADDR_LOW_STALL;

        // just in case we end up in an invalid state
        default: begin
            NextState <= COMMAND;
            NextAddrOffset <= CurrentAddrOffset;
            NextSize <= CurrentSize;
            NextAddr <= CurrentAddr;
            NextWriteBuffer <= write_data;
            NextBlockSelect <= mem_select;
            NextRDorWR <= CurrentRDorWR;
            NextWarmboot <= warmboot;
            NextWarmbootImage <= warmboot_select;
            NextBRorSP <= bram_or_spram;
            NextSpAddr <= CurrentSpAddr;
        end
    endcase
end

endmodule