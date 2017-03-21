source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

set prj_boardname $boardname

connectal_synth_ip zynq_ultra_ps_e 2.0 zynq_ultra_ps_e_0 [list \
							  CONFIG.PSU__FPGA_PL1_ENABLE {1} \
							  CONFIG.PSU__USE__M_AXI_GP0 {1} \
							  CONFIG.PSU__USE__IRQ0 {1} \
							  CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {200} \
							  CONFIG.PSU__CRL_APB__PL1_REF_CTRL__FREQMHZ {200} \
							  CONFIG.PSU__USE__S_AXI_GP0 {1} \
							  CONFIG.PSU__USE__S_AXI_GP1 {1} \
							  CONFIG.PSU__USE__S_AXI_GP2 {1} \
							  CONFIG.PSU__USE__S_AXI_GP3 {1} \
							  CONFIG.PSU__USE__S_AXI_GP4 {1} \
							  CONFIG.PSU__USE__S_AXI_GP5 {1} \
							  CONFIG.PSU__USE__S_AXI_GP6 {1} \
							  CONFIG.PSU__USE__S_AXI_ACP {1} \
							  CONFIG.PSU__USE__S_AXI_ACE {1} \
							 ]
