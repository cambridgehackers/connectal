source "board.tcl"
source "$xbsvdir/scripts/xbsv-synth-ip.tcl"

xbsv_synth_ip mig_7series 2.0 ddr3 [list CONFIG.XML_INPUT_FILE "$xbsvdir/xilinx/constraints/$boardname-ddr3.prj" CONFIG.RESET_BOARD_INTERFACE {Custom} CONFIG.MIG_DONT_TOUCH_PARAM {Custom} CONFIG.BOARD_MIG_PARAM {Custom}]
