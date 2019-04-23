# Data prefetchers [![Build Status](https://travis-ci.com/jsmont/data_prefetcher.svg?branch=master)](https://travis-ci.com/jsmont/data_prefetcher)
## How to compile:

In order to compile a prefetcher, place it on the src folder using the following convention:
```
src/PREFETCHER_NAME_prefetcher.c
```
It can then be compiled by using:
```
make PREFETCHER_NAME
```
Which will generate the following file:
```
bin/sim_PREFETCHER_NAME
```

## How to run:

The DPC2 Simulator reads in an instruction trace from stdin in the form
of binary data, so you must use the cat command and pipe it into the 
input of the simulator, like this:

```
cat trace.dpc | bin/sim_PREFETCHER_NAME
```

The included traces have been zipped.  You can use zcat to feed these
traces into the simulator without unzipping them beforehand:

```
zcat trace.dpc.gz | bin/sim_PREFETCHER_NAME
```

There are several command line switches that you can use to configure the
DPC2 Simulator.

* -small_llc: 
This changes the size of the Last Level Cache to 256 KB.  The default
size of the LLC is 1 MB.

* -low_bandwidth:
This changes the DRAM bandwidth of the system to 3.2 GB/s.  The default
DRAM bandwidth is 12.8 GB/s.

* -scramble_loads:
This randomizes the order in which loads lookup the L1.  Note that this
randomization only occurs among loads which are ready to issue at that
moment, so the degree of randomization the L2 sees is usually small.
Default is to NOT use scrambled loads.

* -warmup_instructions <number>:
Use this to specify the length of the warmup period.  After the warmup
period is over, the IPC statistics are reset, and the final reported
IPC metric will be calculated starting at this point.
Default value is 10,000,000.

* -simulation_instructions <number>:
Use this to specify how many instructions you want to execute after the
warmup period is over.  After the simulation period is over, the simulator
will exit and IPC since the warmup period will be printed.
Default value is 100,000,000.

* -hide_heartbeat:
Normally, a heartbeat message is printed every 100,000 instructions, which
shows the IPC since the last heartbeat message, as well as the cummulative
IPC of the program so far.  The cummulative IPC displayed by the heartbeat
function is NOT affected by the reset after the warmup period.

For the championship, your prefetcher's performance will be measured in 
four configurations:

1. No command line switches set
2. -small_llc
3. -low_bandwidth
4. -scramble_loads

You can combine the switches for your testing purposes, but the championship
will only look at the four configurations mentioned above.
