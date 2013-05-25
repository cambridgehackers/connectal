#
set -e
make verilog
make hdmidisplay.make
#cp ../xok4/__xps/system.xml __xps/
#cp ../xok4/data/ps7_hdmidisplay_prj.xml ./data/ps7_hdmidisplay_prj.xml
#touch __xps/hdmidisplay_routed
#
#
##########################   make -f hdmidisplay.make bits
echo "****************************************************"
echo "Creating system netlist for hardware specification.."
echo "****************************************************"
echo ZZZZ
echo platgen -p xc7z020clg484-1 -lang verilog -intstyle default   -toplevel no -ti hdmidisplay_i -msg __xps/ise/xmsgprops.lst hdmidisplay.mhs
#jcaecho "Running synthesis..."
#jcaecho ZZZZ
#jcabash -c "cd synthesis; ./synthesis.sh"
#jcaecho "*********************************************"
#jcaecho "Running Xilinx Implementation tools.."
#jcaecho "*********************************************"
#jcaecho ZZZZ
#jcacp -f data/hdmidisplay.ucf implementation/hdmidisplay.ucf
#jcacp -f etc/fast_runtime.opt implementation/xflow.opt
#jcaxflow -wd implementation -p xc7z020clg484-1 -implement xflow.opt hdmidisplay.ngc
#jcatouch __xps/hdmidisplay_routed
#jcaecho ZZZZ
#jcaxilperl /home/jamey/Xilinx/14.3/ISE_DS/EDK/data/fpga_impl/observe_par.pl -error no implementation/hdmidisplay.par
#jcaecho "*********************************************"
#jcaecho "Running Bitgen.."
#jcaecho "*********************************************"
#jcacp -f etc/bitgen.ut implementation/bitgen.ut
#jcacd implementation ; bitgen -w -f bitgen.ut hdmidisplay ; cd ..
