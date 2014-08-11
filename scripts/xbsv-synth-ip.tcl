source "board.tcl"
source "$xbsvdir/../fpgamake/tcl/fpgamake-synth-ip.tcl"

proc xbsv_synth_ip {core_name core_version ip_name params} {
   fpgamake_synth_ip $core_name $core_version $ip_name $params
}
