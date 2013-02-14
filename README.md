XBSV
====

The script genxpsprojfrombsv enables you to take a Bluespec System
Verilog (BSV) file and generate a bitstream for a Xilinx Zynq FPGA. 

It generates C++ and BSV stubs so that you can write code that runs on
the Zynq's ARM CPUs to interact with your BSV componet.

Example
-------

For example, to create an HDMI frame buffer from the example code:

    ./genxpsprojfrombsv -p xpsproj -b HdmiDisplay bsv/TypesAndInterfaces.bsv bsv/HdmiDisplay.bsv

To generate the bitstream:

    make -C xpsproj bits

The first time, this will launch the XPS GUI, but only so that it will
generate some makefiles. Quit from the XPS GUI once it has loaded the
design and the build process will continue.


The result .bit file for this example will be:

    xpsproj/data/hdmidisplay.bit


Installation
------------

Install the python-ply package, e.g.,

    sudo apt-get install python-ply

PLY's home is http://www.dabeaz.com/ply/

A note on the use of the XPS GUI
---------------------------------

Not only is there not a working GUI-free design flow, but in order to
change the processing clock from the default (50MHz) you have to use
the GUI and change it in the Zynq tab by clicking on "Clock
generation" and then configuring CLK0 in the "PL Clocks" section.

Setting up the SD Card
----------------------

1. Download http://code.google.com/p/xbsv/downloads/detail?name=sdcard-130214.tar.bz
2. tar -jxvf sdcard-130214.tar.bz
3. Assuming the card shows up as /dev/sdc:
   sudo umount /dev/sdc
   sudo umount /dev/sdc1
   sudo mkdosfs -I -n zynq /dev/sdc
4. Unplug the card and plug it back in
5. cd sdcard-130214; cp boot.bin devicetree.dtb ramdisk8M.image.gz zImage system.img /media/zynq
5. sync
   sudo umount /dev/sdc

Eject the card and plug it into the zc702 and boot.
