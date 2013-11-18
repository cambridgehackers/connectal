#

imageon_pinout = {
    'zedboard': [
        ('io_vita_clk_pll', 'L17', 'LVCMOS25', 'OUTPUT'), #LA13_p
        ('io_vita_reset_n', 'L19', 'LVCMOS25', 'OUTPUT'), # CLK0_M2C_n
        ('io_vita_trigger[2]', 'M17', 'LVCMOS25', 'OUTPUT'),#LA13_n
        ('io_vita_trigger[1]', 'K19', 'LVCMOS25', 'OUTPUT'),#LA14_p
        ('io_vita_trigger[0]', 'K20', 'LVCMOS25', 'OUTPUT'),#LA14_n
        ('io_vita_monitor[1]', 'J17', 'LVCMOS25', 'INPUT'),#LA15_n
        ('io_vita_monitor[0]', 'J16', 'LVCMOS25', 'INPUT'),#LA15_p
        ('io_vita_spi_sclk', 'P20', 'LVCMOS25', 'OUTPUT'),#LA12_p
        ('io_vita_spi_ssel_n', 'P21', 'LVCMOS25', 'OUTPUT'),#LA12_n
        ('io_vita_spi_mosi', 'N17', 'LVCMOS25', 'OUTPUT'),#LA11_p
        ('io_vita_spi_miso', 'N18', 'LVCMOS25', 'INPUT'),#LA11_n
        ('io_vita_clk_out_p', 'M19', 'LVDS_25', 'INPUT'),#LA00_p_CC
        ('io_vita_clk_out_n', 'M20', 'LVDS_25', 'INPUT'),#LA00_n_CC
        ('io_vita_sync_p', 'R19', 'LVDS_25', 'INPUT'), #LA10_p
        ('io_vita_sync_n', 'T19', 'LVDS_25', 'INPUT'), #LA10_n
        ('io_vita_data_p[0]', 'R20', 'LVDS_25', 'INPUT'),#LA09_p
        ('io_vita_data_p[1]', 'T16', 'LVDS_25', 'INPUT'),#LA07_p
        ('io_vita_data_p[2]', 'J21', 'LVDS_25', 'INPUT'),#LA08_p
        ('io_vita_data_p[3]', 'J18', 'LVDS_25', 'INPUT'),#LA05_p
        #('io_vita_data_p[4]', 'M21', 'LVDS_25', 'INPUT'),#LA04_p
        #('io_vita_data_p[5]', 'L21', 'LVDS_25', 'INPUT'),#LA06_p
        #('io_vita_data_p[6]', 'N22', 'LVDS_25', 'INPUT'),#LA03_p
        #('io_vita_data_p[7]', 'P17', 'LVDS_25', 'INPUT'),#LA02_p
        ('io_vita_data_n[0]', 'R21', 'LVDS_25', 'INPUT'),#LA09_n
        ('io_vita_data_n[1]', 'T17', 'LVDS_25', 'INPUT'),#LA07_n
        ('io_vita_data_n[2]', 'J22', 'LVDS_25', 'INPUT'),#LA08_n
        ('io_vita_data_n[3]', 'K18', 'LVDS_25', 'INPUT'),#LA05_n
        #('io_vita_data_n[4]', 'M22', 'LVDS_25', 'INPUT'),#LA04_n
        #('io_vita_data_n[5]', 'L22', 'LVDS_25', 'INPUT'),#LA06_n
        #('io_vita_data_n[6]', 'P22', 'LVDS_25', 'INPUT'),#LA03_n
        #('io_vita_data_n[7]', 'P18', 'LVDS_25', 'INPUT'),#LA02_n
        ],
    'zc702': [
        ("XADC_gpio[0]", 'H17', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[1]", 'H22', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[2]", 'G22', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[3]", 'H18', 'LVCMOS25', 'OUTPUT'),

        ('fmc_imageon_video_clk1', 'Y18', 'LVCMOS25', 'INPUT'),
        ('fmc_imageon_iic_1_rst_pin', 'Y16', 'LVCMOS25', 'OUTPUT'),
        ('fmc_imageon_iic_1_scl', 'AB14', 'LVCMOS25', 'BIDIR'),
        ('fmc_imageon_iic_1_sda', 'AB15', 'LVCMOS25', 'BIDIR'),

        ('io_vita_clk_pll', 'V22', 'LVCMOS25', 'OUTPUT'),
        ('io_vita_reset_n', 'AA18', 'LVCMOS25', 'OUTPUT'),
        ('io_vita_trigger[2]', 'W22', 'LVCMOS25', 'OUTPUT'),
        ('io_vita_trigger[1]', 'T22', 'LVCMOS25', 'OUTPUT'),
        ('io_vita_trigger[0]', 'U22', 'LVCMOS25', 'OUTPUT'),
        ('io_vita_monitor[1]', 'AA13', 'LVCMOS25', 'INPUT'),
        ('io_vita_monitor[0]', 'Y13', 'LVCMOS25', 'INPUT'),
        ('io_vita_spi_sclk', 'W15', 'LVCMOS25', 'OUTPUT'),
        ('io_vita_spi_ssel_n', 'Y15', 'LVCMOS25', 'OUTPUT'),
        ('io_vita_spi_mosi', 'Y14', 'LVCMOS25', 'OUTPUT'),
        ('io_vita_spi_miso', 'AA14', 'LVCMOS25', 'INPUT'),
        ('io_vita_clk_out_p', 'Y19', 'LVDS_25', 'INPUT'),
        ('io_vita_clk_out_n', 'AA19', 'LVDS_25', 'INPUT'),
        ('io_vita_sync_p', 'Y20', 'LVDS_25', 'INPUT'),
        ('io_vita_sync_n', 'Y21', 'LVDS_25', 'INPUT'),
        ('io_vita_data_p[0]', 'U15', 'LVDS_25', 'INPUT'),
        ('io_vita_data_p[1]', 'T21', 'LVDS_25', 'INPUT'),
        ('io_vita_data_p[2]', 'AA17', 'LVDS_25', 'INPUT'),
        ('io_vita_data_p[3]', 'AB19', 'LVDS_25', 'INPUT'),
        #('io_vita_data_p[4]', 'V13', 'LVDS_25', 'INPUT'),
        #('io_vita_data_p[5]', 'U17', 'LVDS_25', 'INPUT'),
        #('io_vita_data_p[6]', 'AA16', 'LVDS_25', 'INPUT'),
        #('io_vita_data_p[7]', 'V14', 'LVDS_25', 'INPUT'),
        ('io_vita_data_n[0]', 'U16', 'LVDS_25', 'INPUT'),
        ('io_vita_data_n[1]', 'U21', 'LVDS_25', 'INPUT'),
        ('io_vita_data_n[2]', 'AB17', 'LVDS_25', 'INPUT'),
        ('io_vita_data_n[3]', 'AB20', 'LVDS_25', 'INPUT'),
        #('io_vita_data_n[4]', 'W13', 'LVDS_25', 'INPUT'),
        #('io_vita_data_n[5]', 'V17', 'LVDS_25', 'INPUT'),
        #('io_vita_data_n[6]', 'AB16', 'LVDS_25', 'INPUT'),
        #('io_vita_data_n[7]', 'V15', 'LVDS_25', 'INPUT'),
        ]
}

class ImageonVita:
    def __init__(self, busHandlers):
        busHandlers['ImageonVita'] = self
    def top_bus_ports(self, busname,t,params):
        return '''
/* imageon vita *****************************************/

    inout fmc_imageon_iic_1_sda,
    inout fmc_imageon_iic_1_scl,
    output fmc_imageon_iic_1_rst_pin,
    input fmc_imageon_video_clk1,
    output io_vita_clk_pll,
    output io_vita_reset_n,
    output [2:0] io_vita_trigger,
    input [1:0] io_vita_monitor,
    output io_vita_spi_sclk,
    output io_vita_spi_ssel_n,
    output io_vita_spi_mosi,
    input io_vita_spi_miso,
    input io_vita_clk_out_p,
    input io_vita_clk_out_n,
    input io_vita_sync_p,
    input io_vita_sync_n,
    input [3:0] io_vita_data_p,
    input [3:0] io_vita_data_n,
    output [3:0] XADC_gpio,
/* imageon vita *****************************************/
'''
    def top_bus_wires(self, busname,t,params):
         return '''
     wire imageon_clk;
     wire fmc_imageon_iic_1_scl_T;
     wire fmc_imageon_iic_1_scl_O;
     wire fmc_imageon_iic_1_scl_I;
     wire fmc_imageon_iic_1_sda_T;
     wire fmc_imageon_iic_1_sda_O;
     wire fmc_imageon_iic_1_sda_I;
     wire fbbozo;
'''
    def ps7_bus_port_map(self,busname,t,params):
        return '''
    .I2C1_SDA_I(fmc_imageon_iic_1_sda_I),
    .I2C1_SDA_O(fmc_imageon_iic_1_sda_O),
    .I2C1_SDA_T(fmc_imageon_iic_1_sda_T),
    .I2C1_SCL_I(fmc_imageon_iic_1_scl_I),
    .I2C1_SCL_O(fmc_imageon_iic_1_scl_O),
    .I2C1_SCL_T(fmc_imageon_iic_1_scl_T),
'''
    def dut_bus_port_map(self, busname,t,params):
        return '''
    .serpins_io_vita_clk_p_v(io_vita_clk_out_p),
    .serpins_io_vita_clk_n_v(io_vita_clk_out_n),
    .serpins_io_vita_sync_p_v(io_vita_sync_p),
    .serpins_io_vita_sync_n_v(io_vita_sync_n),
    .serpins_io_vita_data_p_v(io_vita_data_p),
    .serpins_io_vita_data_n_v(io_vita_data_n),
    .pins_io_vita_reset_n(io_vita_reset_n),
    .pins_io_vita_trigger_0__read(io_vita_trigger[0]),
    .pins_io_vita_trigger_1__read(io_vita_trigger[1]),
    .pins_io_vita_trigger_2__read(io_vita_trigger[2]),
    .pins_io_vita_clk_pll(io_vita_clk_pll),
    .toppins_fbbozoin_v(fbbozo),
    .CLK_toppins_fbbozo(fbbozo),
    /* SPI port */
    .CLK_spi_invertedClock(io_vita_spi_sclk),
    .spi_sel_n(io_vita_spi_ssel_n),
    .spi_mosi(io_vita_spi_mosi),
    .spi_miso_v(io_vita_spi_miso),
'''
    def top_bus_assignments(self,busname,t,params):
        return '''
     IOBUF#(.DRIVE(12), .IOSTANDARD("LVCMOS25"), .SLEW("SLOW")) (
     .IO(fmc_imageon_iic_1_scl), .O(fmc_imageon_iic_1_scl_I),
     .I(fmc_imageon_iic_1_scl_O), .T(fmc_imageon_iic_1_scl_T)); 
     IOBUF#(.DRIVE(12), .IOSTANDARD("LVCMOS25"), .SLEW("SLOW")) (
     .IO(fmc_imageon_iic_1_sda), .O(fmc_imageon_iic_1_sda_I),
     .I(fmc_imageon_iic_1_sda_O), .T(fmc_imageon_iic_1_sda_T));
'''
    def bus_assignments(self,busname,t,params):
        return '''
'''
    def pinout(self, board):
        return imageon_pinout[board]
