`ifndef LEDS_ADDRESS
    `define LEDS_ADDRESS 1
`endif

module top (
    input clk,
    output [2:0] leds
);
    reg [29:0] counter;
    wire [15:0] data_out;
    assign leds = data_out[2:0];

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    // should be explicit BRAM for placement constraints
    // keep hierarchy prevents any optimizations that would break warmbooting
    (* keep_hierarchy = 1 *)
    bram #(.NUM_BLOCKS(30)) bram_inst (
        .clk(clk), 
        .rd_en(1'b1), 
        .wr_en(1'b0), 
        .rd_addr(8'd`LEDS_ADDRESS), 
        .wr_addr(8'd0), 
        .data_in(16'd0), 
        .data_out(data_out)
    );

    SB_WARMBOOT warmboot (
        .S1(1'b0),
        .S0(1'b0),
        // 5 seconds at 24 MHz
        .BOOT(counter >= 30'd120_000_000)
    );
endmodule