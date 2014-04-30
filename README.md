XBSV
====


XBSV provides a hardware-software interface for applications split
between user mode code and custom hardware in an FPGA.  Portal can
automatically build the software and hardware glue for a message based
interface and also provides for configuring and using shared memory
between applications and hardware. Communications between hardware and
software are provided by a bidirectional flow of events and regions of
memory shared between hardware and software.  Events from software to
hardware are called requests and events from hardware to software are
called indications, but in fact they are symmetric.

A logical request/indication pair is referred to as a portal".  An
application can make use of multiple portals, which may be specified
independently. A portal is specified by a BSV interface declaration,
from which `xbsvgen` generates BSV and C++ wrappers and
proxies.

XBSV has a mailing list:
   https://groups.google.com/forum/#!forum/xbsv


Supported Platforms
-------------------

XBSV supports Android on Zynq platforms, including zedboard and zc702.

XBSV supports Linux on x86 with PCIe-attached Virtex and Kintex boards (vc707, kc705).

XBSV supports bluesim as a simulated hardware platform. 

xbsvgen
-----------------

The script xbsvgen enables you to take a Bluespec System
Verilog (BSV) file and generate a bitstream for a Xilinx Zynq FPGA. 

It generates C++ and BSV stubs so that you can write code that runs on
the Zynq's ARM CPUs to interact with your BSV componet.

See [doc/xbsvgen.md](doc/xbsvgen.md) for a description of its options.

Preparation
-----------


Preparation for Zynq
--------------------

0. Get [http://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2013-2.html](Vivado 2013.2)

[Note]
XBSV for Zynq also works with 2013.4 and 2014.1.

1. Download the Android Native Development Kit (NDK) from: 
     http://developer.android.com/tools/sdk/ndk/index.html
     (actual file might be:
         http://dl.google.com/android/ndk/android-ndk-r9d-linux-x86_64.tar.bz2
     )

   XBSV uses NDK to compile code to run on Zynq platforms.

   Add the NDK to your PATH.

       URL=http://dl.google.com/android/ndk/android-ndk-r9d-linux-x86_64.tar.bz2
       curl -O `basename $URL` $URL
       tar -jxvf `basename $URL`
       PATH=$PATH:/scratch/android-ndk-r9d/

2. Download and install ADB from the Android Development Tools.

   The Android Debug Bridge (adb) is packaged in platform-tools. XBSV
   uses [adb](http://developer.android.com/tools/help/adb.html) to
   transfer files to and from the Zedboard over ethernet and to run
   commands on the Zedboard.

   User your browser to accept the conditions and download the SDK installation tarball:

       http://dl.google.com/android/android-sdk_r22.6.2-linux.tgz

   Unpack the installation tarball:

       tar -zxvf android-sdk_r22.6.2-linux.tgz

   Run the `android` tool to install SDK components

       ./android-sdk-linux/tools/android

   Deselect all components except for "Android SDK Platform-Tools" [(screenshot)](doc/android-sdk-screenshots/android-sdk-manager.png) and
   then click the "Install ... package" button to install [(screenshot)](doc/android-sdk-screenshots/android-sdk-license.png) and then
   accept the license. [(screenshot)](doc/android-sdk-screenshots/android-sdk-manager-log.png)

   Add adb to your path:

       PATH=$PATH:$PWD/android-sdk-linux/platform-tools

3. git clone git://github.com/cambridgehackers/zynq-boot.git

The boot.bin is board-specific, because the first stage boot loader
(fsbl) and the devicetree are both board-specific.

To build a boot.bin for a zedboard:

    make BOARD=zedboard all

Then copy sdcard-zedboard/* /media/sdcard

To build a boot.bin for a zc702:

   make BOARD=zc702 all

Then copy sdcard-zc702/* /media/sdcard

Eject the card and plug it into the zedboard/zc702 and boot.



== Preparation for Kintex and Virtex boards

0. Get [http://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2013-2.html](Vivado 2013.2)

1. Build the drivers

    cd drivers/pcieportal; make && sudo make install

2. Load the drivers

    cd drivers/pcieportal; make insmod

3. Install the Digilent cable driver

    cd /scratch/Xilinx/Vivado/2013.2/data/xicom/cable_drivers/lin64/digilent
    sudo ./install_digilent.sh


4. Get fpgajtag

    git clone git://github.com/cambridgehackers/fpgajtag
    cd fpgajtag
    make all && sudo make install

== Examples

=== Echo Example

    ## this has only been tested with the Vivado 2013.2 release
    . Xilinx/Vivado/2013.2/settings64.sh

    make echo.zedboard
or
    make echo.zc702
or
    make echo.kc705
or
    make echo.vc707

To run on a zedboard with IP address aa.bb.cc.dd:
    RUNPARAM=aa.bb.cc.dd make echo.zedrun

=== Memcpy Example

    BOARD=vc707 make -C examples/memcpy

=== HDMI Example

[Note]
This example does not work. -Jamey 4/29/2014.

For example, to create an HDMI frame buffer from the example code:

To generate code for Zedboard:
    make hdmidisplay.zedboard

To generate code for a ZC702 board:
    make hdmidisplay.zc702

The result .bit file for this example will be:

    examples/hdmi/zedboard/hw/mkHdmiZynqTop.bit.bin.gz

Sending the bitfile:
    adb push mkHdmiZynqTop.bit.bin.gz /mnt/sdcard

Loading the bitfile on the device:
    mknod /dev/xdevcfg c 259 0
    cat /sys/devices/amba.0/f8007000.devcfg/prog_done
    zcat /mnt/sdcard/mkHdmiZynqTop.bit.bin.gz > /dev/xdevcfg
    cat /sys/devices/amba.0/f8007000.devcfg/prog_done
    chmod agu+rwx /dev/fpga0

Restart surfaceflinger:
   stop surfaceflinger; start surfaceflinger

Sometimes multiple restarts are required.

=== Imageon Example

This is an example using the Avnet Imageon board and ZC702 (not tested with Zedboard yet):

To generate code for a ZC702 board:
    make imageon.zc702

Installation
------------

Install the bluespec compiler. Make sure the BLUESPECDIR environment
variable is set:
    export BLUESPECDIR=~/bluespec/Bluespec-2013.09.beta1/lib
	
Install the python-ply package, e.g.,

    sudo apt-get install python-ply

PLY's home is http://www.dabeaz.com/ply/

Zynq Hints
-------------

To remount /system read/write:

    mount -o rw,remount /dev/block/mmcblk0p1 /system


