============
Installation
============

Installing Connectal from Packages
-----------------------------------

On Ubuntu systems, connectal may be installed from pre-built packages::

    sudo add-apt-repository -y ppa:jamey-hicks/connectal
    sudo apt-get update
    sudo apt-get -y install connectal


Installing Connectal from Source
--------------------------------

Connectal source comes from three repositories::

    git clone git://github.com/cambridgehackers/connectal
    git clone git://github.com/cambridgehackers/fpgamake
    git clone git://github.com/cambridgehackers/buildcache

To use Connectal to build hardware/software applications, some additional packages are required::

    cd connectal; sudo make install-dependences

Installing Connectal and Bluespec on CentOS 7
---------------------------------------------

The following dependencies were needed on CentOS::

    sudo yum install gmp glibc-devel autoconf gperf compat-libstdc++-33

CentOS does not have an iverilog packages, but it can be build from
source, following the instructions in its repository:

  * https://github.com/steveicarus/iverilog.git


Installing Connectal Drivers and PCI Express Utilities:
-------------------------------------------------------

To run Connectal applications on FPGAs attached via PCI Express, a
couple of device drivers have to be built and installed::

   cd connectal; make all && sudo make install

In addition, you will need to build and install fpgajtag and pciescan::

    git clone git://github.com/cambridgehackers/pciescan
    (cd pciescan; make && sudo make install)
    
    git clone git://github.com/cambridgehackers/fpgajtag
    (cd fpgajtag; make && sudo make install)


Installing Vivado
-----------------
    
Download Vivado from Xilinx:

    http://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2015-4.html

Connectal builds do not use the Vivado SDK.

Installing Ubuntu on Zynq (Zedboard, etc)
-----------------------------------------

The shorthand instructions are:

  * Follow the instructions to install Ubuntu for Raspberry Pi 2 on and SD Card
  * Copy a Zedboard boot.bin to the first (VFAT) partition of the SD Card
  * Boot the Zedboard
  * Default password for user "ubuntu" is "ubuntu"

Toolchain
^^^^^^^^^

Zynq contains dual ARM Cortex A9 cores, which are 32-bit processors
using the ARMv7 instruction set. They are compatible with the
toolchain used for Raspberry Pi 2, which has prefix
"arm-linux-gnueabihf".

The "eabi" suffix indicates the ARM extended application binary
interface standard.

The "hf" suffix indicates that the toolchain generates floating point
instructions rather than subroutine calls to emulate floating point,
because not all 32-bit ARM processors have floating point units.

Download the base image
^^^^^^^^^^^^^^^^^^^^^^^

Download the Ubuntu SD card image:
   * http://cdimage.ubuntu.com/ubuntu/releases/16.04/release/ubuntu-16.04-preinstalled-server-armhf+raspi2.img.xz

Which is referenced on this page:
   * https://wiki.ubuntu.com/ARM/RaspberryPi

Formatting and SD Card for Ubuntu
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Ubuntu 16.04 uses filesystem labels to determine which partitions to mount. There should be two partitions, with the following labels:

   * system-boot The first partition should be vfat so that the
     firmware in the Zynq ROM can read it to find boot.bin. The
     following command will format the partition and label it::

     mkfs -t vfat -n system-boot /dev/sdb1

   * cloudimg-rootfs The second partition should be a Linux filesystem
     (default ext4) containing the ubuntu installation. The following
     two commands will format a partition and label it::

       mkfs -t ext4 /dev/sdb2
       e2label /dev/sdb2 cloudimg-rootfs


Install a boot.bin file
^^^^^^^^^^^^^^^^^^^^^^^

See the instructions at https://github.com/cambridgehackers/zynq-boot

Configuring a Linux Kernel for Ubuntu 16.04
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

I had to change the kernel configuration to suppport systemd, the init
system used in Ubuntu 16.04.

To be written ...


