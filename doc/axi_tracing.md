
## How to trace AXI bus transactions on the Zynq platform.

### Preparation

1. Connect a usb cable to either a linux box or Mac

2. Install openocd
      Linux: sudo apt-get install openocd
      Mac: sudo port install openocd

### Compile time

In the project makefile, add the line:
     XBSVFLAGS=--bscflags " -D TRACE_AXI"

This will compile ConnectableWithTrace to trace transactions into BRAM.

### After running the test:

1. run the script xbsv/jtag/run_trace.sh.

2. the trace output will be in the file trace.log.
