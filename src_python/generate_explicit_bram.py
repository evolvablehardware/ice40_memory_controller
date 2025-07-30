import argparse

parser = argparse.ArgumentParser(description="Generates a verilog header file with bram blocks")
parser.add_argument("--n", type=int, default=16, help="The number of blocks to instantiate")
parser.add_argument("--d", type=str, default="hx1k", help="The device (i.e hx1k or up5k)")
parser.add_argument("--o", type=str, default="build/generated_rams.vh", help="Where to write the generated verilog header file to")
args = parser.parse_args()

def get_hx1k_bels():
    # generate list of all relevant BELS
    placements = []
    for x in [3, 10]:
        for y in [1, 3, 5, 7, 9, 11, 13, 15]:
            placements.append(f"X{x}/Y{y}/ram")
    return placements

def get_up5k_bels():
    # generate list of all relevant BELS
    placements = []
    for x in [6, 19]:
        for y in range(1, 30, 2):
            placements.append(f"X{x}/Y{y}/ram")
    return placements

if args.d == "hx1k":
    bel_locations = get_hx1k_bels()
elif args.d == "up5k":
    bel_locations = get_up5k_bels()
else:
    raise ValueError(f"Device not supported: {args.d}. Use hx1k or up5k")

assert len(bel_locations) >= args.n, f"Too many EBRs requested for the device {args.d}"

with open(args.o, "w") as f:
    for i in range(args.n):
        bel = bel_locations[i]
        init_file = f"build/data/{i}.hex"

        f.write(f"""\
(* BEL = "{bel}" *)
SB_RAM40_4K #(
    .INIT_FILE("{init_file}"),
    .READ_MODE(0),
    .WRITE_MODE(0)
) ram_inst_{i} (
    .RDATA(data_outs[{i}]),
    .RADDR({{3'b000, rd_addr[7:0]}}),
    .WADDR({{3'b000, wr_addr[7:0]}}),
    .MASK(16'b0),
    .WDATA(data_in),
    .RCLKE(1'b1),
    .RCLK(clk),
    .RE(rd_en),
    .WCLKE(1'b1),
    .WCLK(clk),
    .WE(wr_en && (wr_select == {i}))
);

""")