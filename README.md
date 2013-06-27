XBSV
====

The script genxpsprojfrombsv enables you to take a Bluespec System
Verilog (BSV) file and generate a bitstream for a Xilinx Zynq FPGA. 

It generates C++ and BSV stubs so that you can write code that runs on
the Zynq's ARM CPUs to interact with your BSV componet.

Preparation
-----------
1. Get xilinx tools
2. Download ndk toolchain from: 
     http://developer.android.com/tools/sdk/ndk/index.html
     (actual file might be:
         http://dl.google.com/android/ndk/android-ndk-r8e-linux-x86_64.tar.bz2
     )
3. Get the Zynq Base TRD files, which will contain zynq_fsbl.elf and u-boot.elf
     See: http://www.wiki.xilinx.com/Zynq+Base+TRD+14.3
     (this will require a xilinx login)
   Or:
      git clone git://github.com/cambridgehackers/zynq-axi-blue.git

Setting up the SD Card
----------------------

1. Download http://xbsv.googlecode.com/files/sdcard-130611.tar.bz
2. tar -jxvf sdcard-130611.tar.bz
3. Assuming the card shows up as /dev/sdc:

   sudo umount /dev/sdc
   sudo umount /dev/sdc1
   sudo mkdosfs -I -n zynq /dev/sdc

It does not seem to boot from cards with a partition table.

4. Unplug the card and plug it back in
5. Copy files
   cd sdcard-130611
   cp boot.bin devicetree.dtb ramdisk8M.image.gz zImage system.img /media/zynq
   cp empty.img /media/zynq/userdata.img
5. sync
   sudo umount /dev/sdc

Eject the card and plug it into the zc702 and boot.

Echo Example
------------

    ./genxpsprojfrombsv -B zedboard -p echoproj -b Echo examples/echo/Echo.bsv
or
    ./genxpsprojfrombsv -B zc702 -p echoproj -b Echo examples/echo/Echo.bsv
    cd echoproj
    make verilog
    make bits
    cp examples/echo/testecho.cpp echoproj/jni
    make -C echoproj boot.bin
    ndk-build -C echoproj

    adb push echoproj/echo.bit.bin.gz /mnt/sdcard
    adb push echoproj/libs/armeabi/testecho /data/local

The first time, this will launch the XPS GUI, but only so that it will
generate some makefiles. Quit from the XPS GUI once it has loaded the
design and the build process will continue.

Loading the bitfile on the device:
    mknod /dev/xdevcfg c 259 0
    cat /sys/devices/amba.0/f8007000.devcfg/prog_done
    zcat /mnt/sdcard/echo.bit.bin.gz > /dev/xdevcfg
    cat /sys/devices/amba.0/f8007000.devcfg/prog_done
    chmod agu+rwx /dev/fpga0

When we run it on the device:
    / # /data/local/testecho 
    Mapped device fpga0 at 0xb6f4b000
    Saying 42
    PortalInterface::exec()
    heard 42


HDMI Example
------------

For example, to create an HDMI frame buffer from the example code:

To generate code for Zedboard:
    ./genxpsprojfrombsv -B zedboard -p xpsproj -b HdmiDisplay bsv/HdmiDisplay.bsv

To generate code for a ZC702 board:
    ./genxpsprojfrombsv -B zc702 -p xpsproj -b HdmiDisplay bsv/HdmiDisplay.bsv

To generate the bitstream:

    make -C xpsproj bits

The result .bit file for this example will be:

    xpsproj/data/hdmidisplay.bit


Installation
------------

Install the bluespec compiler. Make sure the BLUESPECDIR environment
variable is set:
    export BLUESPECDIR=~/bluespec/Bluespec-2012.10.beta2/lib
	
Install the python-ply package, e.g.,

    sudo apt-get install python-ply

PLY's home is http://www.dabeaz.com/ply/

