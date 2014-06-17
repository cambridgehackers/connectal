
foreach {pat} {CLK_GATE_hdmi_clock_if CLK_*deleteme_unused_clock* CLK_GATE_*deleteme_unused_clock* RST_N_*deleteme_unused_reset*} {
    foreach {net} [get_nets $pat] {
	disconnect_net -net $net -objects [get_pins -of_objects $net]
    }
}
