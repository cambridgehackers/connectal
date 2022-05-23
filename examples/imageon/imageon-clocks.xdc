create_clock -name video_clk -period "10" [get_ports "fmc_video_clk1_v"]
create_clock -name serpins_clk -period "10" [get_ports "serpins_io_vita_clk_p_v"]
create_clock -name spi_clk -period "100" [get_pins "ts_0/lImageonCapture_spiController_clockDivider/cntr_reg[9]/Q"]

