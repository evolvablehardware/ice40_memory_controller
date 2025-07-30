module bram(input wire clk, 
            input wire rd_en, 
            input wire wr_en, 
            input wire [7 + NUM_BITS:0] rd_addr, 
            input wire [7 + NUM_BITS:0] wr_addr, 
            input wire [15:0] data_in, 
            output reg [15:0] data_out, 
            output reg valid_out
);
parameter NUM_BLOCKS = 16;
localparam NUM_BITS = $clog2(NUM_BLOCKS);
parameter FILE = "temp/data.hex";

reg [15:0] memory [0:256*NUM_BLOCKS - 1];

initial begin
   $readmemh(FILE, memory);
end

always @(posedge clk)
begin
   // default
   valid_out <= 0;

   if(wr_en) begin
      memory[wr_addr] <= data_in;
   end
   if (rd_en) begin
      data_out <= memory[rd_addr];
      valid_out <= 1;
   end
end
endmodule