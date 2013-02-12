
The script genxpsprojfrombsv enables you to take a Bluespec System
Verilog (BSV) file and generate a bitstream for a Xilinx Zynq FPGA. 

It generates C++ and BSV stubs so that you can write code that runs on
the Zynq's ARM CPUs to interact with your BSV componet.

== Example

For example, to create an HDMI frame buffer from the example code:

    ./genxpsprojfrombsv -p xpsproj -b HdmiDisplay bsv/TypesAndInterfaces.bsv bsv/HdmiDisplay.bsv

To generate the bitstream:

    make -C xpsproj bits

The first time, this will launch the XPS GUI, but only so that it will
generate some makefiles. Quit from the XPS GUI once it has loaded the
design and the build process will continue.

The result .bit file for this example will be:

    xpsproj/data/hdmidisplay.bit


== Installation

Install the python-ply package, e.g.,

    sudo apt-get install python-ply

PLY's home is http://www.dabeaz.com/ply/
