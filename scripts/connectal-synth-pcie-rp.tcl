source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"
source "$scriptsdir/../../fpgamake/tcl/ipcore.tcl"

connectal_synth_ip pcie_7x 3.0 pcie_7x_rp [list CONFIG.Device_Port_Type {Root_Port_of_PCI_Express_Root_Complex} CONFIG.Maximum_Link_Width {X8} CONFIG.Link_Speed {5.0_GT/s} CONFIG.PCIe_Cap_Slot_Implemented {true} CONFIG.Xlnx_Ref_Board {VC707} CONFIG.en_ext_pipe_interface {true}]
