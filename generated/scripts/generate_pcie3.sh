#

set -x
set -e
../scripts/importbvi.py \
   -I \
   Pcie3Wrap \
   -P \
   pcie3Wrap \
   -f \
   pipe_gen3 \
   -f \
   pipe_userclk1 \
   -f \
   pipe_userclk2 \
   -f \
   cfg_mgmt_type1 \
   -f \
   cfg_req_pm_transition_l23 \
   -o \
   ../xilinx/PCIE3.bsv \
   ../../out/netfpgasume/pcie3_7x_0/pcie3_7x_0_stub.v
