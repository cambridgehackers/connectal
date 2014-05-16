
proc xbsv_set_board_part {} {
    global boardname
    if [catch {current_project}] {
	create_project -name synth_ip -in_memory
    }
    if {[lsearch [list_property [current_project]] board_part] >= 0} {
	set_property board_part "xilinx.com:$boardname:part0:1.0" [current_project]
    } else {
	## vivado 2013.2 uses the BOARD property instead
	set board_candidates [get_boards *$boardname*]
	set_property BOARD [lindex $board_candidates [expr [llength $board_candidates] - 1]] [current_project]
    }
}

proc xbsv_synth_ip {core_name core_version ip_name params} {
    global xbsvdir boardname

    ## make sure we have a project configured for the correct board
    if [catch {current_project}] {
	xbsv_set_board_part
    }

    if [file exists $xbsvdir/generated/xilinx/$boardname/$ip_name/$ip_name.xci] {
	read_ip $xbsvdir/generated/xilinx/$boardname/$ip_name/$ip_name.xci
    }  else {
        file mkdir $xbsvdir/generated/xilinx/$boardname
        create_ip -name $core_name -version $core_version -vendor xilinx.com -library ip -module_name $ip_name -dir $xbsvdir/generated/xilinx/$boardname
        set_property -dict $params [get_ips $ip_name]
        report_property [get_ips $ip_name]
        generate_target all [get_files $xbsvdir/generated/xilinx/$boardname/$ip_name/$ip_name.xci]
    }
    if [file exists $xbsvdir/generated/xilinx/$boardname/$ip_name/$ip_name.dcp] {
    } else {
	catch {
	    synth_ip [get_ips $ip_name]
	}
    }
}
