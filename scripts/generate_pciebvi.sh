#
set -x
set -e
scripts/importbvi.py -o pcie.test -I pcie -P foopref \
    -n pl_link_partner_gen2_supported \
    -n cfg_mgmt_wr_rw1c_as_rw \
    -n pipe_gen3_out \
    -n pipe_userclk1_in \
    -n pipe_userclk2_in \
    -n pl_link_gen2_cap \
    xilinx/pcie_7x_v2_1/synth/pcie_7x_0.v
