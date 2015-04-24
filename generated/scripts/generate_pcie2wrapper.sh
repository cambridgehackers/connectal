#
set -x
set -e
../scripts/importbvi.py -o PCIEWRAPPER2.bsv -I PcieWrap -P PcieWrap \
    -n pl_link_partner_gen2_supported \
    -n cfg_mgmt_wr_rw1c_as_rw \
    -n pipe_gen3_out \
    -n pipe_userclk1_in \
    -n pipe_userclk2_in \
    -n pl_link_gen2_cap \
    -n int_userclk1_out \
    -n int_userclk2_out \
    -n int_ \
    -c int_userclk1_out \
    -c int_userclk2_out \
    -c int_oobclk_out \
    -c int_dclk_out \
    -c int_pclk_out_slave \
    -c int_pipe_rxuserclk_out \
    -c int_qplloutclk_out \
    -c int_qplloutrefclk_out \
    -c int_rxoutclk_out \
    -n user_clk_out \
    -n user_reset_out \
    -c user_clk_out -r user_reset_out \
    -c sys_clk -r sys_rst_n \
    -n cfg_dsn -n cfg_dstatus \
    -f cfg_aer -f cfg_ds -f cfg_err -f cfg_interrupt \
    -f cfg_mgmt -f cfg_msg -f cfg_pmcsr -f cfg_pm \
    -f cfg_root_control \
    -f pipe -f pl_link -f pci_exp -f pcie_drp \
    -p lanes \
    ../../out/vc707/pcie2_7x_0/pcie2_7x_0_stub.v

# remove junk emitted into "import BVI ="
sed -i 's/(pci_exp_txp,//' PCIEWRAPPER2.bsv

# move user_clk_out and user_reset_out to top in place of boilerplate default_clock and default_reset
sed -i 's/output_clock user_clk_out(user_clk_out);//' PCIEWRAPPER2.bsv
sed -i 's/output_reset user_reset_out(user_reset_out);//' PCIEWRAPPER2.bsv
sed -i 's/default_clock clk();/output_clock user_clk_out(user_clk_out);/' PCIEWRAPPER2.bsv
sed -i 's/default_reset rst();/output_reset user_reset_out(user_reset_out);/' PCIEWRAPPER2.bsv
# remove extra reset
sed -i 's/Reset sys_clk_reset, //' PCIEWRAPPER2.bsv
sed -i 's/input_reset sys_clk_reset() = sys_clk_reset;//' PCIEWRAPPER2.bsv

# make sys_clk and sys_rst_n the default
sed -i 's/input_clock sys_clk/default_clock sys_clk/' PCIEWRAPPER2.bsv
sed -i 's/input_reset sys_rst_n/default_reset sys_rst_n/' PCIEWRAPPER2.bsv

# add clocked_by reset_by to methods
sed -i 's/method cfg[^;]*/& clocked_by (user_clk_out) reset_by (user_reset_out)/' PCIEWRAPPER2.bsv
sed -i 's/method fc[^;]*/& clocked_by (user_clk_out) reset_by (user_reset_out)/' PCIEWRAPPER2.bsv
sed -i 's/method m_axis[^;]*/& clocked_by (user_clk_out) reset_by (user_reset_out)/' PCIEWRAPPER2.bsv
sed -i 's/method s_axis[^;]*/& clocked_by (user_clk_out) reset_by (user_reset_out)/' PCIEWRAPPER2.bsv
sed -i 's/method pl_[^;]*/& clocked_by (user_clk_out) reset_by (user_reset_out)/' PCIEWRAPPER2.bsv
sed -i 's/method np_[^;]*/& clocked_by (user_clk_out) reset_by (user_reset_out)/' PCIEWRAPPER2.bsv
sed -i 's/method user_[^;]*/& clocked_by (user_clk_out) reset_by (user_reset_out)/' PCIEWRAPPER2.bsv
sed -i 's/method[^;]*EN_[^;]*/& clocked_by (user_clk_out) reset_by (user_reset_out)/' PCIEWRAPPER2.bsv
# fix the double edited lines
sed -i 's/clocked_by (user_clk_out) reset_by (user_reset_out) clocked_by (user_clk_out) reset_by (user_reset_out)/clocked_by (user_clk_out) reset_by (user_reset_out)/'  PCIEWRAPPER2.bsv

# now the pcie clocks
sed -i 's/\(method rx[^;]*\)clocked_by[^;]*/\1 clocked_by (sys_clk) reset_by (sys_rst_n)/' PCIEWRAPPER2.bsv
sed -i 's/method pci_exp_tx[^;]*/& clocked_by (sys_clk) reset_by (sys_rst_n)/' PCIEWRAPPER2.bsv
