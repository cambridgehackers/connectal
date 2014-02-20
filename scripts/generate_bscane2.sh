#
set -x
set -e
scripts/importbvi.py -o bscane2.bsv -C BSCANE2 -I BscanE2 -c DRCK -c TCK --param=JTAG_CHAIN \
    /scratch/Xilinx/Vivado/2013.2/data/parts/xilinx/zynq/zynq.lib > generated/xilinx/BscanE2.bsv

