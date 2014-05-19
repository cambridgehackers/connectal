#
set -x
set -e
scripts/importbvi.py -o Bufgctrl.bsv -C BUFGCTRL -I Bufgctrl -P Bufgctrl \
    -c I0 -c I1 -c O \
    ../../import_components/Xilinx/Vivado/2013.2/data/parts/xilinx/zynq/zynq.lib

