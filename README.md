Connectal
====


Connectal provides a hardware-software interface for applications split
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
from which `connectalgen` generates BSV and C++ wrappers and
proxies.

Connectal has a mailing list:
   https://groups.google.com/forum/#!forum/connectal

See the documentation for more details:
   http://www.connectal.org/doc/current/ref/

Supported Platforms
-------------------

Connectal supports Android on Zynq platforms, including zedboard and zc702.

Connectal supports Linux on x86 with PCIe-attached Virtex and Kintex boards (vc707, kc705).

Connectal supports bluesim as a simulated hardware platform. 


Installation
------------

1. Install the Bluespec compiler. Connectal is known to work with 2014.07.A and 2015.05.beta1

Install the bluespec compiler. Make sure the BLUESPECDIR environment
variable is set appropriately:

    export BLUESPECDIR=~/bluespec/Bluespec-2014.07.A/lib

2. Install Vivado 2015.2 or 2015.4

3. Install Connectal

       sudo add-apt-repository -y ppa:jamey-hicks/connectal
       sudo apt-get update
       sudo apt-get -y install connectal

Building from Source
--------------------

1. Checkout out the following from github:

       git clone git://github.com/cambridgehackers/connectal

   If you are generating code for an FPGA, check out fpgamake:

       git clone git://github.com/cambridgehackers/fpgamake

   It appears that this requires buildcache to be checked out also:

       git clone git://github.com/cambridgehackers/buildcache

   Add `USE_BUILDCACHE=1` to your calls to make to enable it to cache, otherwise it will rerun all compilation steps.

2. Install connectal dependences. This installs ubuntu packages used by connectal or during compilation:

       cd connectal;
       sudo make install-dependences

3. If you are using an FPGA attached to your machine, install the drivers:

       make all
       sudo make install


Preparation for Zynq
--------------------

0. Get [http://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2015-2.html](Vivado 2015.2)


1. Download the Android Native Development Kit (NDK) from: 
     http://developer.android.com/tools/sdk/ndk/index.html
     (actual file might be:
         http://dl.google.com/android/ndk/android-ndk-r10e-linux-x86_64.tar.bz2
     )

   Connectal uses NDK to compile code to run on Zynq platforms.

   Add the NDK to your PATH.

       URL=http://dl.google.com/android/ndk/android-ndk-r10e-linux-x86_64.tar.bz2
       curl -O `basename $URL` $URL
       tar -jxvf `basename $URL`
       PATH=$PATH:/scratch/android-ndk-r10e/

2. Download and install ADB from the Android Development Tools.

   The Android Debug Bridge (adb) is packaged in platform-tools. Connectal
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

3. Create/obtain a boot.bin and SD card image for your board

Follow the instructions at https://github.com/cambridgehackers/zynq-boot

Copy the files to the SD card, eject the card from the PC, and plug it into the zedboard/zc702/zc706 and boot.


Preparation for Kintex and Virtex boards
----------------------------------------

0. Get [http://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2013-2.html](Vivado 2013.2)

1. Install the drivers

       make
       sudo make install
       sudo modprobe portalmem

2. Get fpgajtag

       git clone git://github.com/cambridgehackers/fpgajtag
       cd fpgajtag
       make all && sudo make install

Examples
--------

Generally cd to the project directory, then type

    cd examples/examplename
    make build.<target>
    make run.<target>

where target is

Command suffix | Function
--------------|----------
bluesim | compile for simulation
zedboard| compile for zedboard
zybo| compile for zybo
zc702| compile for zc702 board
zc706| compile for zc706 board
kc705| compile for kc705 board
vc707| compile for vc707 board
vc709| compile for vc709 board
nfsume| compile for NetFPGA-SUME board

To turn on more verbosity for debugging when running make,
add V=1 to command line, as

    make examples/examplename.<something> V=1
or

    V=1 make examples/examplename.<something>

To run the example on a machine different than the build machine, use RUNPARAM=hostname-or-addr:

    make RUNPARAM=zedtest run.zedboard
    make RUNPARAM=192.168.1.123 run.vc707

### Bitstream Packaging


The FPGA bitstream is included in the application executable, and the
FPGA is automatically programmed when the application is run:

    cd examples/echo
    make build.vc707
    ./vc707/bin/ubuntu.exe

We are running Android on the Zynq devices and so the application
executable is called android.exe.

### Echo Example


    ## this has only been tested with the Vivado 2013.2 release
    . Xilinx/Vivado/2013.2/settings64.sh

    make -C examples/echo build..zedboard
or

    make -C examples/echo build.zc702
or

    make -C examples/echo build.kc705
or

    make -C examples/echo build.vc707

To run on a zedboard with IP address aa.bb.cc.dd:

    RUNPARAM=aa.bb.cc.dd make -C examples/echo run.zedboard

### Memcpy Example

    make -C examples/memcpy build.vc707


[![Analytics](https://ga-beacon.appspot.com/UA-15845210-3/connectal/README.md)](https://github.com/igrigorik/ga-beacon)
