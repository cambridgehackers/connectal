#
set -x
set -e
../scripts/importbvi.py -o PCIEWRAPPER.bsv -I PcieWrap -P PcieWrap \
    -n pl_link_partner_gen2_supported \
    -n cfg_mgmt_wr_rw1c_as_rw \
    -n pipe_gen3_out \
    -n pipe_userclk1_in \
    -n pipe_userclk2_in \
    -n pl_link_gen2_cap \
    -c user_clk_out -r user_reset_out \
    -c sys_clk -r sys_rst_n \
    -f cfg_aer -f cfg_ds -f cfg_err -f cfg_interrupt \
    -f cfg_mgmt -f cfg_msg -f cfg_pmcsr -f cfg_pm \
    -f cfg_root_control \
    -f pipe -f pl_link -f pci_exp -f pcie_drp \
    -p lanes \
    ../../out/vc707/pcie_7x_0/synth/pcie_7x_0.v

#    xilinx/pcie_7x_v2_1/synth/pcie_7x_0.v
