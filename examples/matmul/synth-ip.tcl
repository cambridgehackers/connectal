source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

connectal_synth_ip floating_point 7.0 fp_add [list CONFIG.Axi_Optimize_Goal {Performance} CONFIG.Maximum_Latency {false} CONFIG.Has_ARESETN {true}]
connectal_synth_ip floating_point 7.0 fp_mul [list CONFIG.Operation_Type {Multiply} CONFIG.Axi_Optimize_Goal {Resources} CONFIG.Maximum_Latency {false} CONFIG.Has_ARESETN {true}]
