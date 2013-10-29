XBSV
====

The script genxpsprojfrombsv enables you to take a Bluespec System
Verilog (BSV) file and generate a bitstream for a Xilinx
Virtex7/Kintex FPGA attached via PCI Express.

It generates C++ and BSV stubs so that you can write code that runs on
the x86 CPUs to interact with your BSV componet.

Preparation
-----------
1. Get xilinx tools
2. Get bluespec tools
3. Patch bluespec using the file bluespec-pcie.patch

    patch -p1 -d $(BLUESPECDIR)/.. < bluespec-pcie.patch

LoadStore Example
------------

    ## this has only been tested with the Vivado 2013.2 release
    . Xilinx/Vivado/2013.2/settings64.sh

    ./genxpsprojfrombsv -B zedboard -p loadstoreproj -b LoadStore examples/loadstore/LoadStore.bsv

    ## building the test executable
    cd loadstoreproj/jni
    make

    ## that generates wrappers in directory "loadstoreproj", which we've packaged with PCIe specific bits

    cd examples/pcie-loadstore
    make verilog
    make vivado

    ## to install the bitfile
    make program

    ## build the drivers
    cd pcie/drivers/
    make && make insmod

    ## run the example
    ./loadstoreproj/jni/loadstore



