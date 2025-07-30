import itertools
import pandas as pd
from time import time, strftime, localtime
import random
import string
from os import makedirs
from subprocess import run
from memory_controller import MemoryController
import configparser

# parse options
config = configparser.ConfigParser()
config.read('config.ini')

device = config['DEVICE']['device_type']
port = config['DEVICE']['fpga_port']
seed = int(config['TESTBENCH']['random_seed'])
num_tests = int(config['TESTBENCH']['num_tests'])

# set up pandas df with all combinations of things we want to test
rw = ['Read', 'Write']
addr = [i for i in range(256)]

if device == "hx1k":
    blocks = [i for i in range(16)]
    size = [i+1 for i in range(256)]
elif device == "up5k":
    blocks = [i for i in range(30)]
    # avoid overflowing RP2040
    # TODO: remove magic number
    size = [i+1 for i in range(27)]

all_combinations = list(itertools.product(rw, blocks, addr, size))
df = pd.DataFrame(all_combinations, columns=['R/W', 'Block', 'Address', 'Size'])

# set up file to save to
makedirs("testbench_results", exist_ok=True)
path = strftime(f"testbench_results/{device}_%Y_%m_%d_%H:%M:%S_{seed}.csv", localtime())

# filter out rows where the size + address > 256
df = df.query('Size + Address <= 256')

# shuffle rows
frac = float(num_tests / df.shape[0])
df = df.sample(frac=frac, random_state=seed).reset_index(drop=True)

# add columns for the data we're recording
df['Time (microseconds)'] = 0
df['Accuracy'] = 0

# recompile and upload to hx1k fpga
# for the up5k, press SW0 to reset the device and memory back to a known state
if device == "hx1k":
    run(["iceprog", "build/controller.bin"])

# set up memory controller
mc = MemoryController(port, num_blocks=len(blocks))

# run tests
for index, row in df.iterrows():
    # save every 100, just in case
    if index % 100 == 0:
        so_far = df[df['Time (microseconds)'] > 0]
        so_far.to_csv(path, index=False)

    print(f"Running test {index + 1} of {df.shape[0]}")
    if(row['R/W'] == 'Read'):
        start = time()
        mc.read(row['Block'], row['Address'], row['Size'])
        end = time()
    else:
        # generate random string to write 
        data_str = ''.join(random.choices(string.hexdigits, k=4*row['Size']))

        start = time()
        mc.write(row['Block'], row['Address'], data_str)
        end = time()

    # save data
    df.loc[index, 'Accuracy'] = 1 if mc.verify(row['Block'], row['Address'], row['Size'], display_output=False) else 0
    df.loc[index, 'Time (microseconds)'] = int(1_000_000*(end-start))

# save data to csv
df.to_csv(path, index=False)
print("TESTS COMPLETED")
print(f"Accuracy: {100.0* df['Accuracy'].mean()}%")



