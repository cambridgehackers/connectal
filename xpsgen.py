
import sys
import os
import util
import re

edkversion = '14.3'
edkversions = ['14.3', '14.4']
if os.environ.has_key('XILINX_EDK'):
    m = re.match('.*/(\d+.\d+)/ISE_DS/EDK$', os.environ['XILINX_EDK'])
    if m:
        edkversion = m.group(1)
use_acp = 0

hdmi_ucf_template= {
    'zc702': '''
NET "hdmi_clk_pin" LOC = L16;
NET "hdmi_clk_pin" IOSTANDARD = LVCMOS25;
NET "hdmi_vsync_pin" LOC = H15;
NET "hdmi_vsync_pin" IOSTANDARD = LVCMOS25;
NET "hdmi_hsync_pin" LOC = R18;
NET "hdmi_hsync_pin" IOSTANDARD = LVCMOS25;
NET "hdmi_de_pin" LOC = T18;
NET "hdmi_de_pin" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[0]" LOC = AB21;
NET "hdmi_data_pin[0]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[1]" LOC = AA21;
NET "hdmi_data_pin[1]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[2]" LOC = AB22;
NET "hdmi_data_pin[2]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[3]" LOC = AA22;
NET "hdmi_data_pin[3]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[4]" LOC = V19;
NET "hdmi_data_pin[4]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[5]" LOC = V18;
NET "hdmi_data_pin[5]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[6]" LOC = V20;
NET "hdmi_data_pin[6]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[7]" LOC = U20;
NET "hdmi_data_pin[7]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[8]" LOC = W21;
NET "hdmi_data_pin[8]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[9]" LOC = W20;
NET "hdmi_data_pin[9]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[10]" LOC = W18;
NET "hdmi_data_pin[10]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[11]" LOC = T19;
NET "hdmi_data_pin[11]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[12]" LOC = U19;
NET "hdmi_data_pin[12]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[13]" LOC = R19;
NET "hdmi_data_pin[13]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[14]" LOC = T17;
NET "hdmi_data_pin[14]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[15]" LOC = T16;
NET "hdmi_data_pin[15]" IOSTANDARD = LVCMOS25;
# NET hdmi_spdif_pin          LOC = R15 ;
# NET hdmi_int_pin            LOC = U14 ;
NET "hdmidisplay_0_i2c_scl_pin" LOC = AA18;
NET "hdmidisplay_0_i2c_scl_pin" IOSTANDARD = LVCMOS25;
NET "hdmidisplay_0_i2c_sda_pin" LOC = Y16;
NET "hdmidisplay_0_i2c_sda_pin" IOSTANDARD = LVCMOS25;
''',
    'zedboard':'''
NET "hdmi_clk_pin" LOC = W18;
NET "hdmi_clk_pin" IOSTANDARD = LVCMOS25;
NET "hdmi_vsync_pin" LOC = W17;
NET "hdmi_vsync_pin" IOSTANDARD = LVCMOS25;
NET "hdmi_hsync_pin" LOC = V17;
NET "hdmi_hsync_pin" IOSTANDARD = LVCMOS25;
NET "hdmi_de_pin" LOC = U16;
NET "hdmi_de_pin" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[0]" LOC = Y13;
NET "hdmi_data_pin[0]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[1]" LOC = AA13;
NET "hdmi_data_pin[1]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[2]" LOC = AA14;
NET "hdmi_data_pin[2]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[3]" LOC = Y14;
NET "hdmi_data_pin[3]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[4]" LOC = AB15;
NET "hdmi_data_pin[4]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[5]" LOC = AB16;
NET "hdmi_data_pin[5]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[6]" LOC = AA16;
NET "hdmi_data_pin[6]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[7]" LOC = AB17;
NET "hdmi_data_pin[7]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[8]" LOC = AA17;
NET "hdmi_data_pin[8]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[9]" LOC = Y15;
NET "hdmi_data_pin[9]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[10]" LOC = W13;
NET "hdmi_data_pin[10]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[11]" LOC = W15;
NET "hdmi_data_pin[11]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[12]" LOC = V15;
NET "hdmi_data_pin[12]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[13]" LOC = U17;
NET "hdmi_data_pin[13]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[14]" LOC = V14;
NET "hdmi_data_pin[14]" IOSTANDARD = LVCMOS25;
NET "hdmi_data_pin[15]" LOC = V13;
NET "hdmi_data_pin[15]" IOSTANDARD = LVCMOS25;
# NET hdmi_spdif_pin          LOC =  Y18;
# NET hdmi_int_pin            LOC =  W16;
NET "hdmidisplay_0_i2c_scl_pin" LOC = AA18;
NET "hdmidisplay_0_i2c_scl_pin" IOSTANDARD = LVCMOS25;
NET "hdmidisplay_0_i2c_sda_pin" LOC = Y16;
NET "hdmidisplay_0_i2c_sda_pin" IOSTANDARD = LVCMOS25;
'''
    }

usr_clk_ucf_template='''
NET "usr_clk_p_pin" LOC = Y9;
NET "usr_clk_p_pin" IOSTANDARD = LVDS_25;
NET "usr_clk_p_pin" DIFF_TERM = "TRUE";
NET "usr_clk_n_pin" LOC = Y8;
NET "usr_clk_n_pin" IOSTANDARD = LVDS_25;
NET "usr_clk_n_pin" DIFF_TERM = "TRUE";
NET "usr_clk_p_pin" TNM_NET = "usr_clk_p_pin";
TIMESPEC TS_usr_clk_p_pin = PERIOD "usr_clk_p_pin" 165 MHz;
NET "usr_clk_n_pin" TNM_NET = "usr_clk_n_pin";
TIMESPEC TS_usr_clk_n_pin = PERIOD "usr_clk_n_pin" 165 MHz;
'''

xadc_ucf_template= {
    'zc702': '''
NET "xadc_gpio_0_pin" LOC = H17;
NET "xadc_gpio_0_pin" IOSTANDARD = LVCMOS25;
NET "xadc_gpio_1_pin" LOC = H22;
NET "xadc_gpio_1_pin" IOSTANDARD = LVCMOS25;
NET "xadc_gpio_2_pin" LOC = G22;
NET "xadc_gpio_2_pin" IOSTANDARD = LVCMOS25;
NET "xadc_gpio_3_pin" LOC = H18;
NET "xadc_gpio_3_pin" IOSTANDARD = LVCMOS25;
''',
    'zedboard': '''
NET "xadc_gpio_0_pin" LOC = H15;
NET "xadc_gpio_0_pin" IOSTANDARD = LVCMOS25;
NET "xadc_gpio_1_pin" LOC = R15;
NET "xadc_gpio_1_pin" IOSTANDARD = LVCMOS25;
NET "xadc_gpio_2_pin" LOC = K15;
NET "xadc_gpio_2_pin" IOSTANDARD = LVCMOS25;
NET "xadc_gpio_3_pin" LOC = J15;
NET "xadc_gpio_3_pin" IOSTANDARD = LVCMOS25;
'''
    }

default_clk_ucf_template='''
NET "processing_system7_0/FCLK_CLK0" TNM_NET = "processing_system7_0/FCLK_CLK0";
TIMESPEC TS_FCLK0 = PERIOD "processing_system7_0/FCLK_CLK0" 133 MHz;
'''

xdc_template = '''
set_property iostandard "%(iostandard)s" [get_ports "%(name)s"]
set_property PACKAGE_PIN "%(pin)s" [get_ports "%(name)s"]
set_property slew "SLOW" [get_ports "%(name)s"]
set_property PIO_DIRECTION "%(direction)s" [get_ports "%(name)s"]
'''
xdc_diff_term_template = '''
set_property DIFF_TERM "TRUE" [get_ports "%(name)s"]
'''

impactCmdTemplate = '''
setMode -bscan
setCable -p auto
addDevice -p 1 -file ./%(base)s.runs/impl_1/mk%(Base)sPcieTop.bit
program -p 1
quit
'''

programTclTemplate = '''
connect_hw_server
open_hw_target 
set fpga [lindex [get_hw_devices] 0]
set file ./%(base)s.runs/impl_1/mk%(Base)sPcieTop.bit
set_property PROGRAM.FILE $file $fpga
puts "fpga is $fpga, bit file size is [exec ls -sh $file]"
program_hw_devices $fpga
'''

xadc_pinout= {
    'zc702': [
        ("XADC_gpio[0]", 'H17', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[1]", 'H22', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[2]", 'G22', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[3]", 'H18', 'LVCMOS25', 'OUTPUT'),
        ],
    'zedboard': [
        ("XADC_gpio[0]", 'H15', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[1]", 'R15', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[2]", 'K15', 'LVCMOS25', 'OUTPUT'),
        ("XADC_gpio[3]", 'J15', 'LVCMOS25', 'OUTPUT'),
        ]
    }

led_pinout = {
    'zc702': [
        ('GPIO_leds[0]', 'E15', 'LVCMOS25', 'OUTPUT'),
        ('GPIO_leds[1]', 'D15', 'LVCMOS25', 'OUTPUT'),
        ('GPIO_leds[2]', 'W17', 'LVCMOS25', 'OUTPUT'),
        ('GPIO_leds[3]', 'W5', 'LVCMOS25', 'OUTPUT'),
        ('GPIO_leds[4]', 'V7', 'LVCMOS25', 'OUTPUT'),
        ('GPIO_leds[5]', 'W10', 'LVCMOS25', 'OUTPUT'),
        ('GPIO_leds[6]', 'P18', 'LVCMOS25', 'OUTPUT'),
        ('GPIO_leds[7]', 'P17', 'LVCMOS25', 'OUTPUT')
    ],
    'zedboard': [
        ('GPIO_leds[0]', 'T22', 'LVCMOS33', 'OUTPUT'),
        ('GPIO_leds[1]', 'T21', 'LVCMOS33', 'OUTPUT'),
        ('GPIO_leds[2]', 'U22', 'LVCMOS33', 'OUTPUT'),
        ('GPIO_leds[3]', 'U21', 'LVCMOS33', 'OUTPUT'),
        ('GPIO_leds[4]', 'V22', 'LVCMOS33', 'OUTPUT'),
        ('GPIO_leds[5]', 'W22', 'LVCMOS33', 'OUTPUT'),
        ('GPIO_leds[6]', 'U19', 'LVCMOS33', 'OUTPUT'),
        ('GPIO_leds[7]', 'U14', 'LVCMOS33', 'OUTPUT')],
    'kc705': [],
    'vc707': [],
    }


hdmi_pinout = {
    'zc702': [
        ( "hdmi_clk", 'L16', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_hsync", 'R18', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_vsync", 'H15', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_de", 'T18', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[0]", 'AB21', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[1]", 'AA21', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[2]", 'AB22', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[3]", 'AA22', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[4]", 'V19', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[5]", 'V18', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[6]", 'V20', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[7]", 'U20', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[8]", 'W21', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[9]", 'W20', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[10]", 'W18', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[11]", 'T19', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[12]", 'U19', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[13]", 'R19', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[14]", 'T17', 'LVCMOS25', 'OUTPUT'),
        ( "hdmi_data[15]", 'T16', 'LVCMOS25', 'OUTPUT'),
        ],
    'zedboard':[
        ( "hdmi_clk", 'W18', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_vsync", 'W17', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_hsync", 'V17', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_de", 'U16', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[0]", 'Y13', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[1]", 'AA13', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[2]", 'AA14', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[3]", 'Y14', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[4]", 'AB15', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[5]", 'AB16', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[6]", 'AA16', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[7]", 'AB17', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[8]", 'AA17', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[9]", 'Y15', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[10]", 'W13', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[11]", 'W15', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[12]", 'V15', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[13]", 'U17', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[14]", 'V14', 'LVCMOS33', 'OUTPUT'),
        ( "hdmi_data[15]", 'V13', 'LVCMOS33', 'OUTPUT'),
        ]
    }

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
        ('fmc_imageon_iic_0_rst_pin', 'Y16', 'LVCMOS25', 'OUTPUT'),
        ('fmc_imageon_iic_0_scl', 'AB14', 'LVCMOS25', 'BIDIR'),
        ('fmc_imageon_iic_0_sda', 'AB15', 'LVCMOS25', 'BIDIR'),

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
top_verilog_template='''
`timescale 1 ps / 1 ps
// lib IP_Integrator_Lib
(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLanguage=VERILOG}" *) 
module %(dut)s_top_1
   (inout [14:0]DDR_Addr,
    inout [2:0]DDR_BankAddr,
    inout DDR_CAS_n,
    inout DDR_Clk_n,
    inout DDR_Clk_p,
    inout DDR_CKE,
    inout DDR_CS_n,
    inout [3:0]DDR_DM,
    inout [31:0]DDR_DQ,
    inout [3:0]DDR_DQS_n,
    inout [3:0]DDR_DQS_p,
    inout DDR_ODT,
    inout DDR_RAS_n,
    inout DDR_DRSTB,
    inout DDR_WEB,
    inout FIXED_IO_ddr_vrn,
    inout FIXED_IO_ddr_vrp,
    inout [53:0]FIXED_IO_mio,
    inout FIXED_IO_ps_clk,
    inout FIXED_IO_ps_porb,
    inout FIXED_IO_ps_srstb,
%(top_bus_ports)s
    output [7:0] GPIO_leds
);

%(axi_master_parameters)s
%(axi_slave_parameters)s
parameter C_FAMILY = "virtex6";

  wire GND_1;
%(interrupt_wire_decls)s

%(top_axi_master_wires)s
%(top_axi_slave_wires)s
%(top_bus_wires)s
  wire [14:0]processing_system7_1_ddr_ADDR;
  wire [2:0]processing_system7_1_ddr_BA;
  wire processing_system7_1_ddr_CAS_N;
  wire processing_system7_1_ddr_CKE;
  wire processing_system7_1_ddr_CK_N;
  wire processing_system7_1_ddr_CK_P;
  wire processing_system7_1_ddr_CS_N;
  wire [3:0]processing_system7_1_ddr_DM;
  wire [31:0]processing_system7_1_ddr_DQ;
  wire [3:0]processing_system7_1_ddr_DQS_N;
  wire [3:0]processing_system7_1_ddr_DQS_P;
  wire processing_system7_1_ddr_ODT;
  wire processing_system7_1_ddr_RAS_N;
  wire processing_system7_1_ddr_RESET_N;
  wire processing_system7_1_ddr_WE_N;
  wire processing_system7_1_fclk_clk0;
  wire processing_system7_1_fclk_clk1;
  wire processing_system7_1_fclk_clk2;
  wire processing_system7_1_fclk_clk3;
  wire processing_system7_1_fclk_reset0_n;
  wire processing_system7_1_fixed_io_DDR_VRN;
  wire processing_system7_1_fixed_io_DDR_VRP;
  wire [53:0]processing_system7_1_fixed_io_MIO;
  wire processing_system7_1_fixed_io_PS_CLK;
  wire processing_system7_1_fixed_io_PS_PORB;
  wire processing_system7_1_fixed_io_PS_SRSTB;

GND GND
       (.G(GND_1));

/* dut goes here */
mk%(Dut)sWrapper %(Dut)sIMPLEMENTATION (
      %(dut_hdmi_clock_arg)s
      .CLK(processing_system7_1_fclk_clk0),
      .RST_N(processing_system7_1_fclk_reset0_n),
      %(dut_axi_master_port_map)s
      %(dut_axi_slave_port_map)s
      %(dut_bus_port_map)s
      %(dut_interrupt_map)s
      );

%(axi_master_scheduler)s
%(axi_slave_scheduler)s
%(bus_assignments)s

wire [15:0] irq_f2p;
%(irq_f2p_assignments)s

processing_system7#(.C_NUM_F2P_INTR_INPUTS(16))
 processing_system7_1
       (.DDR_Addr(DDR_Addr[14:0]),
        .DDR_BankAddr(DDR_BankAddr[2:0]),
        .DDR_CAS_n(DDR_CAS_n),
        .DDR_CKE(DDR_CKE),
        .DDR_CS_n(DDR_CS_n),
        .DDR_Clk(DDR_Clk_p),
        .DDR_Clk_n(DDR_Clk_n),
        .DDR_DM(DDR_DM[3:0]),
        .DDR_DQ(DDR_DQ[31:0]),
        .DDR_DQS(DDR_DQS_p[3:0]),
        .DDR_DQS_n(DDR_DQS_n[3:0]),
        .DDR_DRSTB(DDR_DRSTB),
        .DDR_ODT(DDR_ODT),
        .DDR_RAS_n(DDR_RAS_n),
        .DDR_VRN(FIXED_IO_ddr_vrn),
        .DDR_VRP(FIXED_IO_ddr_vrp),
        .DDR_WEB(DDR_WEB),
        .FCLK_CLK0(processing_system7_1_fclk_clk0),
        .FCLK_CLK1(processing_system7_1_fclk_clk1),
        .FCLK_CLK2(processing_system7_1_fclk_clk2),
        .FCLK_CLK3(processing_system7_1_fclk_clk3),
        .FCLK_RESET0_N(processing_system7_1_fclk_reset0_n),
        .IRQ_F2P(irq_f2p),
        .MIO(FIXED_IO_mio[53:0]),
%(top_ps7_axi_slave_port_map)s
%(top_ps7_axi_master_port_map)s
%(ps7_bus_port_map)s
        .PS_CLK(FIXED_IO_ps_clk),
        .PS_PORB(FIXED_IO_ps_porb),
        .PS_SRSTB(FIXED_IO_ps_srstb));
   
%(top_bus_assignments)s
%(default_leds_assignment)s
endmodule
'''

top_axi_master_wires_template='''
  wire [31:0]%(busname)s_araddr;
  wire [1:0]%(busname)s_arburst;
  wire [3:0]%(busname)s_arcache;
  wire [5:0]%(busname)s_arid;
  wire [3:0]%(busname)s_arlen;
  wire [2:0]%(busname)s_arprot;
  wire %(busname)s_arready;
  wire [2:0]%(busname)s_arsize;
  wire %(busname)s_arvalid;
  wire [31:0]%(busname)s_awaddr;
  wire [1:0]%(busname)s_awburst;
  wire [3:0]%(busname)s_awcache;
  wire [5:0]%(busname)s_awid;
  wire [3:0]%(busname)s_awlen;
  wire [2:0]%(busname)s_awprot;
  wire %(busname)s_awready;
  wire [2:0]%(busname)s_awsize;
  wire %(busname)s_awvalid;
  wire [5:0]%(busname)s_bid;
  wire %(busname)s_bready;
  wire [1:0]%(busname)s_bresp;
  wire %(busname)s_bvalid;
  wire [C_%(BUSNAME)s_DATA_WIDTH-1:0]%(busname)s_rdata;
  wire [5:0]%(busname)s_rid;
  wire %(busname)s_rlast;
  wire %(busname)s_rready;
  wire [1:0]%(busname)s_rresp;
  wire %(busname)s_rvalid;
  wire [C_%(BUSNAME)s_DATA_WIDTH-1:0]%(busname)s_wdata;
  wire [C_%(BUSNAME)s_DATA_WIDTH-1 : 0] %(busname)s_wdata_wire;
  wire [5:0]%(busname)s_wid;
  wire %(busname)s_wlast;
  wire %(busname)s_wready;
  wire [(C_%(BUSNAME)s_DATA_WIDTH/8)-1:0]%(busname)s_wstrb;
  wire %(busname)s_wvalid;
  wire RDY_%(busname)s_write_writeAddr;
  wire RDY_%(busname)s_write_writeData;
  wire RDY_%(busname)s_write_writeResponse;
  wire RDY_%(busname)s_read_readAddr;
  wire RDY_%(busname)s_read_readData;
  wire WILL_FIRE_%(busname)s_write_writeAddr;
  wire WILL_FIRE_%(busname)s_write_writeData;
  wire WILL_FIRE_%(busname)s_write_writeResponse;
  wire WILL_FIRE_%(busname)s_read_readAddr;
  wire WILL_FIRE_%(busname)s_read_readData;
'''

top_axi_slave_wires_template='''
  wire [31:0]%(busname)s_araddr;
  wire [1:0]%(busname)s_arburst;
  wire [3:0]%(busname)s_arcache;
  wire [11:0]%(busname)s_arid;
  wire [3:0]%(busname)s_arlen;
  wire [1:0]%(busname)s_arlock;
  wire [2:0]%(busname)s_arprot;
  wire %(busname)s_arready;
  wire [2:0]%(busname)s_arsize;
  wire %(busname)s_arvalid;
  wire [31:0]%(busname)s_awaddr;
  wire [1:0]%(busname)s_awburst;
  wire [3:0]%(busname)s_awcache;
  wire [11:0]%(busname)s_awid;
  wire [3:0]%(busname)s_awlen;
  wire [1:0]%(busname)s_awlock;
  wire [2:0]%(busname)s_awprot;
  wire %(busname)s_awready;
  wire [2:0]%(busname)s_awsize;
  wire %(busname)s_awvalid;
  wire [11:0]%(busname)s_wid;
  wire [11:0]%(busname)s_bid;
  wire %(busname)s_bready;
  wire [1:0]%(busname)s_bresp;
  wire %(busname)s_bvalid;
  wire [31:0]%(busname)s_rdata;
  wire [11:0]%(busname)s_rid;
  wire %(busname)s_rlast;
  wire %(busname)s_rready;
  wire [1:0]%(busname)s_rresp;
  wire %(busname)s_rvalid;
  wire [31:0]%(busname)s_wdata;
  wire %(busname)s_wlast;
  wire %(busname)s_wready;
  wire [3:0]%(busname)s_wstrb;
  wire %(busname)s_wvalid;

  wire %(busname)s_mem0_araddr_matches;
  wire %(busname)s_mem0_awaddr_matches;

  wire [C_%(BUSNAME)s_DATA_WIDTH-1 : 0] %(busname)s_read_readData;
  wire [1 : 0] %(busname)s_write_writeResponse;

  wire EN_%(busname)s_read_readAddr;
  wire RDY_%(busname)s_read_readAddr;
  wire EN_%(busname)s_read_readData;
  wire RDY_%(busname)s_read_readData;
  wire EN_%(busname)s_write_writeAddr;
  wire RDY_%(busname)s_write_writeAddr;
  wire EN_%(busname)s_write_writeData;
  wire RDY_%(busname)s_write_writeData;
  wire EN_%(busname)s_write_writeResponse;
  wire RDY_%(busname)s_write_writeResponse;
  wire RDY_%(busname)s_write_bid;
'''

top_dut_axi_master_port_map_template='''
        .%(busname)s_aclk(processing_system7_fclk_clk0),
        .%(busname)s_araddr(%(busname)s_araddr),
        .%(busname)s_arburst(%(busname)s_arburst),
        .%(busname)s_arcache(%(busname)s_arcache),
        .%(busname)s_aresetn(processing_system7_fclk_reset0_n),
        .%(busname)s_arid(%(busname)s_arid),
        .%(busname)s_arlen(%(busname)s_arlen),
        .%(busname)s_arprot(%(busname)s_arprot),
        .%(busname)s_arready(%(busname)s_arready),
        .%(busname)s_arsize(%(busname)s_arsize),
        .%(busname)s_arvalid(%(busname)s_arvalid),
        .%(busname)s_awaddr(%(busname)s_awaddr),
        .%(busname)s_awburst(%(busname)s_awburst),
        .%(busname)s_awcache(%(busname)s_awcache),
        .%(busname)s_awid(%(busname)s_awid),
        .%(busname)s_awlen(%(busname)s_awlen),
        .%(busname)s_awprot(%(busname)s_awprot),
        .%(busname)s_awready(%(busname)s_awready),
        .%(busname)s_awsize(%(busname)s_awsize),
        .%(busname)s_awvalid(%(busname)s_awvalid),
        .%(busname)s_bid(%(busname)s_bid),
        .%(busname)s_bready(%(busname)s_bready),
        .%(busname)s_bresp(%(busname)s_bresp),
        .%(busname)s_bvalid(%(busname)s_bvalid),
        .%(busname)s_rdata(%(busname)s_rdata),
        .%(busname)s_rid(%(busname)s_rid),
        .%(busname)s_rlast(%(busname)s_rlast),
        .%(busname)s_rready(%(busname)s_rready),
        .%(busname)s_rresp(%(busname)s_rresp),
        .%(busname)s_rvalid(%(busname)s_rvalid),
        .%(busname)s_wdata(%(busname)s_wdata),
        .%(busname)s_wid(%(busname)s_wid),
        .%(busname)s_wlast(%(busname)s_wlast),
        .%(busname)s_wready(%(busname)s_wready),
        .%(busname)s_wstrb(%(busname)s_wstrb),
        .%(busname)s_wvalid(%(busname)s_wvalid),
'''

top_ps7_axi_master_port_map_template='''
        .S_AXI_%(ps7bus)s_ACLK(processing_system7_1_fclk_clk0),
        .S_AXI_%(ps7bus)s_ARADDR(%(busname)s_araddr),
        .S_AXI_%(ps7bus)s_ARBURST(%(busname)s_arburst),
        .S_AXI_%(ps7bus)s_ARCACHE(%(busname)s_arcache),
        .S_AXI_%(ps7bus)s_ARID(%(busname)s_arid),
        .S_AXI_%(ps7bus)s_ARLEN(%(busname)s_arlen),
        .S_AXI_%(ps7bus)s_ARLOCK({GND_1,GND_1}),
        .S_AXI_%(ps7bus)s_ARPROT(%(busname)s_arprot),
        .S_AXI_%(ps7bus)s_ARQOS({GND_1,GND_1,GND_1,GND_1}),
        .S_AXI_%(ps7bus)s_ARREADY(%(busname)s_arready),
        .S_AXI_%(ps7bus)s_ARSIZE(%(busname)s_arsize),
        .S_AXI_%(ps7bus)s_ARVALID(%(busname)s_arvalid),
        .S_AXI_%(ps7bus)s_AWADDR(%(busname)s_awaddr),
        .S_AXI_%(ps7bus)s_AWBURST(%(busname)s_awburst),
        .S_AXI_%(ps7bus)s_AWCACHE(%(busname)s_awcache),
        .S_AXI_%(ps7bus)s_AWID(%(busname)s_awid),
        .S_AXI_%(ps7bus)s_AWLEN(%(busname)s_awlen),
        .S_AXI_%(ps7bus)s_AWLOCK({GND_1,GND_1}),
        .S_AXI_%(ps7bus)s_AWPROT(%(busname)s_awprot),
        .S_AXI_%(ps7bus)s_AWQOS({GND_1,GND_1,GND_1,GND_1}),
        .S_AXI_%(ps7bus)s_AWREADY(%(busname)s_awready),
        .S_AXI_%(ps7bus)s_AWSIZE(%(busname)s_awsize),
        .S_AXI_%(ps7bus)s_AWVALID(%(busname)s_awvalid),
        .S_AXI_%(ps7bus)s_BID(%(busname)s_bid),
        .S_AXI_%(ps7bus)s_BREADY(%(busname)s_bready),
        .S_AXI_%(ps7bus)s_BRESP(%(busname)s_bresp),
        .S_AXI_%(ps7bus)s_BVALID(%(busname)s_bvalid),
        .S_AXI_%(ps7bus)s_RDATA(%(busname)s_rdata),
        .S_AXI_%(ps7bus)s_RID(%(busname)s_rid),
        .S_AXI_%(ps7bus)s_RLAST(%(busname)s_rlast),
        .S_AXI_%(ps7bus)s_RREADY(%(busname)s_rready),
        .S_AXI_%(ps7bus)s_RRESP(%(busname)s_rresp),
        .S_AXI_%(ps7bus)s_RVALID(%(busname)s_rvalid),
        .S_AXI_%(ps7bus)s_WDATA(%(busname)s_wdata),
        .S_AXI_%(ps7bus)s_WID(%(busname)s_wid),
        .S_AXI_%(ps7bus)s_WLAST(%(busname)s_wlast),
        .S_AXI_%(ps7bus)s_WREADY(%(busname)s_wready),
        .S_AXI_%(ps7bus)s_WSTRB(%(busname)s_wstrb),
        .S_AXI_%(ps7bus)s_WVALID(%(busname)s_wvalid),
        /* .S_AXI_%(ps7bus)s_RDISSUECAP1_EN(GND_1), */
        /* .S_AXI_%(ps7bus)s_WRISSUECAP1_EN(GND_1), */
'''

top_ps7_axi_slave_port_map_template='''
        .M_AXI_GP0_ACLK(processing_system7_1_fclk_clk0),
        .M_AXI_GP0_ARADDR(%(busname)s_araddr),
        .M_AXI_GP0_ARBURST(%(busname)s_arburst),
        .M_AXI_GP0_ARCACHE(%(busname)s_arcache),
        .M_AXI_GP0_ARID(%(busname)s_arid),
        .M_AXI_GP0_ARLEN(%(busname)s_arlen),
        .M_AXI_GP0_ARLOCK(%(busname)s_arlock),
        .M_AXI_GP0_ARPROT(%(busname)s_arprot),
        .M_AXI_GP0_ARREADY(%(busname)s_arready),
        .M_AXI_GP0_ARSIZE(%(busname)s_arsize),
        .M_AXI_GP0_ARVALID(%(busname)s_arvalid),
        .M_AXI_GP0_AWADDR(%(busname)s_awaddr),
        .M_AXI_GP0_AWBURST(%(busname)s_awburst),
        .M_AXI_GP0_AWCACHE(%(busname)s_awcache),
        .M_AXI_GP0_AWID(%(busname)s_awid),
        .M_AXI_GP0_AWLEN(%(busname)s_awlen),
        .M_AXI_GP0_AWLOCK(%(busname)s_awlock),
        .M_AXI_GP0_AWPROT(%(busname)s_awprot),
        .M_AXI_GP0_AWREADY(%(busname)s_awready),
        .M_AXI_GP0_AWSIZE(%(busname)s_awsize),
        .M_AXI_GP0_AWVALID(%(busname)s_awvalid),
        .M_AXI_GP0_BID(%(busname)s_bid),
        .M_AXI_GP0_BREADY(%(busname)s_bready),
        .M_AXI_GP0_BRESP(%(busname)s_bresp),
        .M_AXI_GP0_BVALID(%(busname)s_bvalid),
        .M_AXI_GP0_RDATA(%(busname)s_rdata),
        .M_AXI_GP0_RID(%(busname)s_rid),
        .M_AXI_GP0_RLAST(%(busname)s_rlast),
        .M_AXI_GP0_RREADY(%(busname)s_rready),
        .M_AXI_GP0_RRESP(%(busname)s_rresp),
        .M_AXI_GP0_RVALID(%(busname)s_rvalid),
        .M_AXI_GP0_WDATA(%(busname)s_wdata),
        .M_AXI_GP0_WLAST(%(busname)s_wlast),
        .M_AXI_GP0_WID(%(busname)s_wid),
        .M_AXI_GP0_WREADY(%(busname)s_wready),
        .M_AXI_GP0_WSTRB(%(busname)s_wstrb),
        .M_AXI_GP0_WVALID(%(busname)s_wvalid),
'''

axi_master_parameter_verilog_template='''
parameter C_%(BUSNAME)s_DATA_WIDTH = %(buswidth)s;
parameter C_%(BUSNAME)s_ADDR_WIDTH = 32;
parameter C_%(BUSNAME)s_BURSTLEN_WIDTH = %(burstlenwidth)s;
parameter C_%(BUSNAME)s_PROT_WIDTH = %(protwidth)s;
parameter C_%(BUSNAME)s_CACHE_WIDTH = %(cachewidth)s;
parameter C_%(BUSNAME)s_ID_WIDTH = 6;
'''

axi_slave_parameter_verilog_template='''
parameter C_%(BUSNAME)s_DATA_WIDTH = 32;
parameter C_%(BUSNAME)s_ADDR_WIDTH = 32;
parameter C_%(BUSNAME)s_ID_WIDTH = 12;
parameter C_%(BUSNAME)s_MEM0_BASEADDR = 32'h%(busbase)s;
parameter C_%(BUSNAME)s_MEM0_HIGHADDR = 32'h%(bushigh)s;
'''

axi_master_port_decl_verilog_template='''
//============ %(BUSNAME)s ============
wire [C_%(BUSNAME)s_DATA_WIDTH - 1 : 0] %(busname)s_wdata_wire;
//============ %(BUSNAME)s ============
'''

axi_master_port_map_verilog_template='''
      .EN_%(busname)s_read_readAddr(WILL_FIRE_%(busname)s_read_readAddr),
      .%(busname)s_read_readAddr(%(busname)s_araddr),
      .RDY_%(busname)s_read_readAddr(RDY_%(busname)s_read_readAddr),

      .%(busname)s_read_readBurstLen(%(busname)s_arlen),
      .RDY_%(busname)s_read_readBurstLen(RDY_%(busname)s_read_readBurstLen),

      .%(busname)s_read_readBurstWidth(%(busname)s_arsize),
      .RDY_%(busname)s_read_readBurstWidth(RDY_%(busname)s_read_readBurstWidth),

      .%(busname)s_read_readBurstType(%(busname)s_arburst),
      .RDY_%(busname)s_read_readBurstType(RDY_%(busname)s_read_readBurstType),

      .%(busname)s_read_readBurstProt(%(busname)s_arprot),
      .RDY_%(busname)s_read_readBurstProt(RDY_%(busname)s_read_readBurstProt),

      .%(busname)s_read_readBurstCache(%(busname)s_arcache),
      .RDY_%(busname)s_read_readBurstCache(RDY_%(busname)s_read_readBurstCache),

      .%(busname)s_read_readId(%(busname)s_arid),
      .RDY_%(busname)s_read_readId(RDY_%(busname)s_read_readId),

      .%(busname)s_read_readData_data(%(busname)s_rdata),
      .%(busname)s_read_readData_resp(%(busname)s_rresp),
      .%(busname)s_read_readData_last(%(busname)s_rlast),
      .%(busname)s_read_readData_id(%(busname)s_rid),
      .EN_%(busname)s_read_readData(WILL_FIRE_%(busname)s_read_readData),
      .RDY_%(busname)s_read_readData(RDY_%(busname)s_read_readData),

      .EN_%(busname)s_write_writeAddr(WILL_FIRE_%(busname)s_write_writeAddr),
      .%(busname)s_write_writeAddr(%(busname)s_awaddr),
      .RDY_%(busname)s_write_writeAddr(RDY_%(busname)s_write_writeAddr),

      .%(busname)s_write_writeBurstLen(%(busname)s_awlen),
      .RDY_%(busname)s_write_writeBurstLen(RDY_%(busname)s_write_writeBurstLen),

      .%(busname)s_write_writeBurstWidth(%(busname)s_awsize),
      .RDY_%(busname)s_write_writeBurstWidth(RDY_%(busname)s_write_writeBurstWidth),

      .%(busname)s_write_writeBurstType(%(busname)s_awburst),
      .RDY_%(busname)s_write_writeBurstType(RDY_%(busname)s_write_writeBurstType),

      .%(busname)s_write_writeBurstProt(%(busname)s_awprot),
      .RDY_%(busname)s_write_writeBurstProt(RDY_%(busname)s_write_writeBurstProt),

      .%(busname)s_write_writeBurstCache(%(busname)s_awcache),
      .RDY_%(busname)s_write_writeBurstCache(RDY_%(busname)s_write_writeBurstCache),

      .%(busname)s_write_writeId(%(busname)s_awid),
      .RDY_%(busname)s_write_writeId(RDY_%(busname)s_write_writeId),

      .EN_%(busname)s_write_writeData(WILL_FIRE_%(busname)s_write_writeData),
      .%(busname)s_write_writeData(%(busname)s_wdata_wire),
      .RDY_%(busname)s_write_writeData(RDY_%(busname)s_write_writeData),

      .%(busname)s_write_writeWid(%(busname)s_wid),
      .RDY_%(busname)s_write_writeWid(RDY_%(busname)s_write_writeWid),

      .%(busname)s_write_writeDataByteEnable(%(busname)s_wstrb),
      .RDY_%(busname)s_write_writeDataByteEnable(RDY_%(busname)s_write_writeDataByteEnable),

      .%(busname)s_write_writeLastDataBeat(%(busname)s_wlast),
      .RDY_%(busname)s_write_writeLastDataBeat(RDY_%(busname)s_write_writeLastDataBeat),

      .%(busname)s_write_writeResponse_responseCode(%(busname)s_bresp),
      .%(busname)s_write_writeResponse_id(%(busname)s_bid),
      .EN_%(busname)s_write_writeResponse(WILL_FIRE_%(busname)s_write_writeResponse),
      .RDY_%(busname)s_write_writeResponse(RDY_%(busname)s_write_writeResponse),
'''

axi_slave_port_map_verilog_template='''
      .%(busname)s_read_readAddr_addr(%(busname)s_araddr),
      .%(busname)s_read_readAddr_burstLen(%(busname)s_arlen),
      .%(busname)s_read_readAddr_burstWidth(%(busname)s_arsize),
      .%(busname)s_read_readAddr_burstType(%(busname)s_arburst),
      .%(busname)s_read_readAddr_burstProt(%(busname)s_arprot),
      .%(busname)s_read_readAddr_burstCache(%(busname)s_arcache),
      .%(busname)s_read_readAddr_arid(%(busname)s_arid),
      .EN_%(busname)s_read_readAddr(EN_%(busname)s_read_readAddr),
      .RDY_%(busname)s_read_readAddr(RDY_%(busname)s_read_readAddr),

      .%(busname)s_read_last(%(busname)s_rlast),
      .%(busname)s_read_rid(%(busname)s_rid),
      .EN_%(busname)s_read_readData(EN_%(busname)s_read_readData),
      .%(busname)s_read_readData(%(busname)s_rdata),
      .RDY_%(busname)s_read_readData(RDY_%(busname)s_read_readData),

      .%(busname)s_write_writeAddr_addr(%(busname)s_awaddr),
      .%(busname)s_write_writeAddr_burstLen(%(busname)s_awlen),
      .%(busname)s_write_writeAddr_burstWidth(%(busname)s_awsize),
      .%(busname)s_write_writeAddr_burstType(%(busname)s_awburst),
      .%(busname)s_write_writeAddr_burstProt(%(busname)s_awprot),
      .%(busname)s_write_writeAddr_burstCache(%(busname)s_awcache),
      .%(busname)s_write_writeAddr_awid(%(busname)s_awid),
      .EN_%(busname)s_write_writeAddr(EN_%(busname)s_write_writeAddr),
      .RDY_%(busname)s_write_writeAddr(RDY_%(busname)s_write_writeAddr),

      .%(busname)s_write_writeData_data(%(busname)s_wdata),
      .%(busname)s_write_writeData_byteEnable(%(busname)s_wstrb),
      .%(busname)s_write_writeData_last(%(busname)s_wlast),
      .%(busname)s_write_writeData_wid(%(busname)s_wid),
      .EN_%(busname)s_write_writeData(EN_%(busname)s_write_writeData),
      .RDY_%(busname)s_write_writeData(RDY_%(busname)s_write_writeData),

      .EN_%(busname)s_write_writeResponse(EN_%(busname)s_write_writeResponse),
      .RDY_%(busname)s_write_writeResponse(RDY_%(busname)s_write_writeResponse),
      .%(busname)s_write_writeResponse(%(busname)s_bresp),
      .EN_%(busname)s_write_bid(EN_%(busname)s_write_writeResponse),
      .RDY_%(busname)s_write_bid(RDY_%(busname)s_write_bid),
      .%(busname)s_write_bid(%(busname)s_bid),
'''

axi_master_scheduler_verilog_template='''
assign WILL_FIRE_%(busname)s_read_readAddr = (%(busname)s_arready & RDY_%(busname)s_read_readAddr);
assign WILL_FIRE_%(busname)s_read_readData = (%(busname)s_rvalid & RDY_%(busname)s_read_readData);
assign %(busname)s_arvalid = RDY_%(busname)s_read_readAddr;
assign %(busname)s_rready = RDY_%(busname)s_read_readData;

assign WILL_FIRE_%(busname)s_write_writeAddr = (%(busname)s_awready & RDY_%(busname)s_write_writeAddr);
assign WILL_FIRE_%(busname)s_write_writeData = (%(busname)s_wready & RDY_%(busname)s_write_writeData);
assign WILL_FIRE_%(busname)s_write_writeResponse = (%(busname)s_bvalid & RDY_%(busname)s_write_writeResponse);
assign %(busname)s_awvalid = RDY_%(busname)s_write_writeAddr;
assign %(busname)s_wvalid = RDY_%(busname)s_write_writeData;
assign %(busname)s_bready = RDY_%(busname)s_write_writeResponse;
assign %(busname)s_wdata = (RDY_%(busname)s_write_writeData == 1) ? %(busname)s_wdata_wire : 32'hdeadd00d;
'''

axi_slave_scheduler_verilog_template='''
assign %(busname)s_mem0_araddr_matches = (%(busname)s_araddr >= C_%(BUSNAME)s_MEM0_BASEADDR & %(busname)s_araddr <= C_%(BUSNAME)s_MEM0_HIGHADDR);
assign %(busname)s_mem0_awaddr_matches = (%(busname)s_awaddr >= C_%(BUSNAME)s_MEM0_BASEADDR & %(busname)s_awaddr <= C_%(BUSNAME)s_MEM0_HIGHADDR);

assign %(busname)s_arready_unbuf = RDY_%(busname)s_read_readAddr & %(busname)s_arvalid & %(busname)s_mem0_araddr_matches;
assign %(busname)s_arready = %(busname)s_arready_unbuf;
assign %(busname)s_rvalid_unbuf = EN_%(busname)s_read_readData;
assign %(busname)s_rvalid = %(busname)s_rvalid_unbuf;
assign %(busname)s_rresp[1:0]  = "00";

assign %(busname)s_awready  = RDY_%(busname)s_write_writeAddr & %(busname)s_mem0_awaddr_matches;
assign %(busname)s_wready = RDY_%(busname)s_write_writeData;
assign %(busname)s_bvalid  = EN_%(busname)s_write_writeResponse;
assign %(busname)s_bresp = %(busname)s_write_writeResponse;

assign EN_%(busname)s_read_readAddr = RDY_%(busname)s_read_readAddr & %(busname)s_arvalid & %(busname)s_mem0_araddr_matches;
assign EN_%(busname)s_read_readData = RDY_%(busname)s_read_readData & %(busname)s_rready;

assign EN_%(busname)s_write_writeAddr = RDY_%(busname)s_write_writeAddr & %(busname)s_awvalid & %(busname)s_mem0_awaddr_matches;
assign EN_%(busname)s_write_writeData = RDY_%(busname)s_write_writeData & %(busname)s_wvalid;
assign EN_%(busname)s_write_writeResponse = RDY_%(busname)s_write_writeResponse & %(busname)s_bready;
'''

busHandlers={}

class Hdmi:
    def __init__(self):
        busHandlers['HDMI'] = self
    def top_bus_ports(self, busname,t,params):
        return '''    output hdmi_clk,
    output hdmi_vsync,
    output hdmi_hsync,
    output hdmi_de,
    output [15:0] hdmi_data,
'''
    def top_bus_wires(self, busname,t,params):
        return ''
    def ps7_bus_port_map(self,busname,t,params):
        return '''
'''
    def dut_bus_port_map(self, busname,t,params):
        return '''
      .%(busname)s_hdmi_vsync(hdmi_vsync),
      .%(busname)s_hdmi_hsync(hdmi_hsync),
      .%(busname)s_hdmi_de(hdmi_de),
      .%(busname)s_hdmi_data(hdmi_data),
''' % {'busname': busname}
    def top_bus_assignments(self,busname,t,params):
        return '''
'''
    def bus_assignments(self,busname,t,params):
        return ''
    def pinout(self, board):
        return hdmi_pinout[board]
Hdmi()

class Leds:
    def __init__(self):
        busHandlers['LEDS'] = self
    def top_bus_ports(self, busname,t,params):
        return ''
    def top_bus_wires(self, busname,t,params):
        return ''
    def ps7_bus_port_map(self,busname,t,params):
        return ''
    def dut_bus_port_map(self, busname,t,params):
        return '''
      .%(busname)s_leds(GPIO_leds),
''' % {'busname': busname}
    def top_bus_assignments(self,busname,t,params):
        return ''
    def bus_assignments(self,busname,t,params):
        return ''
    def pinout(self, board):
        return led_pinout[board]
Leds()

class ImageonVita:
    def __init__(self):
        busHandlers['ImageonVita'] = self
    def top_bus_ports(self, busname,t,params):
        return '''
/* imageon vita *****************************************/

    inout fmc_imageon_iic_0_sda,
    inout fmc_imageon_iic_0_scl,
    output fmc_imageon_iic_0_rst_pin,
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
     wire fmc_imageon_iic_0_scl_T;
     wire fmc_imageon_iic_0_scl_O;
     wire fmc_imageon_iic_0_scl_I;
     wire fmc_imageon_iic_0_sda_T;
     wire fmc_imageon_iic_0_sda_O;
     wire fmc_imageon_iic_0_sda_I;
     wire fbbozo;
'''
    def ps7_bus_port_map(self,busname,t,params):
        return '''
    .I2C1_SDA_I(fmc_imageon_iic_0_sda_I),
    .I2C1_SDA_O(fmc_imageon_iic_0_sda_O),
    .I2C1_SDA_T(fmc_imageon_iic_0_sda_T),
    .I2C1_SCL_I(fmc_imageon_iic_0_scl_I),
    .I2C1_SCL_O(fmc_imageon_iic_0_scl_O),
    .I2C1_SCL_T(fmc_imageon_iic_0_scl_T),
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
    .CLK_hdmi_hdmi_clock_if(hdmi_clk),
    /* SPI port */
    .CLK_spi_invertedClock(io_vita_spi_sclk),
    .spi_sel_n(io_vita_spi_ssel_n),
    .spi_mosi(io_vita_spi_mosi),
    .spi_miso_v(io_vita_spi_miso),
'''
    def top_bus_assignments(self,busname,t,params):
        return '''
     IOBUF#(.DRIVE(12), .IOSTANDARD("LVCMOS25"), .SLEW("SLOW")) (
     .IO(fmc_imageon_iic_0_scl), .O(fmc_imageon_iic_0_scl_I),
     .I(fmc_imageon_iic_0_scl_O), .T(fmc_imageon_iic_0_scl_T)); 
     IOBUF#(.DRIVE(12), .IOSTANDARD("LVCMOS25"), .SLEW("SLOW")) (
     .IO(fmc_imageon_iic_0_sda), .O(fmc_imageon_iic_0_sda_I),
     .I(fmc_imageon_iic_0_sda_O), .T(fmc_imageon_iic_0_sda_T));
'''
    def bus_assignments(self,busname,t,params):
        return '''
'''
    def pinout(self, board):
        return imageon_pinout[board]
ImageonVita()

class InterfaceMixin:
    def axiMasterBusSubst(self, busnumber, businfo):
        (busname,t,params) = businfo
        addrwidth = params[0].numeric()
        buswidth = params[1].numeric()
        buswidthbytes = buswidth / 8
        # print 'bustype: ', t, ('AXI4' if (t == 'AxiMaster') else 'AXI3'), buswidth
        dutName = util.decapitalize(self.base)
        hpBusOffset = 0
        if buswidth == 32:
            ps7bustype = 'GP'
            ps7bus = 'GP%s' % busnumber
        elif use_acp and busnumber == 0:
            ps7bustype = 'ACP'
            ps7bus = 'ACP'
            hpBusOffset = -1
        else:
            ps7bustype = 'HP'
            ps7bus = 'HP%s' % (busnumber + hpBusOffset)
        return {
            'dut': dutName,
            'BUSNAME': busname.upper(),
            'busname': busname,
            'busnumber': busnumber,
            'addrwidth': addrwidth,
            'buswidth': buswidth,
            'buswidthbytes': buswidthbytes,
            'ps7bustype': ps7bustype,
            'ps7bus': ps7bus,
            'burstlenwidth': 8 if (t == 'AxiMaster') else 4,
            'protwidth': 3 if (t == 'AxiMaster') else 2,
            'cachewidth': 4 if (t == 'AxiMaster') else 3,
            'axiprotocol': 'AXI4' if (t == 'AxiMaster') else 'AXI3',
            }
    def writeTopVerilog(self, topverilogname, silent=False):
        if not silent:
            print 'Writing top Verilog file', topverilogname
        topverilog = util.createDirAndOpen(topverilogname, 'w')
        dutName = util.decapitalize(self.base)
        axiMasters = self.collectInterfaceNames('Axi3?Client', True)
        axiSlaves = [('ctrl','AxiSlave',[])] + self.collectInterfaceNames('AxiSlave')
        masterBusSubsts = [self.axiMasterBusSubst(busnumber,axiMasters[busnumber]) for busnumber in range(len(axiMasters))]
        slaveBusSubsts = []
        for i in range(len(axiSlaves)):
            (busname,t,params) = axiSlaves[i]
            slaveBusSubsts.append({'busname': busname,
                                   'BUSNAME': busname.upper(),
                                   'busbase': '%08x' % (0x6e400000 + 0x00020000*i),
                                   'bushigh': '%08x' % (0x6e400000 + 0x00020000*i + 0xFFFFF)})
        buses = {}
        for busType in busHandlers:
            b = self.collectInterfaceNames(busType)
            buses[busType] = b
        if len(buses['LEDS']):
            default_leds_assignment = ''
        else:
            default_leds_assignment = '''assign GPIO_leds = 8'haa;'''
        substs = {
            'dut': dutName.lower(),
            'Dut': util.capitalize(self.base),
            'axi_master_parameters':
                ''.join([axi_master_parameter_verilog_template % subst for subst in masterBusSubsts]),
            'axi_slave_parameters':
                ''.join([axi_slave_parameter_verilog_template % subst for subst in slaveBusSubsts]),
            'top_axi_master_wires': ''.join([top_axi_master_wires_template % subst for subst in masterBusSubsts]),
            'top_axi_slave_wires': ''.join([top_axi_slave_wires_template % subst for subst in slaveBusSubsts]),
            'top_dut_axi_master_port_map': ''.join([top_dut_axi_master_port_map_template % subst for subst in masterBusSubsts]),
            'top_ps7_axi_master_port_map': ''.join([top_ps7_axi_master_port_map_template % subst for subst in masterBusSubsts]),
            'top_ps7_axi_slave_port_map': ''.join([top_ps7_axi_slave_port_map_template % subst for subst in slaveBusSubsts]),
            'dut_hdmi_clock_arg': '       .CLK_fmc_imageon_video_clk1(fmc_imageon_video_clk1),\n       .CLK_processing_system7_1_fclk_clk3(processing_system7_1_fclk_clk3),' if len(buses['ImageonVita']) else '       .CLK_hdmi_clock(imageon_clk4x)' if len(buses['HDMI']) else '',
            'top_bus_ports':
                ''.join([''.join([busHandlers[busType].top_bus_ports(busname,t,params) for (busname,t,params) in buses[busType]])
                         for busType in busHandlers]),
            'top_bus_wires':
                ''.join([''.join([busHandlers[busType].top_bus_wires(busname,t,params) for (busname,t,params) in buses[busType]])
                         for busType in busHandlers]),
            'dut_axi_master_port_map': ''.join([axi_master_port_map_verilog_template % subst for subst in masterBusSubsts]),

            'dut_axi_slave_port_map':
                ''.join([axi_slave_port_map_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            'dut_bus_port_map': ''.join([''.join([busHandlers[busType].dut_bus_port_map(busname,t,params)
                                                  for (busname,t,params) in buses[busType]])
                                         for busType in busHandlers]),
            'axi_master_scheduler':
                ''.join([axi_master_scheduler_verilog_template % subst for subst in masterBusSubsts ]),
            'axi_slave_scheduler':
                ''.join([axi_slave_scheduler_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            'ps7_bus_port_map':
                ''.join([''.join([busHandlers[busType].ps7_bus_port_map(busname,t,params) for (busname,t,params) in buses[busType]])
                         for busType in busHandlers]),
            'top_bus_assignments': ''.join([''.join([busHandlers[busType].top_bus_assignments(busname,t,params)
                                                     for (busname,t,params) in buses[busType]])
                                            for busType in busHandlers]),
            'bus_assignments': ''.join([''.join([busHandlers[busType].bus_assignments(busname,t,params)
                                                 for (busname,t,params) in buses[busType]])
                                        for busType in busHandlers]),
            'default_leds_assignment': default_leds_assignment,
            'irq_f2p_assignments': ''.join(self.collectInterrupts()),
            'dut_interrupt_map' : ''.join(util.intersperse(',\n      ', 
                                                      ['.interrupts_%s__read(%s_%s_interrupt)' % (x,dutName,x) for x in range (0,self.numPortals)])),
            'interrupt_wire_decls' : ''.join(['  wire %s_%s_interrupt;\n' % (dutName,x) for x in range(0,self.numPortals)])
            }
        topverilog.write(top_verilog_template % substs)
        topverilog.close()
        return
    
    def collectInterrupts(self):
        dutName = util.decapitalize(self.base)
        rv = []
        for x in range(0,15):
            if self.numPortals > x:
                rv.append('assign irq_f2p[%s] = %s_%s_interrupt;\n' % (x,dutName,x))
            else:
                rv.append('assign irq_f2p[%s] = 0;\n' % (x))
        return rv


    def writeUcf(self, ucfname, boardname='zc702', silent=False):
        if not silent:
            print 'Writing UCF file', ucfname
        ucf = util.createDirAndOpen(ucfname, 'w')
        dutName = util.decapitalize(self.base)
        hdmiBus = self.collectInterfaceNames('HDMI')
        if len(hdmiBus):
            ucf.write(hdmi_ucf_template[boardname])
            #ucf.write(usr_clk_ucf_template)
            ucf.write(xadc_ucf_template[boardname])
        ucf.write(default_clk_ucf_template)
        ucf.close()
        return

    def writeXdc(self, xdcname, boardname='zc702', silent=False):
        if not silent:
            print 'Writing XDC file', xdcname
        xdc = util.createDirAndOpen(xdcname, 'w')
        dutName = util.decapitalize(self.base)
        if not len(self.collectInterfaceNames('LEDS')):
            ## we always connect these pins to a default pattern
            for (name, pin, iostandard, direction) in led_pinout[boardname]:
                xdc.write(xdc_template % { 'name': name, 'pin': pin, 'iostandard': iostandard, 'direction': direction })
        for busType in busHandlers:
            buses = self.collectInterfaceNames(busType)
            if len(buses):
                for entry in busHandlers[busType].pinout(boardname):
                    if len(entry) == 4:
                        (name, pin, iostandard, direction) = entry
                        xdc.write(xdc_template
                                  % { 'name': name, 'pin': pin, 'iostandard': iostandard, 'direction': direction })
                        if (iostandard == 'LVDS_25'):
                            xdc.write(xdc_diff_term_template
                                      % { 'name': name, 'pin': pin, 'iostandard': iostandard, 'direction': direction })
        xdc.close()
        return
    def writeImpactCmd(self, impactcmdname):
        f = util.createDirAndOpen(impactcmdname, 'w')
        f.write(impactCmdTemplate % { 'base': self.base.lower(), 'Base': self.base })
        f.close()
    def writeProgramTcl(self, programtclname):
        f = util.createDirAndOpen(programtclname, 'w')
        f.write(programTclTemplate % { 'base': self.base.lower(), 'Base': self.base })
        f.close()
