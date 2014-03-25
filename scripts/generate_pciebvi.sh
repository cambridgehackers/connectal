#
set -x
set -e
scripts/importbvi.py -o PCIEWRAPPER.bsv -I PcieWrap -P PcieWrap \
    -n pl_link_partner_gen2_supported \
    -n cfg_mgmt_wr_rw1c_as_rw \
    -n pipe_gen3_out \
    -n pipe_userclk1_in \
    -n pipe_userclk2_in \
    -n pl_link_gen2_cap \
    -f cfg_aer_rooterr -f cfg_msg \
-f cfg_root_control \
-f cfg_interrupt \
-f cfg_err \
-f cfg_mgmt \
-f cfg_pmcsr \
-f cfg_pm \
-f cfg_ds \
-f cfg_aer \
-f pipe \
-f pl_link \
-f pcie_drp \
-f pci_exp \
    xilinx/pcie_7x_v2_1/synth/pcie_7x_0.v
