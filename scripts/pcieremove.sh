#
sudo rmmod pcieportal
sudo sh -c "echo 1 >/sys/bus/pci/devices/0000:01:00.0/remove"
sudo sh -c "echo 1 >/sys/bus/pci/rescan"
