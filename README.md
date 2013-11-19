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

    ## this has only been tested with the Vivado 2013.2 release
    . Xilinx/Vivado/2013.2/settings64.sh

    ./genxpsprojfrombsv -B zedboard -p echoproj -b Echo examples/echo/Echo.bsv
or
    ./genxpsprojfrombsv -B zc702 -p echoproj -b Echo examples/echo/Echo.bsv
or
    ./genxpsprojfrombsv -B kc705 -p k7echoproj --make=verilog -b Echo examples/echo/Echo.bsv
or
    ./genxpsprojfrombsv -B vc707 -p v7echoproj --make=verilog -b Echo examples/echo/Echo.bsv

    cd echoproj
    make verilog

    ## after 'make bits', the .bit and .bin files will be in:
    ##     echo.runs/impl_1/
    ##         echo_top_1.bit
    ##         echo_top_1.bin
    make bits

    ## this step requires promgen from Xilinx ISE 14.3
    make echo.bit.bin.gz

    ## building the test executable
    cp examples/echo/testecho.cpp echoproj/jni
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

Memcpy Example
--------------

    ./genxpsprojfrombsv -B vc707 -p memcpyproj -b Memcpy examples/memcpy/Memcpy.bsv bsv/BlueScope.bsv bsv/AxiDMA.bsv


LoadStore Example
------------

    ## this has only been tested with the Vivado 2013.2 release
    . Xilinx/Vivado/2013.2/settings64.sh

    ./genxpsprojfrombsv -B kc705 -p loadstoreproj -b LoadStore examples/loadstore/LoadStore.bsv
or
    ./genxpsprojfrombsv -B vc707 -p loadstoreproj -b LoadStore examples/loadstore/LoadStore.bsv

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

ReadBW
------

    ./genxpsprojfrombsv -B vc707 -p readbwproj -b ReadBW examples/readbw/ReadBW.bsv
or
    ./genxpsprojfrombsv -B kc705 -p readbwproj -b ReadBW examples/readbw/ReadBW.bsv


HDMI Example
------------

For example, to create an HDMI frame buffer from the example code:

To generate code for Zedboard:
    ./genxpsprojfrombsv -B zedboard -p xpsproj -b HdmiDisplay bsv/HdmiDisplay.bsv bsv/PortalMemory.bsv

To generate code for a ZC702 board:
    ./genxpsprojfrombsv -B zc702 -p xpsproj -b HdmiDisplay bsv/HdmiDisplay.bsv bsv/PortalMemory.bsv

To generate the bitstream:

    make -C xpsproj bits hdmidisplay.bit.bin.gz

The result .bit file for this example will be:

    xpsproj/hdmidisplay.bit.bin.gz

Sending the bitfile:
    adb push xpsproj/hdmidisplay.bit.bin.gz /mnt/sdcard

Loading the bitfile on the device:
    mknod /dev/xdevcfg c 259 0
    cat /sys/devices/amba.0/f8007000.devcfg/prog_done
    zcat /mnt/sdcard/hdmidisplay.bit.bin.gz > /dev/xdevcfg
    cat /sys/devices/amba.0/f8007000.devcfg/prog_done
    chmod agu+rwx /dev/fpga0

On the zedboard, configure the adv7511:
   echo RGB > /sys/bus/i2c/devices/1-0039/format
On the zc702, configure the adv7511:
   echo RGB > /sys/bus/i2c/devices/0-0039/format

Restart surfaceflinger:
   stop surfaceflinger; start surfaceflinger

Sometimes multiple restarts are required.

Imageon Example
---------------

This is an example using the Avnet Imageon board and ZC702 (not tested with Zedboard yet):

To generate code for a ZC702 board:
    git clone /lab/asic/imageon ../imageon
    ./genxpsprojfrombsv  -B zc702 -p fooproj -x HDMI LEDS ImageonVita ImageonTopPins ImageonSerdesPins FmcImageonInterface SpiPins ImageonPins -b ImageCapture examples/imageon/ImageCapture.bsv bsv/BlueScope.bsv bsv/PortalMemory.bsv

Test program:
    cp examples/imageon/testimagecapture.cpp fooproj/jni
    cp examples/imageon/i2c*h fooproj/jni
    ndk-build -C fooproj

Installation
------------

Install the bluespec compiler. Make sure the BLUESPECDIR environment
variable is set:
    export BLUESPECDIR=~/bluespec/Bluespec-2012.10.beta2/lib
	
Install the python-ply package, e.g.,

    sudo apt-get install python-ply

PLY's home is http://www.dabeaz.com/ply/

Portal Driver
-------------

To Build the portal driver, Makefile needs to be pointed to the root of the kernel source tree:
   export DEVICE_XILINX_KERNEL=/scratch/mdk/device_xilinx_kernel/

The driver sources are located in the xbsv project:
   cd xbsv/drivers/portal && make portal.ko

[ an alternate way to write command line:
   (cd drivers/portal/; DEVICE_XILINX_KERNEL=`pwd`/../../../device_xilinx_kernel/ make portal.ko)
   adb push drivers/portal/portal.ko /mnt/sdcard
]

To update the driver running on the Zync platform, set ADB_PORT appropriately and run the following commands:
   adb -s $ADB_PORT push portal.ko /mnt/sdcard/
   adb -s $ADB_PORT shell "cd /mnt/sdcard/ && uname -r | xargs rm -rf"
   adb -s $ADB_PORT shell "cd /mnt/sdcard/ && uname -r | xargs mkdir"
   adb -s $ADB_PORT shell "cd /mnt/sdcard/ && uname -r | xargs mv portal.ko"
   adb -s $ADB_PORT shell "modprobe -r portal"
   adb -s $ADB_PORT shell "modprobe portal"
