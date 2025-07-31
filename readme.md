A verilog design that can read and write to the BRAM on the iCE40s.

Top-level files:
- Makefile: handles compiling and programming of the images, and running the relevant python files
  - Targets: clean, controller, debug, demo
- pins.pcf: maps to inputs and outputs of the design to the pins on the FPGA
- simulate.sh: script for running a simulation of the testbench

Images:
- Memory controller:
  - Uses UART to handle reading and writing to the entire BRAM
- Debug:
  - Circuit that outputs the entire contents of BRAM to the serial interface
  - Can be wamrbooted with the memory controller
- Demo:
  - Transmits the lowbyte of the current memeory addresss through UART and uses the high byte to determine the next address. Repeats 32 times.
  - Can be wamrbooted with the memory controller

Verilog files:
- integrated_memory_controller.v: top-level module for connecting the submodules and i/os together
- controller.v: state machine for reading and writing and the serial interface
- bram.v: instatiates a given number of blocks of BRAM and provides an interface for memory
- receiver.v: state machine for receiving data off the serial lines
- transmitter.v: state machine for transmitting data using UART
- pll.v: converts the built-in 12MHz clock to a 60MHz one. Generated using icepll
- tb_uart_bram.v: testbench for the top-level design

Python files:
- shell.py: repeatedly uses user inputs to read and write to the BRAM
- memory_controller.py: wrapper for the serial interface that allows for easy reading and writing of the BRAM
- run_testbench.py: runs many random reads and writes to determine how fast and accurate each operation is
- testbench_viz.ipynb: displays the results from the testbench code that have been saved to csvs
- pre_place.py: script run before nextpnr's placement to place each bram block on a specific tile 
- get_bram_locations.py : output where each BRAM block got placed to make sure placement went right
- generate_bram.py: generate bram to be used for debugging

Script to build pico-ice-sdk:
```bash
apt install libusb-1.0-0
apt install gcc-arm-none-eabi

git submodule update --init 
cd lib/pico-ice-sdk && git submodule update --init
cd lib/pico-sdk && git submodule update --init
cd ../../../..
```

For linking pico-ice-sdk in firmware:
```bash
ln -s ../lib/pico-ice-sdk/ rp_firmware/pico-ice-sdk
ln -s ../lib/pico-ice-sdk/lib/pico-sdk/ rp_firmware/pico-sdk
```




