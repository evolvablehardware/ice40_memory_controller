(* BEL = "X3/Y1/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/0.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_0 (
    .RDATA(data_outs[0]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 0))
);

(* BEL = "X3/Y3/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/1.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_1 (
    .RDATA(data_outs[1]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 1))
);

(* BEL = "X3/Y5/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/2.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_2 (
    .RDATA(data_outs[2]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 2))
);

(* BEL = "X3/Y7/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/3.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_3 (
    .RDATA(data_outs[3]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 3))
);

(* BEL = "X3/Y9/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/4.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_4 (
    .RDATA(data_outs[4]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 4))
);

(* BEL = "X3/Y11/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/5.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_5 (
    .RDATA(data_outs[5]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 5))
);

(* BEL = "X3/Y13/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/6.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_6 (
    .RDATA(data_outs[6]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 6))
);

(* BEL = "X3/Y15/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/7.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_7 (
    .RDATA(data_outs[7]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 7))
);

(* BEL = "X10/Y1/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/8.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_8 (
    .RDATA(data_outs[8]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 8))
);

(* BEL = "X10/Y3/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/9.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_9 (
    .RDATA(data_outs[9]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 9))
);

(* BEL = "X10/Y5/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/10.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_10 (
    .RDATA(data_outs[10]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 10))
);

(* BEL = "X10/Y7/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/11.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_11 (
    .RDATA(data_outs[11]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 11))
);

(* BEL = "X10/Y9/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/12.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_12 (
    .RDATA(data_outs[12]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 12))
);

(* BEL = "X10/Y11/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/13.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_13 (
    .RDATA(data_outs[13]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 13))
);

(* BEL = "X10/Y13/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/14.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_14 (
    .RDATA(data_outs[14]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 14))
);

(* BEL = "X10/Y15/ram" *)
SB_RAM40_4K #(
    .INIT_FILE("build/data/15.hex"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_15 (
    .RDATA(data_outs[15]),
    .RADDR({3'b000, rd_addr[7:0]}),
    .WADDR({3'b000, wr_addr[7:0]}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == 15))
);

