##
## Imageon zedboard constraints
##
set_property LOC "P20" [get_ports "spi_sclk"]
set_property IOSTANDARD "LVCMOS25" [get_ports "spi_sclk"]
set_property PIO_DIRECTION "OUTPUT" [get_ports "spi_sclk"]

set_property LOC "P21" [get_ports "spi_sel_n"]
set_property IOSTANDARD "LVCMOS25" [get_ports "spi_sel_n"]
set_property PIO_DIRECTION "OUTPUT" [get_ports "spi_sel_n"]

set_property LOC "N17" [get_ports "spi_mosi"]
set_property IOSTANDARD "LVCMOS25" [get_ports "spi_mosi"]
set_property PIO_DIRECTION "OUTPUT" [get_ports "spi_mosi"]

set_property LOC "N18" [get_ports "spi_miso_v"]
set_property IOSTANDARD "LVCMOS25" [get_ports "spi_miso_v"]
set_property PIO_DIRECTION "INPUT" [get_ports "spi_miso_v"]

set_property LOC "L17" [get_ports "*io_vita_clk_pll"]
set_property IOSTANDARD  "LVCMOS25" [get_ports "*io_vita_clk_pll"]
set_property PIO_DIRECTION "OUTPUT" [get_ports "*io_vita_clk_pll"]

set_property LOC "L19" [get_ports "*io_vita_reset_n"]
set_property IOSTANDARD "LVCMOS25" [get_ports "*io_vita_reset_n"]
set_property PIO_DIRECTION "OUTPUT" [get_ports "*io_vita_reset_n"]

set_property LOC "M17" [get_ports "*io_vita_trigger_2*"]
set_property IOSTANDARD "LVCMOS25" [get_ports "*io_vita_trigger_2*"]
set_property PIO_DIRECTION "OUTPUT" [get_ports "*io_vita_trigger_2*"]

set_property LOC "K19" [get_ports "*io_vita_trigger_1*"]
set_property IOSTANDARD "LVCMOS25" [get_ports "*io_vita_trigger_1*"]
set_property PIO_DIRECTION "OUTPUT" [get_ports "*io_vita_trigger_1*"]

set_property LOC "K20" [get_ports "*io_vita_trigger_0*"]
set_property IOSTANDARD "LVCMOS25" [get_ports "*io_vita_trigger_0*"]
set_property PIO_DIRECTION "OUTPUT" [get_ports "*io_vita_trigger_0*"]

set_property LOC "J17" [get_ports "*io_vita_monitor[1]"]
set_property IOSTANDARD "LVCMOS25" [get_ports "*io_vita_monitor[1]"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_monitor[1]"]

set_property LOC "J16" [get_ports "*io_vita_monitor[0]"]
set_property IOSTANDARD "LVCMOS25" [get_ports "*io_vita_monitor[0]"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_monitor[0]"]

set_property LOC "P20" [get_ports "*io_vita_spi_sclk"]
set_property IOSTANDARD "LVCMOS25" [get_ports "*io_vita_spi_sclk"]
set_property PIO_DIRECTION "OUTPUT" [get_ports "*io_vita_spi_sclk"]

set_property LOC "P21" [get_ports "*io_vita_spi_ssel_n"]
set_property IOSTANDARD "LVCMOS25" [get_ports "*io_vita_spi_ssel_n"]
set_property PIO_DIRECTION "OUTPUT" [get_ports "*io_vita_spi_ssel_n"]

set_property LOC "N17" [get_ports "*io_vita_spi_mosi"]
set_property IOSTANDARD "LVCMOS25" [get_ports "*io_vita_spi_mosi"]
set_property PIO_DIRECTION "OUTPUT" [get_ports "*io_vita_spi_mosi"]

set_property LOC "N18" [get_ports "*io_vita_spi_miso"]
set_property IOSTANDARD "LVCMOS25" [get_ports "*io_vita_spi_miso"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_spi_miso"]

set_property LOC "M19" [get_ports "*io_vita_clk_out_p"]
set_property IOSTANDARD "LVDS_25" [get_ports "*io_vita_clk_out_p"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_clk_out_p"]

set_property LOC "M20" [get_ports "*io_vita_clk_out_n"]
set_property IOSTANDARD "LVDS_25" [get_ports "*io_vita_clk_out_n"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_clk_out_n"]

set_property LOC "R19" [get_ports "*io_vita_sync_p"]
set_property IOSTANDARD "LVDS_25" [get_ports "*io_vita_sync_p"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_sync_p"]

set_property LOC "T19" [get_ports "*io_vita_sync_n"]
set_property IOSTANDARD "LVDS_25" [get_ports "*io_vita_sync_n"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_sync_n"]

set_property LOC "R20" [get_ports "*io_vita_data_p[0]"]
set_property IOSTANDARD "LVDS_25" [get_ports "*io_vita_data_p[0]"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_data_p[0]"]

set_property LOC "T16" [get_ports "*io_vita_data_p[1]"]
set_property IOSTANDARD "LVDS_25" [get_ports "*io_vita_data_p[1]"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_data_p[1]"]

set_property LOC "J21" [get_ports "*io_vita_data_p[2]"]
set_property IOSTANDARD "LVDS_25" [get_ports "*io_vita_data_p[2]"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_data_p[2]"]

set_property LOC "J18" [get_ports "*io_vita_data_p[3]"]
set_property IOSTANDARD "LVDS_25" [get_ports "*io_vita_data_p[3]"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_data_p[3]"]

set_property LOC "R21" [get_ports "*io_vita_data_n[0]"]
set_property IOSTANDARD "LVDS_25" [get_ports "*io_vita_data_n[0]"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_data_n[0]"]

set_property LOC "T17" [get_ports "*io_vita_data_n[1]"]
set_property IOSTANDARD "LVDS_25" [get_ports "*io_vita_data_n[1]"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_data_n[1]"]

set_property LOC "J22" [get_ports "*io_vita_data_n[2]"]
set_property IOSTANDARD "LVDS_25" [get_ports "*io_vita_data_n[2]"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_data_n[2]"]

set_property LOC "K18" [get_ports "*io_vita_data_n[3]"]
set_property IOSTANDARD "LVDS_25" [get_ports "*io_vita_data_n[3]"]
set_property PIO_DIRECTION "INPUT" [get_ports "*io_vita_data_n[3]"]

