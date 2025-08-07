from serial import Serial
from time import sleep
from math import ceil
from time import time
from random import randint, seed

class MemoryController:
    def __init__(self, port, num_blocks=16, hex_data_path="build/data.hex", spram_data_path="build/spram_data.hex"):
        self.__serial = Serial(port, 115200, timeout=1)

        self.reset()

        # set up bram
        self.__data = []
        self.__data_path = hex_data_path
        raw_data = open(hex_data_path).read().split("\n")
        invalid_bram_file = False
        for i in range(num_blocks):
            self.__data.append([])
            for j in range(256):
                try:
                    self.__data[i].append(raw_data[i*256 + j])
                except IndexError:
                    self.__data[i].append("0000")
                    invalid_bram_file = True
        if invalid_bram_file:
            print("WARNING: BRAM file did not have enough lines. Assuming missing locations are 0000")

        # set up spram
        if spram_data_path is not None:
            self.__spram_data = []
            self.__spram_data_path = spram_data_path
            raw_spram_data = open(spram_data_path).read().split("\n")
            invalid_spram_file = False
            for i in range(4):
                self.__spram_data.append([])
                for j in range(pow(2,14)):
                    try:
                        self.__spram_data[i].append(raw_spram_data[i*pow(2,14) + j])
                    except IndexError:
                        self.__data[i].append("0000")
                        invalid_spram_file = True
            if invalid_spram_file:
                print("WARNING: SPRAM file did not have enough lines. Assuming missing locations are 0000")

    def read(self, block, addr, size, spram=False):
        self.__serial.reset_input_buffer()
        self.__serial.reset_output_buffer()

        # set the 7th bit high if we're doing a spram operation
        first_byte_dec = block | (spram << 7)
        block_byte = first_byte_dec.to_bytes(1, 'big')
        num_addr_bytes = 2 if spram else 1
        addr_byte = addr.to_bytes(num_addr_bytes, 'big')
        # subtract 1 from the size so that we  can send between 1 and 2^n values, not 0 to 2^n -1
        offset_size = size-1
        size_byte = offset_size.to_bytes(1, 'big')

        # send data to serial and wait for response
        self.__serial.write(block_byte)
        self.__serial.write(addr_byte)
        self.__serial.write(size_byte)
        self.__serial.flush()
        result = self.__serial.read(2 * size)

        b = [result.hex()[4*i:4*i+4] for i in range(ceil(len(result.hex()) / 4))]
        return b
    
    def write(self, block, addr, data_str, spram=False):
        self.__serial.reset_input_buffer()
        self.__serial.reset_output_buffer()
        
        # set the sixth bit to 1 to indicate we are writing
        first_byte_dec = block | (1 << 6)
        # set the 7th bit high if we're doing a spram operation
        first_byte_dec = first_byte_dec | (spram << 7)
        first_byte = first_byte_dec.to_bytes(1, 'big')

        size = int(len(data_str) / 4)
        # subtract 1 from the size so that we  can send between 1 and 16 values, not 0 to 15
        offset_size = size-1
        size_byte = offset_size.to_bytes(1, 'big')

        num_addr_bytes = 2 if spram else 1
        addr_byte = addr.to_bytes(num_addr_bytes, 'big')

        data_bytes = bytearray.fromhex(data_str)

        # send data to serial
        self.__serial.write(first_byte)
        self.__serial.write(addr_byte)
        self.__serial.write(size_byte)
        for b in data_bytes:
            self.__serial.write(b.to_bytes(1, 'big')) 
        self.__serial.flush()

        # update our copy of data
        for i in range(size):
            if spram:
                self.__spram_data[block][addr + i] = data_str[4*i:4*i + 4].lower()
            else:
                self.__data[block][addr + i] = data_str[4*i:4*i + 4].lower()

    def verify(self, block, addr, size, display_output = True, spram=False):
        b = self.read(block, addr, size, spram=spram)
        if display_output:
            print(f"Verifying {size} locations starting at address {addr}")
            print(f"Received {b}")

        # make sure there is no extra data left on the serial line
        r = self.__serial.read_all()

        d = self.__spram_data if spram else self.__data
        if len(b) == size and all(b[i] == d[block][addr+i] for i in range(min(len(b), size))):
            if len(r.hex()) == 0:
                if display_output:
                    print("MATCH\n")
                return True
            else:
                if display_output:
                    print(f"FAILED\nReceived extra bytes: {r.hex()}")
                return False
        else:
            if display_output:
                print(f"FAILED\nExpected {d[block][addr:addr+size]}\n")
            return False
        
    def trigger_warmboot(self, image):
        trigger_num = (1 << 5) + image # bit 5 is 1, bits 1 and 0 are the image number
        trigger_byte = trigger_num.to_bytes(1, 'big')
        self.__serial.write(trigger_byte)
        self.__serial.flush()
        self.reset()
        
        
    def reset(self):
        self.__serial.setRTS(True)
        sleep(0.1)
        self.__serial.setRTS(False)

        self.__serial.reset_input_buffer()
        self.__serial.reset_output_buffer()
        
    def save_to_file(self):
        # bram
        with open(self.__data_path, 'w') as file:
            for i in range(len(self.__data)):
                for v in self.__data[i]:
                    file.write(v + "\n")
        # spram
        with open(self.__spram_data_path, 'w') as file:
            for i in range(len(self.__spram_data)):
                for v in self.__spram_data[i]:
                    file.write(v + "\n")

    def init_spram(self):
        print(f"Initializing SPRAM with {self.__spram_data_path}...")
        chunk_size = 24
        num_chunks = ceil(pow(2,14) / chunk_size)
        start = time()
        for i in range(len(self.__spram_data)):
            print(f"Initializing block {i+1} of 4")
            for j in range(num_chunks):
                data = self.__spram_data[i][chunk_size*j:chunk_size*(j+1)]
                data_str = "".join(data)
                self.write(i, chunk_size*j, data_str, spram=True)
                if not self.verify(i ,chunk_size*j, int(len(data_str)/4), False, True):
                    print(f"Error initilaizing block {i} address {chunk_size*j}. ABORT")
                    exit(1)
        end = time()
        print(f"Done. Time taken: {end-start} seconds.")

    # solves weird issue where the fpga is not in state 0 whenever the serial connection is init
    # TODO: find better solution
    def read_until_match(self):
        print("Performing random reads until device syncs")
        t = 0
        seed(0)
        while True:
            print(f"Attempt {t+1} at reading successfully")
            
            block = randint(0, 15)
            addr = randint(0, 255)
            size = randint(1, min(10, 256-addr))
            if self.verify(0, 0, size, display_output=False, spram=False):
                break

            t += 1
        print(f"Performed successful read. Device is synced")