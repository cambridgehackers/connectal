## disconnect unused CLK and RST ports inserted by bsc
foreach {pat} {CLK_GATE_* CLK_pins_spi_clock} {
    foreach {net} [get_nets $pat] {
	disconnect_net -net $net -objects [get_pins -of_objects $net]
    }
}
