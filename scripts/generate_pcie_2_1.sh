#
set -x
set -e
scripts/importbvi.py -o PCIE_2_1.bsv -C PCIE_2_1 -P PCIE2 -I Pcie2 \
    -f CFGDEVCONTROL \
    -n CFGMGMTWRRW1CASRWN -n CFGPMRCVASREQL -n CFGPMRCVENTERL \
    -n LL2 -n PL2 -n TL2 -n PLLINKGEN -n PLLINKPARTNERGEN \
    /scratch/Xilinx/Vivado/2013.2/data/parts/xilinx/zynq/zynq.lib

# -I BscanE2 -c DRCK -c TCK --param=JTAG_CHAIN \

