#
set -x
set -e
scripts/importbvi.py -o Bufgctrl.bsv -C BUFGCTRL -I Bufgctrl -P Bufgctrl \
    ../../import_components/Xilinx/Vivado/2013.2/data/parts/xilinx/zynq/zynq.lib

