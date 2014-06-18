## disconnect unused CLK and RST ports inserted by bsc
foreach {pat} {CLK_GATE*} {
    puts $pat
    puts ports
    puts [get_ports $pat]
    puts nets
    puts [get_nets $pat]
    foreach {net} [get_nets $pat] {
	disconnect_net -net $net -objects [get_pins -of_objects $net]
    }
}
