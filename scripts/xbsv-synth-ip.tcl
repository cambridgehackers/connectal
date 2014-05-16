
proc xbsv_synth_ip {core_name core_version ip_name params} {
    global xbsvdir boardname
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
