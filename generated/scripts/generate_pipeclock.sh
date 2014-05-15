#
set -e
set -x
./scripts/importbvi.py -o PipeClock.bsv -P pclk -I pclk -p pcie_lane \
    xilinx/7x/pcie/source/pcie_7x_0_pipe_clock.v 
