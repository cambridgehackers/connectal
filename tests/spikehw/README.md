Spike Hardware
==============

This project provides hardware peripherals to spike, the RISC-V ISA
simulator.

TODO
----

 * device tree partitioning of flash
   * added to riscv_spikehw_defconfig (DONE)
   * device tree entry for flash works (DONE)
   * device tree entry for partitions works (registers)
   * vmlinux partition (DONE)
   * root partition (DONE)
 * spikehw registering a flash device with spike (DONE)
 * restore console input (wtf)
 * copy vmlinux to flash (via /etc/init.d/rc) (DONE?)
 * pass address of vmlinux in flash to bbl (in riscy version of riscv-pk)
 * boot vmlinux from flash to login prompt (DONE) (AGAIN)
 * copy root fs image to flash (DONE) (AGAIN)
 * boot linux to command prompt using flash root filesystem (DONE)
 * change /etc/default/rcS ROOTFS_READ_ONLY=yes (DONE)
 * boot linux to command prompt using flash for vmlinux and root filesystem (almost done)
 * modify spike to use portalmem for dram so DMA from FPGA works (via register_mem_allocator) (DONE)

 * modify spike so devices can raise interrupts (IMPLEMENTED)

 * enable boot loader to pass command line to linux
 * modify spike to boot from boot ROM if no executable passed as an argument
 * copy bbl from boot ROM to DRAM (see code in tests/spikehw/boot/ )
 * fix ioremap() so that all 128MB of flash can be mapped
 * switch to coreboot instead of bbl
 * ...

Building SpikeHW
----------------

To get the sources:

    git clone git://github.com/cambridgehackers/fpgamake
    git clone git://github.com/cambridgehackers/buildcache
    git clone git://github.com/cambridgehackers/connectal

I extended spike to enable devices to be registered from extlib's.

    git clone git://github.com/cambridgehackers/cambridgehackers/riscv-isa-sim

    cd connectal/tests/spikehw
    make build.vc707g2 test-spikehw.vc707g2

To test it, assuming connectal is installed:

    cd connectal/tests/spikehw
    ./test-spikehw.vc707g2

You should see output like the following:

    jamey@bdbm07:~/connectal/tests/spikehw$ ./test-spikehw.vc707g2
    buffer /home/jamey/connectal/tests/spikehw/vc707g2/bin/connectal.so
    fpgajtag: elf input file, len 1459190 class 2
    fpgajtag: unzip input file, len 1040655
    fpgajtag: Digilent:Digilent Adept USB Device:210203860922; bcd:700
    count 2/3 cortex -1 dcount 2 trail 0
    STATUS 00500018 done 0 release_done 0 eos 10 startup_state 4
    STATUS 00500018 done 0 release_done 0 eos 10 startup_state 4
    STATUS 0002107a done 0 release_done 0 eos 10 startup_state 0
    fpgajtag: Starting to send file
    fpgajtag: Done sending file
    fpgajtag: bypass already programmed ae
    STATUS 0002107a done 0 release_done 0 eos 10 startup_state 0
    Running /usr/bin/pciescan.sh
    + PATH=/home/jamey/work/build/tools/bin:/home/jamey/work/vendor/android-ndk-r10e:/home/jamey/work/build/tools/bin:/home/jamey/work/vendor/android-ndk-r10e:/home/jamey/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/scratch/Xilinx/Vivado/2015.4/bin:/scratch/bluespec/Bluespec-2015.05.beta1/bin:/scratch/android-ndk-r10e:/home/jamey/bin:/sbin
    ++ lspci -d 1be7:c100
    ++ sed -e 's/ .*//'
    + BLUEDEVICE=03:00.0
    + '[' 03:00.0 '!=' '' ']'
    + sh -c 'echo 1 >/sys/bus/pci/devices/0000:03:00.0/remove'
    + sleep 1
    + rmmod pcieportal
    + sleep 1
    + sh -c 'echo 1 >/sys/bus/pci/rescan'
    + sleep 1
    subprocess pid 16080 completed status=0 0
    [initPortalHardwareOnce:256] fd 6 len 0
    [checkSignature:154] read status from '/dev/connectal' was only 0 bytes long
    [dmaManagerOnce:44]
    axi eth status mmcm_locked=1 irq=0 intr sources=0
    word 0000 of boot ROM 00001137 (expected 00001137)
    word 0004 of boot ROM 010000ef (expected 010000ef)
    word 0008 of boot ROM 20000513 (expected 20000513)
    word 000c of boot ROM 00050067 (expected 00050067)
    word 0010 of boot ROM 0000006f (expected 0000006f)
    word 0014 of boot ROM 040007b7 (expected 040007b7)
    word 0018 of boot ROM 40078793 (expected 40078793)
    word 001c of boot ROM fc0005b7 (expected fc0005b7)
    AXI Ethernet Identification 09000000 (expected 09000000)
    SpikeHw::writeFlash offset=55 value=98
    Query flash 51.52.59 QRY (expected QRY)

The last five lines are the actual test output.

If the first word of the boot ROM is 0, then it is because bootromx4.hex is missing.

Linux Kernel
------------

The corresponding RISC-V Linux kernel is available here:
    git clone git://github.com/cambridgehackers/cambridgehackers/riscv-linux-4.1.y linux
    cd linux

    ## configure the kernel
    make ARCH=riscv riscv64_spikehw_defconfig

    ## build the kernel
    make ARCH=riscv

    ## build the device tree .dtb files
    make ARCH=riscv dtbs

BBL (in riscv-pk)
-----------------

I modified BBL to load an ELF file from physical memory (DRAM, boot
ROM, or NOR FLASH) when passed an address instead of a filename.

   git clone git://github.com/cambridgehackers/cambridgehackers/riscv-pk



Using Spike HW with Spike
-------------------------

Spike updated with register_device() available to extlibs:

    git clone git://github.com/cambridgehackers/cambridgehackers/riscv-isa-sim

See also the pull request: https://github.com/riscv/riscv-isa-sim/pull/37

To connect spikehw to the hardware:

    spike -extlib=/path/to/vc707g2/bin/connectal.so -m64 ...


