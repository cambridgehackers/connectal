source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

puts $boardname
set prj_boardname $boardname
if [string match "*g2" $boardname] {set prj_boardname [string trimright $boardname "g2"]}

connectal_synth_ip axi_intc 4.1 axi_intc_0 [list CONFIG.C_NUM_INTR_INPUTS {16} CONFIG.C_S_AXI_ACLK_FREQ_MHZ {250.0} CONFIG.C_NUM_SW_INTR {0}]
