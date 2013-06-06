#/bin/bash
set -e
set -x
#make verilog
#make hdmidisplay.make
##########################   make -f hdmidisplay.make bits
######## platgen -p xc7z020clg484-1 -lang verilog -intstyle default   -toplevel no -ti hdmidisplay_i -msg __xps/ise/xmsgprops.lst hdmidisplay.mhs
mkdir -p synthesis/xst_temp_dir implementation hdl
cp -r ../after_platgen/hdl/* hdl/
cp ../after_platgen/implementation/hdmidisplay.bmm implementation/
echo "hdmidisplay_processing_system7_0_wrapper
    hdmidisplay_axi_master_interconnect_0_wrapper
    hdmidisplay_axi_slave_interconnect_0_wrapper
    hdmidisplay_axi_slave_interconnect_1_wrapper
    hdmidisplay_hdmidisplay_0_wrapper
    hdmidisplay" | while read name ; do
        (cd synthesis; ../../scripts/run_xst.sh $name)
done
cp -f data/hdmidisplay.ucf implementation/hdmidisplay.ucf
#########xflow -wd implementation -p xc7z020clg484-1 -implement xflow.opt hdmidisplay.ngc
(cd implementation; ../../scripts/run_par.sh hdmidisplay xc7z020clg484-1)
xilperl /home/jamey/Xilinx/14.3/ISE_DS/EDK/data/fpga_impl/observe_par.pl -error no implementation/hdmidisplay.par

cp -f etc/bitgen.ut implementation/bitgen.ut
(cd implementation ; bitgen -w -f bitgen.ut hdmidisplay )
