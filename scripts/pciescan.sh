#!/bin/bash
set -x
# invalidate existing device (so that scan will look for new one)
BLUEDEVICE=`lspci -d 1be7:c100 | sed -e "s/ .*//"`
if [ "$BLUEDEVICE" != "" ]; then
    sudo sh -c "echo 1 >/sys/bus/pci/devices/0000:$BLUEDEVICE/remove"
fi
#sudo sh -c "echo 1 >/sys/bus/pci/devices/0000:01:00.0/remove"
# remove existing driver, since there is some bug in the 'remove'
# function, causing the driver to become unmapped although
# it is still registered (and causing a segv on the probe call)
sudo rmmod pcieportal
sudo sh -c "echo 1 >/sys/bus/pci/rescan"
#lspci -vv -d 1be7:c100
