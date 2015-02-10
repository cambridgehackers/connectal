## disconnect unused CLK and RST ports inserted by bsc
foreach {pat} {CLK_GATE_* CLK_clock} {
    foreach {net} [get_nets $pat] {
	puts "disconnecting net $net"
	disconnect_net -net $net -objects [get_pins -of_objects $net]
    }
}
