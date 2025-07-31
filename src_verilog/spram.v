module spram(input wire clk, 
            input wire wr_en, 
            input wire [1:0] cs,
            input wire [13:0] addr,  
            input wire [15:0] data_in, 
            output wire [15:0] data_out
);

wire [15:0] data_outs[3:0];
assign data_out = data_outs[cs];

genvar i;
generate
    for(i = 0; i < 4; i = i + 1) begin
        SB_SPRAM256KA spram_inst (
            .ADDRESS(addr),
            .DATAIN(data_in),
            .MASKWREN(4'b1111),
            .WREN(wr_en && (cs == i[1:0])),
            .CHIPSELECT(cs == i[1:0]),
            .CLOCK(clk),
            .STANDBY(1'b0),
            .SLEEP(1'b0),
            .POWEROFF(1'b1),
            .DATAOUT(data_outs[i[1:0]])
        );
    end
endgenerate

endmodule