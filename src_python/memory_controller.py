from serial import Serial
from time import sleep
from math import ceil

class MemoryController:
    def __init__(self, port, num_blocks=16, hex_data_path="build/data.hex"):
        self.__serial = Serial(port, 115200, timeout=1)
        self.__data = []
        self.__data_path = hex_data_path
        raw_data = open(hex_data_path).read().split("\n")
        for i in range(num_blocks):
            self.__data.append([])
            for j in range(256):
                self.__data[i].append(raw_data[i*256 + j])

        self.reset()

    def read(self, block, addr, size):
        self.__serial.reset_input_buffer()
        self.__serial.reset_output_buffer()

        block_byte = block.to_bytes(1, 'big')
        addr_byte = addr.to_bytes(1, 'big')
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
    
    def write(self, block, addr, data_str):
        self.__serial.reset_input_buffer()
        self.__serial.reset_output_buffer()
        
        # set  the second bit to 1 to indicate we are writing
        first_byte_dec = 64 + block
        first_byte = first_byte_dec.to_bytes(1, 'big')

        size = int(len(data_str) / 4)
        # subtract 1 from the size so that we  can send between 1 and 16 values, not 0 to 15
        offset_size = size-1
        size_byte = offset_size.to_bytes(1, 'big')

        addr_byte = addr.to_bytes(1, 'big')

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
            self.__data[block][addr + i] = data_str[4*i:4*i + 4].lower()

    def verify(self, block, addr, size, display_output = True):
        b = self.read(block, addr, size)
        if display_output:
            print(f"Verifying {size} locations starting at address {addr}")
            print(f"Received {b}")

        # make sure there is no extra data left on the serial line
        r = self.__serial.read_all()

        if len(b) == size and all(b[i] == self.__data[block][addr+i] for i in range(min(len(b), size))):
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
                print(f"FAILED\nExpected {self.__data[block][addr:addr+size]}\n")
            return False
        
    def trigger_warmboot(self):
        trigger_num = 32 #bit 5
        trigger_byte = trigger_num.to_bytes(1, 'big')
        self.__serial.write(trigger_byte)
        self.__serial.flush()
        self.reset()

        r = self.__serial.read(2*4096)
        ha = r.hex()
        with open("warmboot_output.hex", 'w') as f:
            for i in range(16):
                for j in range(0,256):
                    if 4*(256*i + j) < len(ha):
                        f.write(f"{ha[4*(256*i + j): 4*(256*i + j+ 1)]}\n")
        print(f"Read {len(r)} bytes into warmboot_output.hex")
        self.reset()
        
        
    def reset(self):
        self.__serial.setRTS(True)
        sleep(0.1)
        self.__serial.setRTS(False)

        self.__serial.reset_input_buffer()
        self.__serial.reset_output_buffer()
        
    def save_to_file(self):
        with open(self.__data_path, 'w') as file:
            for i in range(len(self.__data)):
                for v in self.__data[i]:
                    file.write(v + "\n")