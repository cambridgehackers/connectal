source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

proc create_custom_pll {name refclk args} {
    global ipdir boardname partname
    set num [llength $args]

    if {$num == 0} {
        set error {wrong # args: should be at least "create_custom_pll [refclk] [genclk0] ..."}
        error $error
    }

    puts "Generating PLL with ref clock $refclk and output clock $args..."

    set params [ dict create ]
    dict set params gui_reference_clock_frequency $refclk
    dict set params gui_operation_mode            "normal"
    dict set params gui_number_of_clocks          $num
    dict set params gui_use_locked                "false"

    set m 0
    while {$m < 18} {
        set key0 gui_output_clock_frequency$m
        set key1 gui_phase_shift$m
        set key2 gui_duty_cycle$m

        if {$m < $num} {
            dict set params $key0 [lindex $args $m]
            dict set params $key1 0
            dict set params $key2 50
        } else {
            dict set params $key0 0
            dict set params $key1 0
            dict set params $key2 50
        }

        incr m
    }

    set component_parameters {}
	foreach item [dict keys $params] {
		set val [dict get $params $item]
		lappend component_parameters --component-param=$item=$val
	}

    set core_name {altera_pll}
    set core_version {14.0}
    set ip_name $name

    exec -ignorestderr -- ip-generate \
            --project-directory=$ipdir/$boardname                            \
            --output-directory=$ipdir/$boardname/synthesis/$ip_name                   \
            --file-set=QUARTUS_SYNTH                                         \
            --report-file=html:$ipdir/$boardname/$ip_name.html               \
            --report-file=sopcinfo:$ipdir/$boardname/$ip_name.sopcinfo       \
            --report-file=cmp:$ipdir/$boardname/$ip_name.cmp                 \
            --report-file=svd:$ipdir/$boardname/synthesis/$ip_name/$ip_name.svd       \
            --report-file=qip:$ipdir/$boardname/synthesis/$ip_name/altera_$ip_name.qip     \
            --report-file=regmap:$ipdir/$boardname/synthesis/$ip_name/$ip_name.regmap \
            --report-file=xml:$ipdir/$boardname/$ip_name.xml                 \
            --system-info=DEVICE_FAMILY=StratixV                             \
            --system-info=DEVICE=$partname                                   \
            --system-info=DEVICE_SPEEDGRADE=2_H2                             \
            --language=VERILOG                                               \
            {*}$component_parameters\
            --component-name=$core_name                                      \
            --output-name=$ip_name
}

create_custom_pll pll_156 644.53125 156.25
