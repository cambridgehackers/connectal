
#  -c pl_clk0 -c pl_clk1 -r pl_resetn0
../scripts/importbvi.py -c maxihpm0_fpd_aclk -c maxihpm0_fpd_aclk -c saxihpc0_fpd_aclk -c saxiacp_fpd_aclk -c saxi_lpd_aclk -c saxihp0_fpd_aclk -c saxihp1_fpd_aclk -c saxihp2_fpd_aclk -c saxihp3_fpd_aclk -c sacefpd_aclk -c maxihpm0_lpd_aclk -I PS8 -P PS8 -o ZYNQ_ULTRA.bsv ../../out/zcu102/zynq_ultra_ps_e_0/zynq_ultra_ps_e_0_stub.v

sed -i 's/zynq_ultra_ps_e_0(maxihpm0_fpd_aclk,/zynq_ultra_ps_e_0/' ZYNQ_ULTRA.bsv
sed -i 's/default_clock clk()/default_clock no_clock/' ZYNQ_ULTRA.bsv
sed -i 's/default_reset rst()/default_reset no_reset/' ZYNQ_ULTRA.bsv
sed -i 's/input_reset.*;//' ZYNQ_ULTRA.bsv
sed -i 's/, Reset .*reset//' ZYNQ_ULTRA.bsv
##sed -i 's/method maxigp0[^;]*/& clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset)/' ZYNQ_ULTRA.bsv
sed -i 's/method [a-z][^;]*/& clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset)/' ZYNQ_ULTRA.bsv
