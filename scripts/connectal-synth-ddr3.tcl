source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

connectal_synth_ip mig_7series 2.3 ddr3 [list CONFIG.XML_INPUT_FILE "$connectaldir/constraints/xilinx/$boardname-ddr3.prj" CONFIG.RESET_BOARD_INTERFACE {Custom} CONFIG.MIG_DONT_TOUCH_PARAM {Custom} CONFIG.BOARD_MIG_PARAM {Custom}]
