from memory_controller import MemoryController
import string
import configparser

def get_int_input(param, lower_bound, upper_bound):
    while True:
        try: 
            val = int(input(f"{param}: "))
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

mc = MemoryController(config['DEFAULT']['fpga_port'])

while True:
    mode = input("(R)ead, (W)rite, (T)riger warmboot, (S)ave current state to file: ").upper()

    if mode == "R" or mode == "W":
        # Memory block to read from
        block = get_int_input("Block", 0, 15)

        # 8-bit address to read from
        addr = get_int_input("Address", 0, 255)

    if mode == "R":
        # number of 16-byte memory locations to read
        size = get_int_input("Size", 1, 255 - addr + 1)
        print(mc.verify(block, addr, size)) #verify calls read
    elif mode == "W":
        data_str = get_hex_input()
        mc.write(block, addr, data_str)
        size = int(len(data_str) / 4)
        mc.verify(block, addr, size)
    elif mode == "T":
        mc.trigger_warmboot()
    elif mode == "S":
        mc.save_to_file()