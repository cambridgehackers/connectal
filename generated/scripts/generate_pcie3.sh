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
   -n sys_reset \
   -r sys_reset \
   -n sys_clk \
   -c sys_clk \
   -n user_clk \
   -c user_clk \
   -n user_reset \
   -r user_reset \
   -n int_dclk_out \
   -c int_dclk_out \
   -n int_oobclk_out \
   -c int_oobclk_out \
   -n int_pipe_rxusrclk_out \
   -c int_pipe_rxusrclk_out \
   -n int_qplloutclk_out \
   -c int_qplloutclk_out \
   -n int_rxoutclk_out \
   -c int_rxoutclk_out \
   -n int_userclk1_out \
   -n int_userclk2_out \
   -c int_userclk1_out \
   -c int_userclk2_out \
   -f \
   pipe_userclk1 \
   -f \
   pipe_userclk2 \
   -f \
   cfg_mgmt_type1 \
   -f \
   cfg_req_pm_transition \
   -f pci_exp \
   -f pipe \
   -o \
   ../xilinx/PCIEWRAPPER3.bsv \
   ../../out/nfsume/pcie3_7x_0/pcie3_7x_0_stub.v

# remove junk emitted into "import BVI ="
sed -i 's/(pci_exp_txn,//' PCIEWRAPPER3.bsv

# move user_clk and user_reset to top in place of boilerplate default_clock and default_reset
sed -i 's/output_clock user_clk(user_clk);//' PCIEWRAPPER3.bsv
sed -i 's/output_reset user_reset(user_reset);//' PCIEWRAPPER3.bsv
sed -i 's/default_clock clk();/output_clock user_clk(user_clk);/' PCIEWRAPPER3.bsv
sed -i 's/default_reset rst();/output_reset user_reset(user_reset);/' PCIEWRAPPER3.bsv
# remove extra reset
sed -i 's/Reset sys_clk_reset, //' PCIEWRAPPER3.bsv
sed -i 's/input_reset sys_clk_reset() = sys_clk_reset;//' PCIEWRAPPER3.bsv

# make sys_clk and sys_reset the default
sed -i 's/input_clock sys_clk/default_clock sys_clk/' PCIEWRAPPER3.bsv
sed -i 's/input_reset sys_reset/default_reset sys_reset/' PCIEWRAPPER3.bsv

# add clocked_by user_clk 
sed -i 's/method cfg[^;]*/& clocked_by (user_clk) reset_by (user_reset)/' PCIEWRAPPER3.bsv
sed -i 's/method ds[^;]*/& clocked_by (user_clk) reset_by (user_reset)/' PCIEWRAPPER3.bsv
sed -i 's/method m_axis[^;]*/& clocked_by (user_clk) reset_by (user_reset)/' PCIEWRAPPER3.bsv
sed -i 's/method s_axis[^;]*/& clocked_by (user_clk) reset_by (user_reset)/' PCIEWRAPPER3.bsv
sed -i 's/method pcie_[^;]*/& clocked_by (user_clk) reset_by (user_reset)/' PCIEWRAPPER3.bsv
sed -i 's/method user_[^;]*/& clocked_by (user_clk) reset_by (user_reset)/' PCIEWRAPPER3.bsv
sed -i 's/method[^;]*EN_[^;]*/& clocked_by (user_clk) reset_by (user_reset)/' PCIEWRAPPER3.bsv
# fix the double edited lines
sed -i 's/clocked_by (user_clk) reset_by (user_reset) clocked_by (user_clk) reset_by (user_reset)/clocked_by (user_clk) reset_by (user_reset)/'  PCIEWRAPPER3.bsv

# now the pcie clocks
sed -i 's/\(method rx[^;]*\)clocked_by[^;]*/\1 clocked_by (sys_clk) reset_by (sys_reset)/' PCIEWRAPPER3.bsv
sed -i 's/method pci_exp_tx[^;]*/& clocked_by (sys_clk) reset_by (sys_reset)/' PCIEWRAPPER3.bsv


