
HDMI Example
~~~~~~~~~~~~~

[Note]
This example does not work. -Jamey 4/29/2014.

For example, to create an HDMI frame buffer from the example code:

To generate code for Zedboard:
    make examples/hdmidisplay.zedboard

To generate code for a ZC702 board:
    make examples/hdmidisplay.zc702

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
