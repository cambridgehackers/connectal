CONNECTAL Support for Partial Reconfiguration
=========================================

CONNECTAL supports partial reconfiguration on pcie-based platforms (kc705
and vc707). There's not enough static logic on the zedboard to make
this worthwhile at the moment.

Run connectalgen as usual to create the project directory.

Create proxies, wrappers, scripts, and Makefiles:

    cd examples/echo
    connectalgen -Bkc705 -p kc705 -x mkPcieTop -s2h Say -h2s Say -s test.cpp -t ../../bsv/StdPcieTop.bsv  Say.bsv

Compile the full bitstream:

    cd kc705
    make verilog
    make partial ## generates full and partial bitstreams
    make program ## loads the full bitstream

Now reboot to configure the PCIe endpoint

    sudo shutdown -r now

Now you can edit the source code, recompile, and generate a new partial bitstream:

    ## edit the BSV
    make verilog
    make partial

Load the partial bitstream:

    make reprogram

This also calls "connectalutil reset /dev/fpga0" to reset the portals in the design. No reboot required.

