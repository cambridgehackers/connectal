## disconnect unused CLK and RST ports inserted by bsc
foreach {pat} {CLK_unused_clock* CLK_GATE_unused_clock* RST_N_unused_reset* CLK_*_if CLK_GATE_*_if RST_N_hdmi_reset_if CLK_GATE_* RST_N_* CLK_spi_*} {
    foreach {net} [get_nets $pat] {
	disconnect_net -net $net -objects [get_pins -of_objects $net]
    }
}
