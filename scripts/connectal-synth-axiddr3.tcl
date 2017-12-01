source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

set prj_boardname $boardname
if [string match "*g2" $boardname] {set prj_boardname [string trimright $boardname "g2"]}

connectal_synth_ip mig_7series 4.0 axiddr3 [list CONFIG.XML_INPUT_FILE "$connectaldir/constraints/xilinx/$prj_boardname-axiddr3.prj" CONFIG.RESET_BOARD_INTERFACE {Custom} CONFIG.MIG_DONT_TOUCH_PARAM {Custom} CONFIG.BOARD_MIG_PARAM {Custom}]
