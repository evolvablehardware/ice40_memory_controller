A verilog project for reading and writing to BRAM for the iCE40 hx1k and up5k devices. The project also supports SPRAM reading and writing for the up5k device. Additionally, there is python code for communicating with the device and support for building the project for use on the pico-ice and pico-ice2.

### Setup
#### Dependencies
A yosys, nextpnr-ice40, and Project Icestorm installation is needed. An installation guide for those tools can be found [here](https://prjicestorm.readthedocs.io/en/latest/overview.html#where-are-the-tools-how-to-install). Other required dependencies can be installed with:
```bash
sudo apt install libusb-1.0-0 gcc-arm-none-eabi
```

#### Python Packages
The following python packages are needed
- pyserial
- pandas
- matplotlib
- numpy
- tqdm

#### Pico-ice-sdk
To set up pico-ice-sdk and pico-sdk:
```bash
git submodule update --init 
cd lib/pico-ice-sdk && git submodule update --init
cd lib/pico-sdk && git submodule update --init
cd ../../../..
```

For linking pico-ice-sdk in rp_firmware:
```bash
ln -s ../lib/pico-ice-sdk/ rp_firmware/pico-ice-sdk
ln -s ../lib/pico-ice-sdk/lib/pico-sdk/ rp_firmware/pico-sdk
```

### Building
The project can be built for the hx1k and up5k iCE40 FPGAs, with implicitly or explicitly instantiated BRAM, and for the pico-ice or pico2-ice.

```bash
make BRAM=[implicit/explicit] DEVICE=[hx1k/up5k] PICO=[1/2]
```

### Using the project
There are multiple python files provided for allowing modification of memory from the host PC. 
- [src_python/shell.py](src_python/shell.py) provides a shell-like interface for sending reads and writes. It automatically verifies each operation went through correctly
- [src_python/run_testbench.py](src_python/run_testbench.py) measures the time and accuracy of the project on a random series of reads and writes. The results can be viewed using [src_python/testbench_viz.ipynb](src_python/testbench_viz.ipynb), provided `DATA_FILE` is set to the .csv produced by [src_python/run_testbench.py](src_python/run_testbench.py).

#### Configuration
Both [src_python/shell.py](src_python/shell.py) and [src_python/run_testbench.py](src_python/run_testbench.py) make use of config.ini. There are two options that must be specified for both scripts
- fpga_port: the usb port of the FPGA. Likely /dev/ttyUSB0 for hx1k or /dev/ttyACM1 for up5k
- device_type: either hx1k or up5k

To run the testbench, the following three options must be specified:
- random_seed: the seed to use for shuffling the order of the tests and generating write data.
- num_tests: the number of reads and writes to tests
- bram_or_spram: whether to test BRAM or SPRAM. Can be set to "bram" or "spram". Only applicable if the device_type is up5k.

### Command Structure
The first byte of each operation specifies what type of operation to do and which block of memory to do it to. Note: the hx1k device contains 16 blocks of BRAM, while the up5k device has 30 blocks of BRAM and 4 blocks of SPRAM.

| Bit | Data                          |
|-----|-------------------------------|
| 7   | 0 for BRAM, 1 for SPRAM       |
| 6   | 0 for read, 1 for write       |
| 5   | 1 if warmbooting, 0 otherwise |
| 4:0 | Block to read/write from      |
| 1:0 | Warmboot image select         |

#### BRAM
For BRAM operations, the next byte to be sent is the address that reading and writing starts from. Each block of BRAM has 256 possible addresses and a width of 16 bits. 

Next, the size (number of 2 byte locations) of the operation is sent in a single byte. One is subtracted from the size before it is sent, as we don't need to support size 0, and this allows us to support up to size 255. The controller supports operations up to size 256, but the user might run into issues with UART buffers overflowing on the RP Pico with large operations. 

For read operations, the FPGA will then transmit the requested data. The PC should receive double the number of bytes as the sent size.

For write operations, the PC should send the bytes to be written to memory, keeping in mind each location is 2 bytes.

#### SPRAM
As each SPRAM block has 16K addresses, we send two bytes for the address of each operation. The rest of the bytes (size and write data) are the same as the BRAM operations.

#### FSM diagram
A diagram for the state machine on the FPGA can be found in [Memory_Controller_FSM.pdf](Memory_Controller_FSM.pdf).