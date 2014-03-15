##
## Imageon zc702 constraints
##
set_property LOC, 'Y18 [get_ports 'fmc_imageon_video_clk1]
set_property IOSTANDARD, 'LVCMOS25 [get_ports 'fmc_imageon_video_clk1]
set_property PIO_DIRECTION  'INPUT [get_ports 'fmc_imageon_video_clk1]

set_property LOC, 'Y16 [get_ports 'fmc_imageon_iic_0_rst_pin]
set_property IOSTANDARD, 'LVCMOS25 [get_ports 'fmc_imageon_iic_0_rst_pin]
set_property PIO_DIRECTION  'OUTPUT [get_ports 'fmc_imageon_iic_0_rst_pin]

set_property LOC, 'AB14 [get_ports 'fmc_imageon_iic_0_scl]
set_property IOSTANDARD, 'LVCMOS25 [get_ports 'fmc_imageon_iic_0_scl]
set_property PIO_DIRECTION  'BIDIR [get_ports 'fmc_imageon_iic_0_scl]

set_property LOC, 'AB15 [get_ports 'fmc_imageon_iic_0_sda]
set_property IOSTANDARD, 'LVCMOS25 [get_ports 'fmc_imageon_iic_0_sda]
set_property PIO_DIRECTION  'BIDIR [get_ports 'fmc_imageon_iic_0_sda]

set_property LOC, 'V22 [get_ports 'io_vita_clk_pll]
set_property IOSTANDARD, 'LVCMOS25 [get_ports 'io_vita_clk_pll]
set_property PIO_DIRECTION  'OUTPUT [get_ports 'io_vita_clk_pll]

set_property LOC, 'AA18 [get_ports 'io_vita_reset_n]
set_property IOSTANDARD, 'LVCMOS25 [get_ports 'io_vita_reset_n]
set_property PIO_DIRECTION  'OUTPUT [get_ports 'io_vita_reset_n]

set_property LOC2 [get_ports 'io_vita_trigger]
set_property IOSTANDARD', 'W22 [get_ports 'io_vita_trigger]
set_property PIO_DIRECTION  'LVCMOS25 [get_ports 'io_vita_trigger]

set_property LOC1 [get_ports 'io_vita_trigger]
set_property IOSTANDARD', 'T22 [get_ports 'io_vita_trigger]
set_property PIO_DIRECTION  'LVCMOS25 [get_ports 'io_vita_trigger]

set_property LOC0 [get_ports 'io_vita_trigger]
set_property IOSTANDARD', 'U22 [get_ports 'io_vita_trigger]
set_property PIO_DIRECTION  'LVCMOS25 [get_ports 'io_vita_trigger]

set_property LOC1 [get_ports 'io_vita_monitor]
set_property IOSTANDARD', 'AA13 [get_ports 'io_vita_monitor]
set_property PIO_DIRECTION  'LVCMOS25 [get_ports 'io_vita_monitor]

set_property LOC0 [get_ports 'io_vita_monitor]
set_property IOSTANDARD', 'Y13 [get_ports 'io_vita_monitor]
set_property PIO_DIRECTION  'LVCMOS25 [get_ports 'io_vita_monitor]

set_property LOC, 'W15 [get_ports 'io_vita_spi_sclk]
set_property IOSTANDARD, 'LVCMOS25 [get_ports 'io_vita_spi_sclk]
set_property PIO_DIRECTION  'OUTPUT [get_ports 'io_vita_spi_sclk]

set_property LOC, 'Y15 [get_ports 'io_vita_spi_ssel_n]
set_property IOSTANDARD, 'LVCMOS25 [get_ports 'io_vita_spi_ssel_n]
set_property PIO_DIRECTION  'OUTPUT [get_ports 'io_vita_spi_ssel_n]

set_property LOC, 'Y14 [get_ports 'io_vita_spi_mosi]
set_property IOSTANDARD, 'LVCMOS25 [get_ports 'io_vita_spi_mosi]
set_property PIO_DIRECTION  'OUTPUT [get_ports 'io_vita_spi_mosi]

set_property LOC, 'AA14 [get_ports 'io_vita_spi_miso]
set_property IOSTANDARD, 'LVCMOS25 [get_ports 'io_vita_spi_miso]
set_property PIO_DIRECTION  'INPUT [get_ports 'io_vita_spi_miso]

set_property LOC, 'Y19 [get_ports 'io_vita_clk_out_p]
set_property IOSTANDARD, 'LVDS_25 [get_ports 'io_vita_clk_out_p]
set_property PIO_DIRECTION  'INPUT [get_ports 'io_vita_clk_out_p]

set_property LOC, 'AA19 [get_ports 'io_vita_clk_out_n]
set_property IOSTANDARD, 'LVDS_25 [get_ports 'io_vita_clk_out_n]
set_property PIO_DIRECTION  'INPUT [get_ports 'io_vita_clk_out_n]

set_property LOC, 'Y20 [get_ports 'io_vita_sync_p]
set_property IOSTANDARD, 'LVDS_25 [get_ports 'io_vita_sync_p]
set_property PIO_DIRECTION  'INPUT [get_ports 'io_vita_sync_p]

set_property LOC, 'Y21 [get_ports 'io_vita_sync_n]
set_property IOSTANDARD, 'LVDS_25 [get_ports 'io_vita_sync_n]
set_property PIO_DIRECTION  'INPUT [get_ports 'io_vita_sync_n]

set_property LOC0 [get_ports 'io_vita_data_p]
set_property IOSTANDARD', 'U15 [get_ports 'io_vita_data_p]
set_property PIO_DIRECTION  'LVDS_25 [get_ports 'io_vita_data_p]

set_property LOC1 [get_ports 'io_vita_data_p]
set_property IOSTANDARD', 'T21 [get_ports 'io_vita_data_p]
set_property PIO_DIRECTION  'LVDS_25 [get_ports 'io_vita_data_p]

set_property LOC2 [get_ports 'io_vita_data_p]
set_property IOSTANDARD', 'AA17 [get_ports 'io_vita_data_p]
set_property PIO_DIRECTION  'LVDS_25 [get_ports 'io_vita_data_p]

set_property LOC3 [get_ports 'io_vita_data_p]
set_property IOSTANDARD', 'AB19 [get_ports 'io_vita_data_p]
set_property PIO_DIRECTION  'LVDS_25 [get_ports 'io_vita_data_p]

set_property LOC0 [get_ports 'io_vita_data_n]
set_property IOSTANDARD', 'U16 [get_ports 'io_vita_data_n]
set_property PIO_DIRECTION  'LVDS_25 [get_ports 'io_vita_data_n]

set_property LOC1 [get_ports 'io_vita_data_n]
set_property IOSTANDARD', 'U21 [get_ports 'io_vita_data_n]
set_property PIO_DIRECTION  'LVDS_25 [get_ports 'io_vita_data_n]

set_property LOC2 [get_ports 'io_vita_data_n]
set_property IOSTANDARD', 'AB17 [get_ports 'io_vita_data_n]
set_property PIO_DIRECTION  'LVDS_25 [get_ports 'io_vita_data_n]

set_property LOC3 [get_ports 'io_vita_data_n]
set_property IOSTANDARD', 'AB20 [get_ports 'io_vita_data_n]
set_property PIO_DIRECTION  'LVDS_25 [get_ports 'io_vita_data_n]

