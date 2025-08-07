from memory_controller import MemoryController
import string
import configparser

def get_int_input(param, lower_bound, upper_bound):
    while True:
        try: 
            val = int(input(f"{param} ({lower_bound} to {upper_bound}): "))
        except ValueError:
            print(f"{param} must be an int from {lower_bound} to {upper_bound}.")
            continue
        if val < lower_bound or val > upper_bound:
            print(f"{param} must be an int from {lower_bound} to {upper_bound}.")
            continue
        else:
            return val
        
def get_hex_input():
    while True:
        data_str = input("Hex data to write: ")
        if (len(data_str) % 4 == 0) \
            and all(c in string.hexdigits for c in data_str):
            return data_str
        else:
            print("Input must contain only hex characters and have a length that is a multiple of 4.")

config = configparser.ConfigParser()
config.read('config.ini')

device = config['DEVICE']['device_type']
if device == "hx1k":
    num_blocks = 16
    spram_data_path = None
    spram_option = ""
elif device == "up5k":
    num_blocks = 30
    spram_data_path = "build/spram_data.hex"
    spram_option = ", (I)nit SPRAM"
else:
    raise ValueError(f"Device not supported: {device}. Use hx1k or up5k")

mc = MemoryController(config['DEVICE']['fpga_port'], num_blocks=num_blocks, spram_data_path=spram_data_path)

while True:
    mode = input(f"(R)ead, (W)rite, (T)riger warmboot, (S)ave current state to file{spram_option}, Sync (D)evice: ").upper()

    if mode == "R" or mode == "W":
        # if on the 5k device, ask if we're using spram
        use_spram = False
        if device == "up5k":
            response = input("(B)RAM or (S)PRAM: ").upper()
            use_spram = response == "S"

        if use_spram:
            # Memory block to read from
            block = get_int_input("Block", 0, 3)
            # 14-bit address to read from
            addr = get_int_input("Address", 0, pow(2,14)-1)
        else:
            # Memory block to read from
            block = get_int_input("Block", 0, num_blocks-1)
            # 8-bit address to read from
            addr = get_int_input("Address", 0, 255)

    if mode == "R":
        # number of 16-byte memory locations to read
        max_addr = pow(2,14) if use_spram else 256
        size = get_int_input("Size", 1, max_addr - addr)
        print(mc.verify(block, addr, size, spram=use_spram)) #verify calls read
    elif mode == "W":
        data_str = get_hex_input()
        mc.write(block, addr, data_str, spram=use_spram)
        size = int(len(data_str) / 4)
        mc.verify(block, addr, size, spram=use_spram)
    elif mode == "T":
        image = get_int_input("Image", 0, 3)
        mc.trigger_warmboot(image)
    elif mode == "S":
        mc.save_to_file()
    elif mode == "I":
        mc.init_spram()
    elif mode == "D":
        mc.read_until_match()