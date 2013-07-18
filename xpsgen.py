
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
        ('GPIO_leds[7]', 'U14', 'LVCMOS33', 'OUTPUT')]
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
        ( "i2c1_scl", 'AA18', 'LVCMOS25', 'BIDIR'),
        ( "i2c1_sda", 'Y16', 'LVCMOS25', 'BIDIR'),
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
        ( "i2c1_scl", 'AA18', 'LVCMOS33', 'BIDIR'),
        ( "i2c1_sda", 'Y16', 'LVCMOS33', 'BIDIR'),
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
%(top_hdmi_ports)s
    output [7:0] GPIO_leds);

  wire GND_1;
  wire %(dut)s_1_interrupt;
%(top_axi_master_wires)s
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
  wire processing_system7_1_fclk_reset0_n;
  wire processing_system7_1_fixed_io_DDR_VRN;
  wire processing_system7_1_fixed_io_DDR_VRP;
  wire [53:0]processing_system7_1_fixed_io_MIO;
  wire processing_system7_1_fixed_io_PS_CLK;
  wire processing_system7_1_fixed_io_PS_PORB;
  wire processing_system7_1_fixed_io_PS_SRSTB;
  wire [31:0]processing_system7_1_m_axi_gp0_ARADDR;
  wire [1:0]processing_system7_1_m_axi_gp0_ARBURST;
  wire [3:0]processing_system7_1_m_axi_gp0_ARCACHE;
  wire [11:0]processing_system7_1_m_axi_gp0_ARID;
  wire [3:0]processing_system7_1_m_axi_gp0_ARLEN;
  wire [1:0]processing_system7_1_m_axi_gp0_ARLOCK;
  wire [2:0]processing_system7_1_m_axi_gp0_ARPROT;
  wire processing_system7_1_m_axi_gp0_ARREADY;
  wire [2:0]processing_system7_1_m_axi_gp0_ARSIZE;
  wire processing_system7_1_m_axi_gp0_ARVALID;
  wire [31:0]processing_system7_1_m_axi_gp0_AWADDR;
  wire [1:0]processing_system7_1_m_axi_gp0_AWBURST;
  wire [3:0]processing_system7_1_m_axi_gp0_AWCACHE;
  wire [11:0]processing_system7_1_m_axi_gp0_AWID;
  wire [3:0]processing_system7_1_m_axi_gp0_AWLEN;
  wire [1:0]processing_system7_1_m_axi_gp0_AWLOCK;
  wire [2:0]processing_system7_1_m_axi_gp0_AWPROT;
  wire processing_system7_1_m_axi_gp0_AWREADY;
  wire [2:0]processing_system7_1_m_axi_gp0_AWSIZE;
  wire processing_system7_1_m_axi_gp0_AWVALID;
  wire [11:0]processing_system7_1_m_axi_gp0_BID;
  wire processing_system7_1_m_axi_gp0_BREADY;
  wire [1:0]processing_system7_1_m_axi_gp0_BRESP;
  wire processing_system7_1_m_axi_gp0_BVALID;
  wire [31:0]processing_system7_1_m_axi_gp0_RDATA;
  wire [11:0]processing_system7_1_m_axi_gp0_RID;
  wire processing_system7_1_m_axi_gp0_RLAST;
  wire processing_system7_1_m_axi_gp0_RREADY;
  wire [1:0]processing_system7_1_m_axi_gp0_RRESP;
  wire processing_system7_1_m_axi_gp0_RVALID;
  wire [31:0]processing_system7_1_m_axi_gp0_WDATA;
  wire processing_system7_1_m_axi_gp0_WLAST;
  wire processing_system7_1_m_axi_gp0_WREADY;
  wire [3:0]processing_system7_1_m_axi_gp0_WSTRB;
  wire processing_system7_1_m_axi_gp0_WVALID;
  wire i2c1_scl_i;
  wire i2c1_scl_o;
  wire i2c1_scl_t;
  wire i2c1_sda_i;
  wire i2c1_sda_o;
  wire i2c1_sda_t;

GND GND
       (.G(GND_1));
%(dut)s#(
.C_CTRL_MEM0_BASEADDR (32'h6e400000),
.C_CTRL_MEM0_HIGHADDR (32'h6e41ffff),
.C_CTRL_ADDR_WIDTH(32),
.C_CTRL_ID_WIDTH(12),
) %(dut)s_1
       (.CTRL_ACLK(processing_system7_1_fclk_clk0),
        .CTRL_ARADDR(processing_system7_1_m_axi_gp0_ARADDR),
        .CTRL_ARBURST(processing_system7_1_m_axi_gp0_ARBURST),
        .CTRL_ARCACHE(processing_system7_1_m_axi_gp0_ARCACHE[2:0]),
        .CTRL_ARESETN(processing_system7_1_fclk_reset0_n),
        .CTRL_ARID(processing_system7_1_m_axi_gp0_ARID),
        .CTRL_ARLEN(processing_system7_1_m_axi_gp0_ARLEN),
        .CTRL_ARLOCK(processing_system7_1_m_axi_gp0_ARLOCK[0]),
        .CTRL_ARPROT(processing_system7_1_m_axi_gp0_ARPROT[1:0]),
        .CTRL_ARREADY(processing_system7_1_m_axi_gp0_ARREADY),
        .CTRL_ARSIZE(processing_system7_1_m_axi_gp0_ARSIZE),
        .CTRL_ARVALID(processing_system7_1_m_axi_gp0_ARVALID),
        .CTRL_AWADDR(processing_system7_1_m_axi_gp0_AWADDR),
        .CTRL_AWBURST(processing_system7_1_m_axi_gp0_AWBURST),
        .CTRL_AWCACHE(processing_system7_1_m_axi_gp0_AWCACHE[2:0]),
        .CTRL_AWID(processing_system7_1_m_axi_gp0_AWID),
        .CTRL_AWLEN(processing_system7_1_m_axi_gp0_AWLEN),
        .CTRL_AWLOCK(processing_system7_1_m_axi_gp0_AWLOCK[0]),
        .CTRL_AWPROT(processing_system7_1_m_axi_gp0_AWPROT[1:0]),
        .CTRL_AWREADY(processing_system7_1_m_axi_gp0_AWREADY),
        .CTRL_AWSIZE(processing_system7_1_m_axi_gp0_AWSIZE),
        .CTRL_AWVALID(processing_system7_1_m_axi_gp0_AWVALID),
        .CTRL_BID(processing_system7_1_m_axi_gp0_BID),
        .CTRL_BREADY(processing_system7_1_m_axi_gp0_BREADY),
        .CTRL_BRESP(processing_system7_1_m_axi_gp0_BRESP),
        .CTRL_BVALID(processing_system7_1_m_axi_gp0_BVALID),
        .CTRL_RDATA(processing_system7_1_m_axi_gp0_RDATA),
        .CTRL_RID(processing_system7_1_m_axi_gp0_RID),
        .CTRL_RLAST(processing_system7_1_m_axi_gp0_RLAST),
        .CTRL_RREADY(processing_system7_1_m_axi_gp0_RREADY),
        .CTRL_RRESP(processing_system7_1_m_axi_gp0_RRESP),
        .CTRL_RVALID(processing_system7_1_m_axi_gp0_RVALID),
        .CTRL_WDATA(processing_system7_1_m_axi_gp0_WDATA),
        .CTRL_WLAST(processing_system7_1_m_axi_gp0_WLAST),
        .CTRL_WREADY(processing_system7_1_m_axi_gp0_WREADY),
        .CTRL_WSTRB(processing_system7_1_m_axi_gp0_WSTRB),
        .CTRL_WVALID(processing_system7_1_m_axi_gp0_WVALID),
%(top_dut_axi_master_port_map)s
%(top_dut_hdmi_port_map)s
        .interrupt(%(dut)s_1_interrupt));


processing_system7 processing_system7_1
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
        .FCLK_RESET0_N(processing_system7_1_fclk_reset0_n),
        .IRQ_F2P(%(dut)s_1_interrupt),
        .MIO(FIXED_IO_mio[53:0]),
        .M_AXI_GP0_ACLK(processing_system7_1_fclk_clk0),
        .M_AXI_GP0_ARADDR(processing_system7_1_m_axi_gp0_ARADDR),
        .M_AXI_GP0_ARBURST(processing_system7_1_m_axi_gp0_ARBURST),
        .M_AXI_GP0_ARCACHE(processing_system7_1_m_axi_gp0_ARCACHE),
        .M_AXI_GP0_ARID(processing_system7_1_m_axi_gp0_ARID),
        .M_AXI_GP0_ARLEN(processing_system7_1_m_axi_gp0_ARLEN),
        .M_AXI_GP0_ARLOCK(processing_system7_1_m_axi_gp0_ARLOCK),
        .M_AXI_GP0_ARPROT(processing_system7_1_m_axi_gp0_ARPROT),
        .M_AXI_GP0_ARREADY(processing_system7_1_m_axi_gp0_ARREADY),
        .M_AXI_GP0_ARSIZE(processing_system7_1_m_axi_gp0_ARSIZE),
        .M_AXI_GP0_ARVALID(processing_system7_1_m_axi_gp0_ARVALID),
        .M_AXI_GP0_AWADDR(processing_system7_1_m_axi_gp0_AWADDR),
        .M_AXI_GP0_AWBURST(processing_system7_1_m_axi_gp0_AWBURST),
        .M_AXI_GP0_AWCACHE(processing_system7_1_m_axi_gp0_AWCACHE),
        .M_AXI_GP0_AWID(processing_system7_1_m_axi_gp0_AWID),
        .M_AXI_GP0_AWLEN(processing_system7_1_m_axi_gp0_AWLEN),
        .M_AXI_GP0_AWLOCK(processing_system7_1_m_axi_gp0_AWLOCK),
        .M_AXI_GP0_AWPROT(processing_system7_1_m_axi_gp0_AWPROT),
        .M_AXI_GP0_AWREADY(processing_system7_1_m_axi_gp0_AWREADY),
        .M_AXI_GP0_AWSIZE(processing_system7_1_m_axi_gp0_AWSIZE),
        .M_AXI_GP0_AWVALID(processing_system7_1_m_axi_gp0_AWVALID),
        .M_AXI_GP0_BID(processing_system7_1_m_axi_gp0_BID),
        .M_AXI_GP0_BREADY(processing_system7_1_m_axi_gp0_BREADY),
        .M_AXI_GP0_BRESP(processing_system7_1_m_axi_gp0_BRESP),
        .M_AXI_GP0_BVALID(processing_system7_1_m_axi_gp0_BVALID),
        .M_AXI_GP0_RDATA(processing_system7_1_m_axi_gp0_RDATA),
        .M_AXI_GP0_RID(processing_system7_1_m_axi_gp0_RID),
        .M_AXI_GP0_RLAST(processing_system7_1_m_axi_gp0_RLAST),
        .M_AXI_GP0_RREADY(processing_system7_1_m_axi_gp0_RREADY),
        .M_AXI_GP0_RRESP(processing_system7_1_m_axi_gp0_RRESP),
        .M_AXI_GP0_RVALID(processing_system7_1_m_axi_gp0_RVALID),
        .M_AXI_GP0_WDATA(processing_system7_1_m_axi_gp0_WDATA),
        .M_AXI_GP0_WLAST(processing_system7_1_m_axi_gp0_WLAST),
        .M_AXI_GP0_WREADY(processing_system7_1_m_axi_gp0_WREADY),
        .M_AXI_GP0_WSTRB(processing_system7_1_m_axi_gp0_WSTRB),
        .M_AXI_GP0_WVALID(processing_system7_1_m_axi_gp0_WVALID),
%(top_ps7_axi_master_port_map)s
%(top_ps7_hdmi_port_map)s
        .PS_CLK(FIXED_IO_ps_clk),
        .PS_PORB(FIXED_IO_ps_porb),
        .PS_SRSTB(FIXED_IO_ps_srstb));
   
%(hdmi_iobufs)s
assign GPIO_leds = 8'haa;
endmodule
'''

top_axi_master_wires_template='''
  wire [31:0]%(dut)s_1_%(busname)s_ARADDR;
  wire [1:0]%(dut)s_1_%(busname)s_ARBURST;
  wire [3:0]%(dut)s_1_%(busname)s_ARCACHE;
  wire [5:0]%(dut)s_1_%(busname)s_ARID;
  wire [3:0]%(dut)s_1_%(busname)s_ARLEN;
  wire [2:0]%(dut)s_1_%(busname)s_ARPROT;
  wire %(dut)s_1_%(busname)s_ARREADY;
  wire [2:0]%(dut)s_1_%(busname)s_ARSIZE;
  wire %(dut)s_1_%(busname)s_ARVALID;
  wire [31:0]%(dut)s_1_%(busname)s_AWADDR;
  wire [1:0]%(dut)s_1_%(busname)s_AWBURST;
  wire [3:0]%(dut)s_1_%(busname)s_AWCACHE;
  wire [5:0]%(dut)s_1_%(busname)s_AWID;
  wire [3:0]%(dut)s_1_%(busname)s_AWLEN;
  wire [2:0]%(dut)s_1_%(busname)s_AWPROT;
  wire %(dut)s_1_%(busname)s_AWREADY;
  wire [2:0]%(dut)s_1_%(busname)s_AWSIZE;
  wire %(dut)s_1_%(busname)s_AWVALID;
  wire [5:0]%(dut)s_1_%(busname)s_BID;
  wire %(dut)s_1_%(busname)s_BREADY;
  wire [1:0]%(dut)s_1_%(busname)s_BRESP;
  wire %(dut)s_1_%(busname)s_BVALID;
  wire [%(buswidth)s-1:0]%(dut)s_1_%(busname)s_RDATA;
  wire [5:0]%(dut)s_1_%(busname)s_RID;
  wire %(dut)s_1_%(busname)s_RLAST;
  wire %(dut)s_1_%(busname)s_RREADY;
  wire [1:0]%(dut)s_1_%(busname)s_RRESP;
  wire %(dut)s_1_%(busname)s_RVALID;
  wire [%(buswidth)s-1:0]%(dut)s_1_%(busname)s_WDATA;
  wire [5:0]%(dut)s_1_%(busname)s_WID;
  wire %(dut)s_1_%(busname)s_WLAST;
  wire %(dut)s_1_%(busname)s_WREADY;
  wire [%(buswidthbytes)s-1:0]%(dut)s_1_%(busname)s_WSTRB;
  wire %(dut)s_1_%(busname)s_WVALID;
'''

top_dut_axi_master_port_map_template='''
        .%(busname)s_aclk(processing_system7_1_fclk_clk0),
        .%(busname)s_araddr(%(dut)s_1_%(busname)s_ARADDR),
        .%(busname)s_arburst(%(dut)s_1_%(busname)s_ARBURST),
        .%(busname)s_arcache(%(dut)s_1_%(busname)s_ARCACHE),
        .%(busname)s_aresetn(processing_system7_1_fclk_reset0_n),
        .%(busname)s_arid(%(dut)s_1_%(busname)s_ARID),
        .%(busname)s_arlen(%(dut)s_1_%(busname)s_ARLEN),
        .%(busname)s_arprot(%(dut)s_1_%(busname)s_ARPROT),
        .%(busname)s_arready(%(dut)s_1_%(busname)s_ARREADY),
        .%(busname)s_arsize(%(dut)s_1_%(busname)s_ARSIZE),
        .%(busname)s_arvalid(%(dut)s_1_%(busname)s_ARVALID),
        .%(busname)s_awaddr(%(dut)s_1_%(busname)s_AWADDR),
        .%(busname)s_awburst(%(dut)s_1_%(busname)s_AWBURST),
        .%(busname)s_awcache(%(dut)s_1_%(busname)s_AWCACHE),
        .%(busname)s_awid(%(dut)s_1_%(busname)s_AWID),
        .%(busname)s_awlen(%(dut)s_1_%(busname)s_AWLEN),
        .%(busname)s_awprot(%(dut)s_1_%(busname)s_AWPROT),
        .%(busname)s_awready(%(dut)s_1_%(busname)s_AWREADY),
        .%(busname)s_awsize(%(dut)s_1_%(busname)s_AWSIZE),
        .%(busname)s_awvalid(%(dut)s_1_%(busname)s_AWVALID),
        .%(busname)s_bid(%(dut)s_1_%(busname)s_BID),
        .%(busname)s_bready(%(dut)s_1_%(busname)s_BREADY),
        .%(busname)s_bresp(%(dut)s_1_%(busname)s_BRESP),
        .%(busname)s_bvalid(%(dut)s_1_%(busname)s_BVALID),
        .%(busname)s_rdata(%(dut)s_1_%(busname)s_RDATA),
        .%(busname)s_rid(%(dut)s_1_%(busname)s_RID),
        .%(busname)s_rlast(%(dut)s_1_%(busname)s_RLAST),
        .%(busname)s_rready(%(dut)s_1_%(busname)s_RREADY),
        .%(busname)s_rresp(%(dut)s_1_%(busname)s_RRESP),
        .%(busname)s_rvalid(%(dut)s_1_%(busname)s_RVALID),
        .%(busname)s_wdata(%(dut)s_1_%(busname)s_WDATA),
        .%(busname)s_wid(%(dut)s_1_%(busname)s_WID),
        .%(busname)s_wlast(%(dut)s_1_%(busname)s_WLAST),
        .%(busname)s_wready(%(dut)s_1_%(busname)s_WREADY),
        .%(busname)s_wstrb(%(dut)s_1_%(busname)s_WSTRB),
        .%(busname)s_wvalid(%(dut)s_1_%(busname)s_WVALID),
'''

top_ps7_axi_master_port_map_template='''
        .S_AXI_%(ps7bustype)s%(busnumber)s_ACLK(processing_system7_1_fclk_clk0),
        .S_AXI_%(ps7bustype)s%(busnumber)s_ARADDR(%(dut)s_1_%(busname)s_ARADDR),
        .S_AXI_%(ps7bustype)s%(busnumber)s_ARBURST(%(dut)s_1_%(busname)s_ARBURST),
        .S_AXI_%(ps7bustype)s%(busnumber)s_ARCACHE(%(dut)s_1_%(busname)s_ARCACHE),
        .S_AXI_%(ps7bustype)s%(busnumber)s_ARID(%(dut)s_1_%(busname)s_ARID),
        .S_AXI_%(ps7bustype)s%(busnumber)s_ARLEN(%(dut)s_1_%(busname)s_ARLEN),
        .S_AXI_%(ps7bustype)s%(busnumber)s_ARLOCK({GND_1,GND_1}),
        .S_AXI_%(ps7bustype)s%(busnumber)s_ARPROT(%(dut)s_1_%(busname)s_ARPROT),
        .S_AXI_%(ps7bustype)s%(busnumber)s_ARQOS({GND_1,GND_1,GND_1,GND_1}),
        .S_AXI_%(ps7bustype)s%(busnumber)s_ARREADY(%(dut)s_1_%(busname)s_ARREADY),
        .S_AXI_%(ps7bustype)s%(busnumber)s_ARSIZE(%(dut)s_1_%(busname)s_ARSIZE),
        .S_AXI_%(ps7bustype)s%(busnumber)s_ARVALID(%(dut)s_1_%(busname)s_ARVALID),
        .S_AXI_%(ps7bustype)s%(busnumber)s_AWADDR(%(dut)s_1_%(busname)s_AWADDR),
        .S_AXI_%(ps7bustype)s%(busnumber)s_AWBURST(%(dut)s_1_%(busname)s_AWBURST),
        .S_AXI_%(ps7bustype)s%(busnumber)s_AWCACHE(%(dut)s_1_%(busname)s_AWCACHE),
        .S_AXI_%(ps7bustype)s%(busnumber)s_AWID(%(dut)s_1_%(busname)s_AWID),
        .S_AXI_%(ps7bustype)s%(busnumber)s_AWLEN(%(dut)s_1_%(busname)s_AWLEN),
        .S_AXI_%(ps7bustype)s%(busnumber)s_AWLOCK({GND_1,GND_1}),
        .S_AXI_%(ps7bustype)s%(busnumber)s_AWPROT(%(dut)s_1_%(busname)s_AWPROT),
        .S_AXI_%(ps7bustype)s%(busnumber)s_AWQOS({GND_1,GND_1,GND_1,GND_1}),
        .S_AXI_%(ps7bustype)s%(busnumber)s_AWREADY(%(dut)s_1_%(busname)s_AWREADY),
        .S_AXI_%(ps7bustype)s%(busnumber)s_AWSIZE(%(dut)s_1_%(busname)s_AWSIZE),
        .S_AXI_%(ps7bustype)s%(busnumber)s_AWVALID(%(dut)s_1_%(busname)s_AWVALID),
        .S_AXI_%(ps7bustype)s%(busnumber)s_BID(%(dut)s_1_%(busname)s_BID),
        .S_AXI_%(ps7bustype)s%(busnumber)s_BREADY(%(dut)s_1_%(busname)s_BREADY),
        .S_AXI_%(ps7bustype)s%(busnumber)s_BRESP(%(dut)s_1_%(busname)s_BRESP),
        .S_AXI_%(ps7bustype)s%(busnumber)s_BVALID(%(dut)s_1_%(busname)s_BVALID),
        .S_AXI_%(ps7bustype)s%(busnumber)s_RDATA(%(dut)s_1_%(busname)s_RDATA),
        .S_AXI_%(ps7bustype)s%(busnumber)s_RID(%(dut)s_1_%(busname)s_RID),
        .S_AXI_%(ps7bustype)s%(busnumber)s_RLAST(%(dut)s_1_%(busname)s_RLAST),
        .S_AXI_%(ps7bustype)s%(busnumber)s_RREADY(%(dut)s_1_%(busname)s_RREADY),
        .S_AXI_%(ps7bustype)s%(busnumber)s_RRESP(%(dut)s_1_%(busname)s_RRESP),
        .S_AXI_%(ps7bustype)s%(busnumber)s_RVALID(%(dut)s_1_%(busname)s_RVALID),
        .S_AXI_%(ps7bustype)s%(busnumber)s_WDATA(%(dut)s_1_%(busname)s_WDATA),
        .S_AXI_%(ps7bustype)s%(busnumber)s_WID(%(dut)s_1_%(busname)s_WID),
        .S_AXI_%(ps7bustype)s%(busnumber)s_WLAST(%(dut)s_1_%(busname)s_WLAST),
        .S_AXI_%(ps7bustype)s%(busnumber)s_WREADY(%(dut)s_1_%(busname)s_WREADY),
        .S_AXI_%(ps7bustype)s%(busnumber)s_WSTRB(%(dut)s_1_%(busname)s_WSTRB),
        .S_AXI_%(ps7bustype)s%(busnumber)s_WVALID(%(dut)s_1_%(busname)s_WVALID),
        /* .S_AXI_%(ps7bustype)s%(busnumber)s_RDISSUECAP1_EN(GND_1), */
        /* .S_AXI_%(ps7bustype)s%(busnumber)s_WRISSUECAP1_EN(GND_1), */
'''

verilog_template='''
`uselib lib=unisims_ver
`uselib lib=proc_common_v3_00_a

module %(dut)s
(
%(axi_master_ports)s
%(axi_slave_ports)s
%(hdmi_ports)s

    output interrupt
  );

%(axi_master_parameters)s
%(axi_slave_parameters)s
parameter C_FAMILY = "virtex6";

%(axi_master_port_decls)s
%(axi_slave_port_decls)s

%(axi_master_clocks)s
%(axi_slave_clocks)s
%(hdmi_clocks)s

%(axi_master_signals)s
%(axi_slave_signals)s
%(hdmi_signals)s

mk%(Dut)sWrapper %(Dut)sIMPLEMENTATION (
      %(dut_hdmi_clock_arg)s
      .CLK(CTRL_ACLK),
      .RST_N(CTRL_ARESETN),
      %(axi_master_port_map)s
      %(axi_slave_port_map)s
      %(hdmi_port_map)s

      .interrupt(interrupt)
      );

%(axi_master_scheduler)s
%(axi_slave_scheduler)s

endmodule
'''

axi_master_parameter_verilog_template='''
parameter C_%(BUSNAME)s_DATA_WIDTH = %(datawidth)s;
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
parameter C_%(BUSNAME)s_MEM0_BASEADDR = 32'hFFFFFFFF;
parameter C_%(BUSNAME)s_MEM0_HIGHADDR = 32'h00000000;
'''

axi_master_port_verilog_template='''
//============ %(BUSNAME)s ============
    input %(busname)s_aclk,
    input %(busname)s_aresetn,
    input %(busname)s_arready,
    output %(busname)s_arvalid,
    output [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(busname)s_arid,
    output [C_%(BUSNAME)s_ADDR_WIDTH-1 : 0] %(busname)s_araddr,
    output [C_%(BUSNAME)s_BURSTLEN_WIDTH-1 : 0] %(busname)s_arlen,
    output [2 : 0] %(busname)s_arsize,
    output [1 : 0] %(busname)s_arburst,
    output [(C_%(BUSNAME)s_PROT_WIDTH-1) : 0] %(busname)s_arprot,
    output [(C_%(BUSNAME)s_CACHE_WIDTH-1) : 0] %(busname)s_arcache,
    output %(busname)s_rready,
    input %(busname)s_rvalid,
    input [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(busname)s_rid,
    input [C_%(BUSNAME)s_DATA_WIDTH-1 : 0] %(busname)s_rdata,
    input [1 : 0] %(busname)s_rresp,
    input %(busname)s_rlast,
    input %(busname)s_awready,
    output %(busname)s_awvalid,
    output [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(busname)s_awid,
    output [C_%(BUSNAME)s_ADDR_WIDTH-1 : 0] %(busname)s_awaddr,
    output [C_%(BUSNAME)s_BURSTLEN_WIDTH-1 : 0] %(busname)s_awlen,
    output [2 : 0] %(busname)s_awsize,
    output [1 : 0] %(busname)s_awburst,
    output [(C_%(BUSNAME)s_PROT_WIDTH-1) : 0] %(busname)s_awprot,
    output [(C_%(BUSNAME)s_CACHE_WIDTH-1) : 0] %(busname)s_awcache,
    input %(busname)s_wready,
    output %(busname)s_wvalid,
    output [C_%(BUSNAME)s_ID_WIDTH - 1 : 0] %(busname)s_wid,
    output [C_%(BUSNAME)s_DATA_WIDTH - 1 : 0] %(busname)s_wdata,
    output [(C_%(BUSNAME)s_DATA_WIDTH)/8 - 1 : 0] %(busname)s_wstrb,
    output %(busname)s_wlast,
    output %(busname)s_bready,
    input [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(busname)s_bid,
    input %(busname)s_bvalid,
    input [1 : 0] %(busname)s_bresp,
//============ %(BUSNAME)s ============
'''

axi_slave_port_verilog_template='''
//============ %(BUSNAME)s ============
    input %(BUSNAME)s_ACLK,
    input %(BUSNAME)s_ARESETN,
    input [C_%(BUSNAME)s_ADDR_WIDTH-1 : 0] %(BUSNAME)s_AWADDR,
    input %(BUSNAME)s_AWVALID,
    input [C_%(BUSNAME)s_DATA_WIDTH-1 : 0] %(BUSNAME)s_WDATA,
    input [(C_%(BUSNAME)s_DATA_WIDTH/8)-1 : 0] %(BUSNAME)s_WSTRB,
    input %(BUSNAME)s_WVALID,
    input %(BUSNAME)s_BREADY,
    input [C_%(BUSNAME)s_ADDR_WIDTH-1 : 0] %(BUSNAME)s_ARADDR,
    input %(BUSNAME)s_ARVALID,
    input %(BUSNAME)s_RREADY,
    output %(BUSNAME)s_ARREADY,
    output [C_%(BUSNAME)s_DATA_WIDTH-1 : 0] %(BUSNAME)s_RDATA,
    output [1 : 0] %(BUSNAME)s_RRESP,
    output %(BUSNAME)s_RVALID,
    output %(BUSNAME)s_WREADY,
    output [1 : 0] %(BUSNAME)s_BRESP,
    output %(BUSNAME)s_BVALID,
    output %(BUSNAME)s_AWREADY,
    input [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(BUSNAME)s_AWID,
    input [3 : 0] %(BUSNAME)s_AWLEN,
    input [2 : 0] %(BUSNAME)s_AWSIZE,
    input [1 : 0] %(BUSNAME)s_AWBURST,
    input %(BUSNAME)s_AWLOCK,
    input [1 : 0] %(BUSNAME)s_AWCACHE,
    input [1 : 0] %(BUSNAME)s_AWPROT,
    input %(BUSNAME)s_WLAST,
    output [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(BUSNAME)s_BID,
    input [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(BUSNAME)s_ARID,
    input [3 : 0] %(BUSNAME)s_ARLEN,
    input [2 : 0] %(BUSNAME)s_ARSIZE,
    input [1 : 0] %(BUSNAME)s_ARBURST,
    input %(BUSNAME)s_ARLOCK,
    input [2 : 0] %(BUSNAME)s_ARCACHE,
    input [1 : 0] %(BUSNAME)s_ARPROT,
    output [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(BUSNAME)s_RID,
    output %(BUSNAME)s_RLAST,
//============ %(BUSNAME)s ============
'''

top_hdmi_port_verilog_template='''
    output hdmi_clk,
    output hdmi_vsync,
    output hdmi_hsync,
    output hdmi_de,
    output [15:0] hdmi_data,
    inout i2c1_scl,
    inout i2c1_sda,
'''

hdmi_port_verilog_template='''
    input hdmi_clk_in,
    output hdmi_vsync,
    output hdmi_hsync,
    output hdmi_de,
    output [15:0] hdmi_data,
'''


axi_master_port_decl_verilog_template='''
//============ %(BUSNAME)s ============
wire [C_%(BUSNAME)s_DATA_WIDTH - 1 : 0] %(busname)s_wdata_wire;
//============ %(BUSNAME)s ============
'''

axi_slave_port_decl_verilog_template='''
//============ %(BUSNAME)s ============
wire %(BUSNAME)s_ARREADY_unbuf;
wire %(BUSNAME)s_RVALID_unbuf;
//============ %(BUSNAME)s ============
'''

top_dut_hdmi_port_map = '''
       .hdmi_clk_in(processing_system7_1_fclk_clk1),
       .hdmi_vsync(hdmi_vsync),
       .hdmi_hsync(hdmi_hsync),
       .hdmi_de(hdmi_de),
       .hdmi_data(hdmi_data),
'''

top_ps7_hdmi_port_map = '''
       .I2C1_SCL_I(i2c1_scl_i),
       .I2C1_SCL_O(i2c1_scl_o),
       .I2C1_SCL_T(i2c1_scl_t),
       .I2C1_SDA_I(i2c1_sda_i),
       .I2C1_SDA_O(i2c1_sda_o),
       .I2C1_SDA_T(i2c1_sda_t),
'''

axi_clock_verilog_template='''
  // attribute MAX_FANOUT of %(BUSNAME)s_ACLK       : signal is "10000";
  // attribute MAX_FANOUT of %(BUSNAME)s_ARESETN       : signal is "10000";
  // attribute SIGIS of %(BUSNAME)s_ACLK       : signal is "Clk";
  // attribute SIGIS of %(BUSNAME)s_ARESETN       : signal is "Rst";
'''

hdmi_clock_verilog_template='''
  // attribute SIGIS of hdmi_clk : signal is "Clk";
'''

axi_master_port_map_verilog_template='''
      .EN_%(busname)s_write_writeAddr(WILL_FIRE_%(busname)s_write_writeAddr),
      .%(busname)s_write_writeAddr(%(busname)s_awaddr),
      .%(busname)s_write_writeId(%(busname)s_awid),
      .RDY_%(busname)s_write_writeAddr(RDY_%(busname)s_write_writeAddr),

      .%(busname)s_write_writeBurstLen(%(busname)s_awlen),
      // RDY_%(busname)s_write_writeBurstLen,

      .%(busname)s_write_writeBurstWidth(%(busname)s_awsize),
      // RDY_%(busname)s_write_writeBurstWidth,

      .%(busname)s_write_writeBurstType(%(busname)s_awburst),
      // RDY_%(busname)s_write_writeBurstType,

      .%(busname)s_write_writeBurstProt(%(busname)s_awprot),
      // RDY_%(busname)s_write_writeBurstProt,

      .%(busname)s_write_writeBurstCache(%(busname)s_awcache),
      // RDY_%(busname)s_write_writeBurstCache,

      .EN_%(busname)s_write_writeData(WILL_FIRE_%(busname)s_write_writeData),
      .%(busname)s_write_writeData(%(busname)s_wdata_wire),
      .RDY_%(busname)s_write_writeData(RDY_%(busname)s_write_writeData),

      .%(busname)s_write_writeWid(%(busname)s_wid),

      .%(busname)s_write_writeDataByteEnable(%(busname)s_wstrb),
      // RDY_%(busname)s_write_writeDataByteEnable,

      .%(busname)s_write_writeLastDataBeat(%(busname)s_wlast),
      // RDY_%(busname)s_write_writeLastDataBeat,

      .EN_%(busname)s_write_writeResponse(WILL_FIRE_%(busname)s_write_writeResponse),
      .%(busname)s_write_writeResponse_responseCode(%(busname)s_bresp),
      .%(busname)s_write_writeResponse_id(%(busname)s_bid),
      .RDY_%(busname)s_write_writeResponse(RDY_%(busname)s_write_writeResponse),

      .EN_%(busname)s_read_readAddr(WILL_FIRE_%(busname)s_read_readAddr),
      .%(busname)s_read_readId(%(busname)s_arid),
      .%(busname)s_read_readAddr(%(busname)s_araddr),
      .RDY_%(busname)s_read_readAddr(RDY_%(busname)s_read_readAddr),

      .%(busname)s_read_readBurstLen(%(busname)s_arlen),
      // RDY_%(busname)s_read_readBurstLen,

      .%(busname)s_read_readBurstWidth(%(busname)s_arsize),
      // RDY_%(busname)s_read_readBurstWidth,

      .%(busname)s_read_readBurstType(%(busname)s_arburst),
      // RDY_%(busname)s_read_readBurstType,

      .%(busname)s_read_readBurstProt(%(busname)s_arprot),
      // RDY_%(busname)s_read_readBurstProt,

      .%(busname)s_read_readBurstCache(%(busname)s_arcache),
      // RDY_%(busname)s_read_readBurstCache,

      .%(busname)s_read_readData_data(%(busname)s_rdata),
      .%(busname)s_read_readData_resp(%(busname)s_rresp),
      .%(busname)s_read_readData_last(%(busname)s_rlast),
      .%(busname)s_read_readData_id(%(busname)s_rid),
      .EN_%(busname)s_read_readData(WILL_FIRE_%(busname)s_read_readData),
      .RDY_%(busname)s_read_readData(RDY_%(busname)s_read_readData),
'''

axi_slave_port_map_verilog_template='''
      .%(busname)s_read_readAddr_addr(%(BUSNAME)s_ARADDR),
      .%(busname)s_read_readAddr_burstLen(%(BUSNAME)s_ARLEN),
      .%(busname)s_read_readAddr_burstWidth(%(BUSNAME)s_ARSIZE),
      .%(busname)s_read_readAddr_burstType(%(BUSNAME)s_ARBURST),
      .%(busname)s_read_readAddr_burstProt(%(BUSNAME)s_ARPROT),
      .%(busname)s_read_readAddr_burstCache(%(BUSNAME)s_ARCACHE),
      .%(busname)s_read_readAddr_arid(%(BUSNAME)s_ARID),
      .EN_%(busname)s_read_readAddr(EN_%(busname)s_read_readAddr),
      .RDY_%(busname)s_read_readAddr(RDY_%(busname)s_read_readAddr),

      .%(busname)s_read_last(%(busname)s_read_last),
      .%(busname)s_read_rid(%(BUSNAME)s_RID),
      .EN_%(busname)s_read_readData(EN_%(busname)s_read_readData),
      .%(busname)s_read_readData(%(busname)s_read_readData),
      .RDY_%(busname)s_read_readData(RDY_%(busname)s_read_readData),

      .%(busname)s_write_writeAddr_addr(%(BUSNAME)s_AWADDR),
      .%(busname)s_write_writeAddr_burstLen(%(BUSNAME)s_AWLEN),
      .%(busname)s_write_writeAddr_burstWidth(%(BUSNAME)s_AWSIZE),
      .%(busname)s_write_writeAddr_burstType(%(BUSNAME)s_AWBURST),
      .%(busname)s_write_writeAddr_burstProt(%(BUSNAME)s_AWPROT),
      .%(busname)s_write_writeAddr_burstCache(%(BUSNAME)s_AWCACHE),
      .%(busname)s_write_writeAddr_awid(%(BUSNAME)s_AWID),
      .EN_%(busname)s_write_writeAddr(EN_%(busname)s_write_writeAddr),
      .RDY_%(busname)s_write_writeAddr(RDY_%(busname)s_write_writeAddr),

      .%(busname)s_write_writeData_data(%(BUSNAME)s_WDATA),
      .%(busname)s_write_writeData_byteEnable(%(BUSNAME)s_WSTRB),
      .%(busname)s_write_writeData_last(%(BUSNAME)s_WLAST),
      .EN_%(busname)s_write_writeData(EN_%(busname)s_write_writeData),
      .RDY_%(busname)s_write_writeData(RDY_%(busname)s_write_writeData),

      .EN_%(busname)s_write_writeResponse(EN_%(busname)s_write_writeResponse),
      .RDY_%(busname)s_write_writeResponse(RDY_%(busname)s_write_writeResponse),
      .%(busname)s_write_writeResponse(%(busname)s_write_writeResponse),
      .EN_%(busname)s_write_bid(EN_%(busname)s_write_writeResponse),
      .RDY_%(busname)s_write_bid(RDY_%(busname)s_write_bid),
      .%(busname)s_write_bid(%(BUSNAME)s_BID),
'''

hdmi_port_map_verilog_template='''
      .%(busname)s_hdmi_vsync(hdmi_vsync),
      .%(busname)s_hdmi_hsync(hdmi_hsync),
      .%(busname)s_hdmi_de(hdmi_de),
      .%(busname)s_hdmi_data(hdmi_data),
'''

axi_master_signal_verilog_template='''
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

axi_slave_signal_verilog_template='''
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
  wire %(busname)s_read_last;
'''

hdmi_signal_verilog_template='''
  //attribute MAX_FANOUT of hdmi_clk_in : signal is "10000";
  //attribute SIGIS of hdmi_clk_in      : signal is "CLK";
  wire %(busname)s_vsync_unbuf, %(busname)s_hsync_unbuf, %(busname)s_de_unbuf;
  wire [15 : 0] %(busname)s_data_unbuf;
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
assign %(busname)s_mem0_araddr_matches = (%(BUSNAME)s_ARADDR >= C_%(BUSNAME)s_MEM0_BASEADDR & %(BUSNAME)s_ARADDR <= C_%(BUSNAME)s_MEM0_HIGHADDR);
assign %(busname)s_mem0_awaddr_matches = (%(BUSNAME)s_AWADDR >= C_%(BUSNAME)s_MEM0_BASEADDR & %(BUSNAME)s_AWADDR <= C_%(BUSNAME)s_MEM0_HIGHADDR);

assign %(BUSNAME)s_ARREADY_unbuf = RDY_%(busname)s_read_readAddr & %(BUSNAME)s_ARVALID & %(busname)s_mem0_araddr_matches;
assign %(BUSNAME)s_ARREADY = %(BUSNAME)s_ARREADY_unbuf;
assign %(BUSNAME)s_RVALID_unbuf = EN_%(busname)s_read_readData;
assign %(BUSNAME)s_RVALID = %(BUSNAME)s_RVALID_unbuf;
assign %(BUSNAME)s_RRESP[1:0]  = "00";

assign %(BUSNAME)s_RDATA  = %(busname)s_read_readData;
assign %(BUSNAME)s_RLAST  = %(busname)s_read_last;


assign %(BUSNAME)s_AWREADY  = RDY_%(busname)s_write_writeAddr & %(busname)s_mem0_awaddr_matches;
assign %(BUSNAME)s_WREADY = RDY_%(busname)s_write_writeData;
assign %(BUSNAME)s_BVALID  = EN_%(busname)s_write_writeResponse;
assign %(BUSNAME)s_BRESP = %(busname)s_write_writeResponse;

assign EN_%(busname)s_read_readAddr = RDY_%(busname)s_read_readAddr & %(BUSNAME)s_ARVALID & %(busname)s_mem0_araddr_matches;
assign EN_%(busname)s_read_readData = RDY_%(busname)s_read_readData & %(BUSNAME)s_RREADY;

assign EN_%(busname)s_write_writeAddr = RDY_%(busname)s_write_writeAddr & %(BUSNAME)s_AWVALID & %(busname)s_mem0_awaddr_matches;
assign EN_%(busname)s_write_writeData = RDY_%(busname)s_write_writeData & %(BUSNAME)s_WVALID;
assign EN_%(busname)s_write_writeResponse = RDY_%(busname)s_write_writeResponse & %(BUSNAME)s_BREADY;
'''

hdmi_iobuf_verilog_template='''
    assign hdmi_clk = processing_system7_1_fclk_clk1;

    IOBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) IOBUF_i2c1_scl
    (
    .IO(i2c1_scl),
    // Buffer output (connect directly to top-level port)
    .O(i2c1_scl_i),
    .I(i2c1_scl_o),
    .T(i2c1_scl_t)
    // Buffer input
    );
    IOBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) IOBUF_i2c1_sda
    (
    .IO(i2c1_sda),
    // Buffer output (connect directly to top-level port)
    .O(i2c1_sda_i),
    .I(i2c1_sda_o),
    .T(i2c1_sda_t)
    // Buffer input
    );

'''

class InterfaceMixin:
    def axiMasterBusSubst(self, busnumber, businfo):
        (busname,t,params) = businfo
        buswidth = params[0].numeric()
        buswidthbytes = buswidth / 8
        print 'bustype: ', t, ('AXI4' if (t == 'AxiMaster') else 'AXI3'), buswidth
        dutName = util.decapitalize(self.name)
        if buswidth == 32:
            ps7bustype = 'GP'
        else:
            ps7bustype = 'HP'
        return {
            'dut': dutName,
            'BUSNAME': busname.upper(),
            'busname': busname,
            'busnumber': busnumber,
            'buswidth': buswidth,
            'buswidthbytes': buswidthbytes,
            'ps7bustype': ps7bustype,
            'datawidth': params[0].numeric(),
            'burstlenwidth': 8 if (t == 'AxiMaster') else 4,
            'protwidth': 3 if (t == 'AxiMaster') else 2,
            'cachewidth': 4 if (t == 'AxiMaster') else 3,
            'axiprotocol': 'AXI4' if (t == 'AxiMaster') else 'AXI3',
            }
    def writeTopVerilog(self, topverilogname, silent=False):
        if not silent:
            print 'Writing top Verilog file', topverilogname
        topverilog = util.createDirAndOpen(topverilogname, 'w')
        dutName = util.decapitalize(self.name)
        axiMasters = self.collectInterfaceNames('Axi3?Client')
        axiSlaves = [('ctrl','AxiSlave',[])] + self.collectInterfaceNames('AxiSlave')
        hdmiBus = self.collectInterfaceNames('HDMI')
        masterBusSubsts = [self.axiMasterBusSubst(busnumber,axiMasters[busnumber]) for busnumber in range(len(axiMasters))]
        substs = {
            'dut': dutName.lower(),
            'Dut': util.capitalize(self.name),
            'top_axi_master_wires': ''.join([top_axi_master_wires_template % subst for subst in masterBusSubsts]),
            'top_dut_axi_master_port_map': ''.join([top_dut_axi_master_port_map_template % subst for subst in masterBusSubsts]),
            'top_ps7_axi_master_port_map': ''.join([top_ps7_axi_master_port_map_template % subst for subst in masterBusSubsts]),
            'top_hdmi_ports':
                ''.join([top_hdmi_port_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in hdmiBus]),
            'top_dut_hdmi_port_map': 
                ''.join([top_dut_hdmi_port_map
                         for (busname,t,params) in hdmiBus]),
            'top_ps7_hdmi_port_map':
                ''.join([top_ps7_hdmi_port_map
                         for (busname,t,params) in hdmiBus]),
            'hdmi_iobufs':
                ''.join([hdmi_iobuf_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in hdmiBus]),
            }
        topverilog.write(top_verilog_template % substs)
        topverilog.close()
        return

    def writeVerilog(self, verilogname, silent=False):
        if not silent:
            print 'Writing wrapper Verilog file', verilogname
        verilog = util.createDirAndOpen(verilogname, 'w')
        dutName = util.decapitalize(self.name)
        axiMasters = self.collectInterfaceNames('Axi3?Client')
        axiSlaves = [('ctrl','AxiSlave',[])] + self.collectInterfaceNames('AxiSlave')
        hdmiBus = self.collectInterfaceNames('HDMI')
        masterBusSubsts = [self.axiMasterBusSubst(busnumber,axiMasters[busnumber]) for busnumber in range(len(axiMasters))]
        substs = {
            'dut': dutName.lower(),
            'Dut': util.capitalize(self.name),
            'axi_master_parameters':
                ''.join([axi_master_parameter_verilog_template % subst for subst in masterBusSubsts]),
            'axi_slave_parameters':
                ''.join([axi_slave_parameter_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            'axi_master_ports':
                ''.join([axi_master_port_verilog_template % subst for subst in masterBusSubsts]),
            'axi_master_port_decls':
                ''.join([axi_master_port_decl_verilog_template % subst for subst in masterBusSubsts]),
            'axi_slave_ports':
                ''.join([axi_slave_port_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            'axi_slave_port_decls':
                ''.join([axi_slave_port_decl_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            'hdmi_ports':
                ''.join([hdmi_port_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in hdmiBus]),
            'dut_hdmi_clock_arg': '      .CLK_hdmi_clk(hdmi_clk_in),' if len(hdmiBus) else '',
            'axi_master_port_map':
                ''.join([axi_master_port_map_verilog_template % subst for subst in masterBusSubsts]),
            'axi_slave_port_map':
                ''.join([axi_slave_port_map_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            'hdmi_port_map':
                ''.join([hdmi_port_map_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in hdmiBus]),
            'axi_master_clocks':
                ''.join([axi_clock_verilog_template % subst for subst in masterBusSubsts]),
            'axi_slave_clocks':
                ''.join([axi_clock_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            'hdmi_clocks':
                ''.join([hdmi_clock_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in hdmiBus]),
            'iobufs': '',
            'axi_master_signals':
                ''.join([axi_master_signal_verilog_template % subst for subst in masterBusSubsts]),
            'axi_slave_signals':
                ''.join([axi_slave_signal_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            'hdmi_signals':
                ''.join([hdmi_signal_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in hdmiBus]),
            'axi_master_scheduler':
                ''.join([axi_master_scheduler_verilog_template % subst for subst in masterBusSubsts ]),
            'axi_slave_scheduler':
                ''.join([axi_slave_scheduler_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            }
        verilog.write(verilog_template % substs)
        verilog.close()
        return

    def writeUcf(self, ucfname, boardname='zc702', silent=False):
        if not silent:
            print 'Writing UCF file', ucfname
        ucf = util.createDirAndOpen(ucfname, 'w')
        dutName = util.decapitalize(self.name)
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
        dutName = util.decapitalize(self.name)
        hdmiBus = self.collectInterfaceNames('HDMI')
        if len(hdmiBus):
            hdmi_pins = hdmi_pinout[boardname]
            for (name, pin, iostandard, direction) in hdmi_pins:
                xdc.write(xdc_template % { 'name': name, 'pin': pin, 'iostandard': iostandard, 'direction': direction })
            #xdc.write(xadc_xdc_template[boardname])
        for (name, pin, iostandard, direction) in led_pinout[boardname]:
            xdc.write(xdc_template % { 'name': name, 'pin': pin, 'iostandard': iostandard, 'direction': direction })
        #xdc.write(default_clk_xdc_template)
        xdc.close()
        return
