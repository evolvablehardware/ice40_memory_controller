import itertools
import pandas as pd
import argparse
from time import time, strftime, localtime
import random
import string
from os import makedirs
from subprocess import run
from memory_controller import MemoryController

# inputs are the random seed and num times to run each test
parser = argparse.ArgumentParser(description='Script to collect data on the speed of the iCE40 UART memory controller')
parser.add_argument('s', help='random seed used for determining the order in which to run tests')
parser.add_argument('f', help='fraction of all possible combinations to run')
parser.add_argument('p', help='usb port (i.e. /dev/ttyUSB0)')
args = parser.parse_args()
seed = int(args.s)
random.seed(seed)
frac = float(args.f)

# set up pandas df with all combinations of things we want to test
rw = ['Read', 'Write']
blocks = [i for i in range(16)]
addr = [i for i in range(256)]
size = [i+1 for i in range(256)]
all_combinations = list(itertools.product(rw, blocks, addr, size))
df = pd.DataFrame(all_combinations, columns=['R/W', 'Block', 'Address', 'Size'])

# set up file to save to
makedirs("testbench_results", exist_ok=True)
path = strftime(f"testbench_results/%d_%m_%Y_%H:%M:%S_{seed}.csv", localtime())

# filter out rows where the size + address > 256
df = df.query('Size + Address <= 256')

# shuffle rows
df = df.sample(frac=frac, random_state=seed).reset_index(drop=True)

# add columns for the data we're recording
df['Time (microseconds)'] = 0
df['Accuracy'] = 0

# recompile and upload to fpga
# run(["iceprog", "temp/controller.bin"])

# set up memory controller
mc = MemoryController("/dev/ttyACM1")

# run tests
for index, row in df.iterrows():
    # save every 500, just in case
    if index % 1 == 0:
        so_far = df[df['Time (microseconds)'] > 0]
        so_far.to_csv(path, index=False)

    print(f"{index} of {df.shape[0]}")
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



