source board.tcl
source $xbsvdir/scripts/xbsv-synth-ip.tcl

xbsv_synth_ip floating_point 7.0 fp_add [list CONFIG.Axi_Optimize_Goal {Performance} CONFIG.Maximum_Latency {false}]
xbsv_synth_ip floating_point 7.0 fp_mul [list CONFIG.Operation_Type {Multiply} CONFIG.Axi_Optimize_Goal {Resources} CONFIG.Maximum_Latency {false}]
