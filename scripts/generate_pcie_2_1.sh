#
set -x
set -e
scripts/importbvi.py -o PCIE_2_1.bsv -C PCIE_2_1 -P PCIE2 -I Pcie2 \
    -f CFGDEVCONTROL \
    -n CFGMGMTWRRW1CASRWN -n CFGPMRCVASREQL -n CFGPMRCVENTERL \
    -n LL2 -n PL2 -n TL2 -n PLLINKGEN -n PLLINKPARTNERGEN \
    -e 'PL_FAST_TRAIN:(params.fast_train_sim_only)?"TRUE":"FALSE"' \
    -e 'PCIE_EXT_CLK:"TRUE"' \
    -e "BAR0:32'hFFF00004" -e "BAR1:32'hFFFFFFFF" -e "BAR2:32'hFFF00004" -e "BAR3:32'hFFFFFFFF" \
    /scratch/Xilinx/Vivado/2013.2/data/parts/xilinx/zynq/zynq.lib

# -I BscanE2 -c DRCK -c TCK --param=JTAG_CHAIN \

#    --param=PL_FAST_TRAIN --param=PCIE_EXT_CLK \
#    --param=BAR0 --param=BAR1 --param=BAR2 --param=BAR3 \
