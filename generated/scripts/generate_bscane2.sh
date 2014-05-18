#
set -x
set -e
scripts/importbvi.py -o BscanE2.bsv -C BSCANE2 -I BscanE2 -P PPS7 -c DRCK -c TCK --param=JTAG_CHAIN \
    ../../import_components/Xilinx/Vivado/2013.2/data/parts/xilinx/zynq/zynq.lib

