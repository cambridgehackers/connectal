set_property LOC H9  [get_ports { CLK_sys_clk_p }]
set_property LOC G9  [get_ports { CLK_sys_clk_n }]
set_property IOSTANDARD DIFF_SSTL15 [get_ports { CLK_sys_clk_* }]
create_clock -name sys_clk -period 5 [get_ports CLK_sys_clk_p]

# set_property iostandard "LVCMOS15" [get_ports "GPIO_leds[0]"]
# set_property PACKAGE_PIN "A17" [get_ports "GPIO_leds[0]"]
# set_property slew "SLOW" [get_ports "GPIO_leds[0]"]
# set_property PIO_DIRECTION "OUTPUT" [get_ports "GPIO_leds[0]"]

# set_property iostandard "LVCMOS18" [get_ports "GPIO_leds[1]"]
# set_property PACKAGE_PIN "W21" [get_ports "GPIO_leds[1]"]
# set_property slew "SLOW" [get_ports "GPIO_leds[1]"]
# set_property PIO_DIRECTION "OUTPUT" [get_ports "GPIO_leds[1]"]

# set_property iostandard "LVCMOS15" [get_ports "GPIO_leds[2]"]
# set_property PACKAGE_PIN "G2" [get_ports "GPIO_leds[2]"]
# set_property slew "SLOW" [get_ports "GPIO_leds[2]"]
# set_property PIO_DIRECTION "OUTPUT" [get_ports "GPIO_leds[2]"]

# set_property iostandard "LVCMOS18" [get_ports "GPIO_leds[3]"]
# set_property PACKAGE_PIN "Y21" [get_ports "GPIO_leds[3]"]
# set_property slew "SLOW" [get_ports "GPIO_leds[3]"]
# set_property PIO_DIRECTION "OUTPUT" [get_ports "GPIO_leds[3]"]

# set_property iostandard "LVCMOS18" [get_ports "XADC_gpio[0]"]
# set_property PACKAGE_PIN "H14" [get_ports "XADC_gpio[0]"]
# set_property slew "SLOW" [get_ports "XADC_gpio[0]"]
# set_property PIO_DIRECTION "OUTPUT" [get_ports "XADC_gpio[0]"]

# set_property iostandard "LVCMOS18" [get_ports "XADC_gpio[1]"]
# set_property PACKAGE_PIN "J15" [get_ports "XADC_gpio[1]"]
# set_property slew "SLOW" [get_ports "XADC_gpio[1]"]
# set_property PIO_DIRECTION "OUTPUT" [get_ports "XADC_gpio[1]"]

# set_property iostandard "LVCMOS18" [get_ports "XADC_gpio[2]"]
# set_property PACKAGE_PIN "J16" [get_ports "XADC_gpio[2]"]
# set_property slew "SLOW" [get_ports "XADC_gpio[2]"]
# set_property PIO_DIRECTION "OUTPUT" [get_ports "XADC_gpio[2]"]

# set_property iostandard "LVCMOS18" [get_ports "XADC_gpio[3]"]
# set_property PACKAGE_PIN "J14" [get_ports "XADC_gpio[3]"]
# set_property slew "SLOW" [get_ports "XADC_gpio[3]"]
# set_property PIO_DIRECTION "OUTPUT" [get_ports "XADC_gpio[3]"]

# PS_MIO50 set_property PACKAGE_PIN "A19" [get_ports "I2C0_scl"]
# PS_MIO51 set_property PACKAGE_PIN "F19" [get_ports "I2C0_sda"]
