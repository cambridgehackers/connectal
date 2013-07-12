
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

xmp_template='''
#Please do not modify this file by hand
XmpVersion: %(edkversion)s
VerMgmt: %(edkversion)s
IntStyle: default
Flow: ise
MHS File: %(dut)s.mhs
Architecture: zynq
Device: xc7z020
Package: clg484
SpeedGrade: -1
UserCmd1: 
UserCmd1Type: 0
UserCmd2: 
UserCmd2Type: 0
GenSimTB: 0
SdkExportBmmBit: 1
SdkExportDir: SDK/SDK_Export
InsertNoPads: 1
WarnForEAArch: 1
HdlLang: verilog
SimModel: STRUCTURAL
ExternalMemSim: 0
UcfFile: data/%(dut)s.ucf
EnableParTimingError: 0
ShowLicenseDialog: 1
BInfo: 
Processor: processing_system7_0
ElfImp: 
ElfSim: 
'''

mhs_template='''
# ##############################################################################
# Created by xstgen
# Target Board:  xilinx.com zc702 Rev C
# Family:    zynq
# Device:    xc7z020
# Package:   clg484
# Speed Grade:  -1
# ##############################################################################
 PARAMETER VERSION = 2.1.0


 PORT processing_system7_0_MIO = processing_system7_0_MIO, DIR = IO, VEC = [53:0]
 PORT processing_system7_0_PS_SRSTB = processing_system7_0_PS_SRSTB, DIR = I
 PORT processing_system7_0_PS_CLK = processing_system7_0_PS_CLK, DIR = I, SIGIS = CLK
 PORT processing_system7_0_PS_PORB = processing_system7_0_PS_PORB, DIR = I
 PORT processing_system7_0_DDR_Clk = processing_system7_0_DDR_Clk, DIR = IO, SIGIS = CLK
 PORT processing_system7_0_DDR_Clk_n = processing_system7_0_DDR_Clk_n, DIR = IO, SIGIS = CLK
 PORT processing_system7_0_DDR_CKE = processing_system7_0_DDR_CKE, DIR = IO
 PORT processing_system7_0_DDR_CS_n = processing_system7_0_DDR_CS_n, DIR = IO
 PORT processing_system7_0_DDR_RAS_n = processing_system7_0_DDR_RAS_n, DIR = IO
 PORT processing_system7_0_DDR_CAS_n = processing_system7_0_DDR_CAS_n, DIR = IO
 PORT processing_system7_0_DDR_WEB_pin = processing_system7_0_DDR_WEB, DIR = O
 PORT processing_system7_0_DDR_BankAddr = processing_system7_0_DDR_BankAddr, DIR = IO, VEC = [2:0]
 PORT processing_system7_0_DDR_Addr = processing_system7_0_DDR_Addr, DIR = IO, VEC = [14:0]
 PORT processing_system7_0_DDR_ODT = processing_system7_0_DDR_ODT, DIR = IO
 PORT processing_system7_0_DDR_DRSTB = processing_system7_0_DDR_DRSTB, DIR = IO, SIGIS = RST
 PORT processing_system7_0_DDR_DQ = processing_system7_0_DDR_DQ, DIR = IO, VEC = [31:0]
 PORT processing_system7_0_DDR_DM = processing_system7_0_DDR_DM, DIR = IO, VEC = [3:0]
 PORT processing_system7_0_DDR_DQS = processing_system7_0_DDR_DQS, DIR = IO, VEC = [3:0]
 PORT processing_system7_0_DDR_DQS_n = processing_system7_0_DDR_DQS_n, DIR = IO, VEC = [3:0]
 PORT processing_system7_0_DDR_VRN = processing_system7_0_DDR_VRN, DIR = IO
 PORT processing_system7_0_DDR_VRP = processing_system7_0_DDR_VRP, DIR = IO
 PORT xadc_gpio_0_pin = %(dut)s_0_xadc_gpio_0, DIR = O
 PORT xadc_gpio_1_pin = %(dut)s_0_xadc_gpio_1, DIR = O
 PORT xadc_gpio_2_pin = %(dut)s_0_xadc_gpio_2, DIR = O
 PORT xadc_gpio_3_pin = %(dut)s_0_xadc_gpio_3, DIR = O
%(system_hdmi_ports)s

BEGIN qqprocessing_system7
 PARAMETER INSTANCE = processing_system7_0
 PARAMETER HW_VER = 4.02.a
 PARAMETER C_DDR_RAM_HIGHADDR = 0x3FFFFFFF
 PARAMETER C_USE_M_AXI_GP0 = 1
 PARAMETER C_EN_EMIO_CAN0 = 0
 PARAMETER C_EN_EMIO_CAN1 = 0
 PARAMETER C_EN_EMIO_ENET0 = 0
 PARAMETER C_EN_EMIO_ENET1 = 0
 PARAMETER C_EN_EMIO_I2C0 = 0
 PARAMETER C_EN_EMIO_PJTAG = 0
 PARAMETER C_EN_EMIO_SDIO0 = 0
 PARAMETER C_EN_EMIO_CD_SDIO0 = 0
 PARAMETER C_EN_EMIO_WP_SDIO0 = 0
 PARAMETER C_EN_EMIO_SDIO1 = 0
 PARAMETER C_EN_EMIO_CD_SDIO1 = 0
 PARAMETER C_EN_EMIO_WP_SDIO1 = 0
 PARAMETER C_EN_EMIO_SPI0 = 0
 PARAMETER C_EN_EMIO_SPI1 = 0
 PARAMETER C_EN_EMIO_SRAM_INT = 0
 PARAMETER C_EN_EMIO_TRACE = 0
 PARAMETER C_EN_EMIO_TTC0 = 0
 PARAMETER C_EN_EMIO_TTC1 = 0
 PARAMETER C_EN_EMIO_UART0 = 0
 PARAMETER C_EN_EMIO_UART1 = 0
 PARAMETER C_EN_EMIO_MODEM_UART0 = 0
 PARAMETER C_EN_EMIO_MODEM_UART1 = 0
 PARAMETER C_EN_EMIO_WDT = 0
 PARAMETER C_EN_QSPI = 0
 PARAMETER C_EN_SMC = 0
 PARAMETER C_EN_CAN0 = 0
 PARAMETER C_EN_CAN1 = 0
 PARAMETER C_EN_ENET0 = 0
 PARAMETER C_EN_ENET1 = 0
 PARAMETER C_EN_I2C0 = 0
 PARAMETER C_EN_PJTAG = 0
 PARAMETER C_EN_SDIO0 = 0
 PARAMETER C_EN_SDIO1 = 0
 PARAMETER C_EN_SPI0 = 0
 PARAMETER C_EN_SPI1 = 0
 PARAMETER C_EN_TRACE = 0
 PARAMETER C_EN_TTC0 = 0
 PARAMETER C_EN_TTC1 = 0
 PARAMETER C_EN_UART0 = 0
 PARAMETER C_EN_UART1 = 0
 PARAMETER C_EN_MODEM_UART0 = 0
 PARAMETER C_EN_MODEM_UART1 = 0
 PARAMETER C_EN_USB0 = 0
 PARAMETER C_EN_USB1 = 0
 PARAMETER C_EN_WDT = 0
 PARAMETER C_EN_DDR = 1
 PARAMETER C_EN_GPIO = 0
 PARAMETER C_FCLK_CLK0_FREQ = 50000000
 PARAMETER C_FCLK_CLK1_FREQ = 50000000
 PARAMETER C_FCLK_CLK2_FREQ = 50000000
 PARAMETER C_FCLK_CLK3_FREQ = 50000000
 PARAMETER C_USE_CR_FABRIC = 1
 PARAMETER C_USE_M_AXI_GP1 = 0
 PARAMETER C_USE_S_AXI_ACP = 0
 PARAMETER C_EMIO_GPIO_WIDTH = 64
 PARAMETER C_EN_EMIO_GPIO = 0
 PORT MIO = processing_system7_0_MIO
 PORT PS_SRSTB = processing_system7_0_PS_SRSTB
 PORT PS_CLK = processing_system7_0_PS_CLK
 PORT PS_PORB = processing_system7_0_PS_PORB
 PORT DDR_Clk = processing_system7_0_DDR_Clk
 PORT DDR_Clk_n = processing_system7_0_DDR_Clk_n
 PORT DDR_CKE = processing_system7_0_DDR_CKE
 PORT DDR_CS_n = processing_system7_0_DDR_CS_n
 PORT DDR_RAS_n = processing_system7_0_DDR_RAS_n
 PORT DDR_CAS_n = processing_system7_0_DDR_CAS_n
 PORT DDR_WEB = processing_system7_0_DDR_WEB
 PORT DDR_BankAddr = processing_system7_0_DDR_BankAddr
 PORT DDR_Addr = processing_system7_0_DDR_Addr
 PORT DDR_ODT = processing_system7_0_DDR_ODT
 PORT DDR_DRSTB = processing_system7_0_DDR_DRSTB
 PORT DDR_DQ = processing_system7_0_DDR_DQ
 PORT DDR_DM = processing_system7_0_DDR_DM
 PORT DDR_DQS = processing_system7_0_DDR_DQS
 PORT DDR_DQS_n = processing_system7_0_DDR_DQS_n
 PORT DDR_VRN = processing_system7_0_DDR_VRN
 PORT DDR_VRP = processing_system7_0_DDR_VRP
 PORT FCLK_CLK0 = processing_system7_0_FCLK_CLK0_0
 PORT FCLK_CLK1 = processing_system7_0_FCLK_CLK1_0
 PORT M_AXI_GP0_ACLK = processing_system7_0_FCLK_CLK0_0
 PORT M_AXI_GP0_ARESETN = processing_system7_0_M_AXI_GP0_ARESETN
 PARAMETER C_S_AXI_GP0_ID_WIDTH = 6
 BUS_INTERFACE M_AXI_GP0 = axi_slave_interconnect_0
%(ps7_hdmi_config)s
%(ps7_axi_master_config)s

 PORT IRQ_F2P = %(dut)s_0_interrupt
END

%(axi_master_interconnects)s
%(axi_slave_interconnects)s

BEGIN %(dut)s
 PARAMETER INSTANCE = %(dut)s_0
 PARAMETER HW_VER = 1.00.a
 PORT interrupt = %(dut)s_0_interrupt
%(dut_axi_master_config)s
%(dut_axi_slave_config)s
%(dut_hdmi_config)s
 PORT xadc_gpio_0 = %(dut)s_0_xadc_gpio_0
 PORT xadc_gpio_1 = %(dut)s_0_xadc_gpio_1
 PORT xadc_gpio_2 = %(dut)s_0_xadc_gpio_2
 PORT xadc_gpio_3 = %(dut)s_0_xadc_gpio_3
END

BEGIN chipscope_axi_monitor
 PARAMETER INSTANCE = chipscope_axi_monitor_0
 PARAMETER HW_VER = 3.05.a
 PARAMETER C_USE_INTERFACE = 2
 BUS_INTERFACE MON_AXI = %(dut)s_0.CTRL
 PORT CHIPSCOPE_ICON_CONTROL = chipscope_icon_0_control0
 PORT RESET = net_gnd
 PORT MON_AXI_ACLK = processing_system7_0_FCLK_CLK0_0
END

BEGIN chipscope_icon
 PARAMETER INSTANCE = chipscope_icon_0
 PARAMETER HW_VER = 1.06.a
 PARAMETER C_NUM_CONTROL_PORTS = %(chipscopecount)s
 PORT control0 = chipscope_icon_0_control0
%(chipscopecontrols)s
END
'''

system_hdmi_port_mhs_template='''
 PORT hdmi_vsync_pin = %(dut)s_0_hdmi_vsync, DIR = O
 PORT hdmi_hsync_pin = %(dut)s_0_hdmi_hsync, DIR = O
 PORT hdmi_de_pin = %(dut)s_0_hdmi_de, DIR = O
 PORT hdmi_data_pin = %(dut)s_0_hdmi_data, DIR = O, VEC = [15:0]
 PORT hdmi_clk_pin = %(dut)s_0_hdmi_clk, DIR = O, SIGIS = CLK
 PORT hdmidisplay_0_i2c_scl_pin = processing_system7_0_I2C1_SCL, DIR = IO
 PORT hdmidisplay_0_i2c_sda_pin = processing_system7_0_I2C1_SDA, DIR = IO
'''

ps7_axi_master_config_mhs_template='''
 ##PARAMETER C_INTERCONNECT_S_AXI_HP%(busnumber)s_MASTERS = %(dut)s_0.%(BUSNAME)s
 PARAMETER C_USE_S_AXI_HP%(busnumber)s = 1
 PARAMETER C_S_AXI_HP%(busnumber)s_ID_WIDTH = 6
 BUS_INTERFACE S_AXI_HP%(busnumber)s = axi_master_interconnect_%(busnumber)s
 PORT S_AXI_HP%(busnumber)s_ACLK = processing_system7_0_FCLK_CLK0_0
 PORT S_AXI_HP%(busnumber)s_ARESETN = processing_system7_0_S_AXI_HP%(busnumber)s_ARESETN
'''

dut_axi_master_config_mhs_template='''
 BUS_INTERFACE %(busname)s = axi_master_interconnect_%(busnumber)s
 PORT %(busname)s_aclk = processing_system7_0_FCLK_CLK0_0
 PORT %(busname)s_aresetn = processing_system7_0_S_AXI_HP%(busnumber)s_ARESETN
'''

dut_axi_slave_config_mhs_template='''
 PARAMETER C_%(BUSNAME)s_MEM0_BASEADDR = %(busbase)s
 PARAMETER C_%(BUSNAME)s_MEM0_HIGHADDR = %(bushigh)s
 PARAMETER C_%(BUSNAME)s_ID_WIDTH = 6
 ## not needed for shared mode
 ##PARAMETER C_INTERCONNECT_%(BUSNAME)s_MASTERS = processing_system7_0.M_AXI_GP0
 BUS_INTERFACE %(BUSNAME)s = axi_slave_interconnect_%(busnumber)s
 PORT %(BUSNAME)s_ACLK = processing_system7_0_FCLK_CLK0_0
 PORT %(BUSNAME)s_ARESETN = processing_system7_0_M_AXI_GP%(busnumber)s_ARESETN
'''

dut_hdmi_config_mhs_template='''
 PORT hdmi_clk_in = processing_system7_0_FCLK_CLK1_0 
 PORT hdmi_clk = %(dut)s_0_hdmi_clk
 PORT hdmi_vsync = %(dut)s_0_hdmi_vsync
 PORT hdmi_hsync = %(dut)s_0_hdmi_hsync
 PORT hdmi_de = %(dut)s_0_hdmi_de
 PORT hdmi_data = %(dut)s_0_hdmi_data
'''

axi_master_interconnect_mhs_template='''
BEGIN axi_passthrough
 PARAMETER INSTANCE = axi_master_interconnect_%(busnumber)s
 PARAMETER HW_VER = 1.06.a
 #PARAMETER C_INTERCONNECT_CONNECTIVITY_MODE = 1
 #PORT INTERCONNECT_ACLK = processing_system7_0_FCLK_CLK0_0
 #PORT INTERCONNECT_ARESETN = processing_system7_0_S_AXI_HP%(busnumber)s_ARESETN
END

BEGIN chipscope_axi_monitor
 PARAMETER INSTANCE = chipscope_axi_monitor_%(chipscopenumber)s
 PARAMETER HW_VER = 3.05.a
 PARAMETER C_USE_INTERFACE = 2
 BUS_INTERFACE MON_AXI = %(dut)s_0.%(BUSNAME)s
 PORT CHIPSCOPE_ICON_CONTROL = chipscope_icon_0_control%(chipscopenumber)s
 PORT RESET = net_gnd
 PORT MON_AXI_ACLK = processing_system7_0_FCLK_CLK0_0
END
'''

axi_slave_interconnect_mhs_template='''
BEGIN axi_passthrough
 PARAMETER INSTANCE = axi_slave_interconnect_%(busnumber)s
 PARAMETER HW_VER = 1.06.a
 ## use shared mode, crossbar mode does not work for our design
 #PARAMETER C_INTERCONNECT_CONNECTIVITY_MODE = 0
 #PORT INTERCONNECT_ACLK = processing_system7_0_FCLK_CLK0_0
 #PORT INTERCONNECT_ARESETN = processing_system7_0_M_AXI_GP0_ARESETN
END
'''


mpd_template='''###################################################################
##
## Name     : %(dut)s
## Desc     : Microprocessor Peripheral Description
##          : Automatically generated by bsvgen
##
###################################################################

begin %(dut)s
## Peripheral Options
OPTION IPTYPE = PERIPHERAL
OPTION IMP_NETLIST = TRUE
OPTION HDL = VERILOG
OPTION IP_GROUP = MICROBLAZE:USER
OPTION DESC = %(dut)s
OPTION ARCH_SUPPORT_MAP = (others=DEVELOPMENT)

## Bus Interfaces
%(bus_declarations)s

## Generics for VHDL or Parameters for Verilog
%(parameter_declarations)s

## Ports
PORT interrupt = "", DIR = O, SIGIS = INTERRUPT
PORT xadc_gpio_0 = "", DIR = O
PORT xadc_gpio_1 = "", DIR = O
PORT xadc_gpio_2 = "", DIR = O
PORT xadc_gpio_3 = "", DIR = O
%(port_declarations)s
END
'''

axi_master_bus_mpd_template='''
BUS_INTERFACE BUS = %(BUSNAME)s, BUS_STD = AXIPT, BUS_TYPE = MASTER'''

axi_slave_bus_mpd_template='''
BUS_INTERFACE BUS = %(BUSNAME)s, BUS_STD = AXIPT, BUS_TYPE = SLAVE'''

hdmi_bus_mpd_template='''
IO_INTERFACE IO_IF = %(BUSNAME)s, IO_TYPE = HDMI'''

axi_master_parameter_mpd_template='''
PARAMETER C_%(BUSNAME)s_ADDR_WIDTH = 32, DT = INTEGER, BUS = %(BUSNAME)s, ASSIGNMENT = CONSTANT
PARAMETER C_%(BUSNAME)s_DATA_WIDTH = %(datawidth)s, DT = INTEGER, BUS = %(BUSNAME)s, ASSIGNMENT = CONSTANT
PARAMETER C_%(BUSNAME)s_PROT_WIDTH = %(protwidth)s, DT = INTEGER, BUS = %(BUSNAME)s, ASSIGNMENT = CONSTANT
PARAMETER C_%(BUSNAME)s_BURSTLEN_WIDTH = %(burstlenwidth)s, DT = INTEGER, BUS = %(BUSNAME)s, ASSIGNMENT = CONSTANT
PARAMETER C_%(BUSNAME)s_CACHE_WIDTH = %(cachewidth)s, DT = INTEGER, BUS = %(BUSNAME)s, ASSIGNMENT = CONSTANT
PARAMETER C_%(BUSNAME)s_ID_WIDTH = 1, DT = integer, BUS = %(BUSNAME)s
PARAMETER C_%(BUSNAME)s_PROTOCOL = %(axiprotocol)s, TYPE = NON_HDL, ASSIGNMENT = CONSTANT, DT = STRING, BUS = %(BUSNAME)s
'''

axi_slave_parameter_mpd_template='''
PARAMETER C_%(BUSNAME)s_DATA_WIDTH = 32, DT = INTEGER, BUS = %(BUSNAME)s, ASSIGNMENT = CONSTANT
PARAMETER C_%(BUSNAME)s_ADDR_WIDTH = 32, DT = INTEGER, BUS = %(BUSNAME)s, ASSIGNMENT = CONSTANT
PARAMETER C_%(BUSNAME)s_ID_WIDTH = 4, DT = INTEGER, BUS = %(BUSNAME)s
PARAMETER C_%(BUSNAME)s_MEM0_BASEADDR = 0xffffffff, DT = std_logic_vector, PAIR = C_%(BUSNAME)s_MEM0_HIGHADDR, ADDRESS = BASE, CACHEABLE = FALSE, MIN_SIZE=0x1000, ADDR_TYPE=REGISTER, BUS = %(BUSNAME)s
PARAMETER C_%(BUSNAME)s_MEM0_HIGHADDR = 0x00000000, DT = std_logic_vector, PAIR = C_%(BUSNAME)s_MEM0_BASEADDR, ADDRESS = HIGH, CACHEABLE = FALSE, MIN_SIZE=0x1000, ADDR_TYPE=REGISTER, BUS = %(BUSNAME)s
PARAMETER C_%(BUSNAME)s_PROTOCOL = AXI4, TYPE = NON_HDL, ASSIGNMENT = CONSTANT, DT = STRING, BUS = %(BUSNAME)s
'''

axi_master_port_declaration_mpd_template='''
PORT %(busname)s_aclk = "", DIR = I, SIGIS = CLK, BUS = %(BUSNAME)s, ASSIGNMENT = REQUIRE
PORT %(busname)s_aresetn = ARESETN, DIR = I, SIGIS = RST, BUS = %(BUSNAME)s, ASSIGNMENT = REQUIRE
PORT %(busname)s_arready = ARREADY, DIR = I, BUS = %(BUSNAME)s
PORT %(busname)s_arvalid = ARVALID, DIR = O, BUS = %(BUSNAME)s
PORT %(busname)s_arid = ARID, DIR = O, VEC = [((C_%(BUSNAME)s_ID_WIDTH)-1):0], BUS = %(BUSNAME)s
PORT %(busname)s_araddr = ARADDR, DIR = O, VEC = [(C_%(BUSNAME)s_ADDR_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(busname)s_arlen = ARLEN, DIR = O, VEC = [(C_%(BUSNAME)s_BURSTLEN_WIDTH-1):0], BUS = %(BUSNAME)s
PORT %(busname)s_arsize = ARSIZE, DIR = O, VEC = [2:0], BUS = %(BUSNAME)s
PORT %(busname)s_arburst = ARBURST, DIR = O, VEC = [1:0], BUS = %(BUSNAME)s
PORT %(busname)s_arprot = ARPROT, DIR = O, VEC = [(C_%(BUSNAME)s_PROT_WIDTH-1):0], BUS = %(BUSNAME)s
PORT %(busname)s_arcache = ARCACHE, DIR = O, VEC = [(C_%(BUSNAME)s_CACHE_WIDTH-1):0], BUS = %(BUSNAME)s
PORT %(busname)s_rready = RREADY, DIR = O, BUS = %(BUSNAME)s
PORT %(busname)s_rvalid = RVALID, DIR = I, BUS = %(BUSNAME)s
PORT %(busname)s_rid = RID, DIR = I, VEC = [((C_%(BUSNAME)s_ID_WIDTH)-1):0], BUS = %(BUSNAME)s
PORT %(busname)s_rdata = RDATA, DIR = I, VEC = [(C_%(BUSNAME)s_DATA_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(busname)s_rresp = RRESP, DIR = I, VEC = [1:0], BUS = %(BUSNAME)s
PORT %(busname)s_rlast = RLAST, DIR = I, BUS = %(BUSNAME)s
PORT %(busname)s_awready = AWREADY, DIR = I, BUS = %(BUSNAME)s
PORT %(busname)s_awvalid = AWVALID, DIR = O, BUS = %(BUSNAME)s
PORT %(busname)s_awid = AWID, DIR = O, VEC = [((C_%(BUSNAME)s_ID_WIDTH)-1):0], BUS = %(BUSNAME)s
PORT %(busname)s_awaddr = AWADDR, DIR = O, VEC = [(C_%(BUSNAME)s_ADDR_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(busname)s_awlen = AWLEN, DIR = O, VEC = [(C_%(BUSNAME)s_BURSTLEN_WIDTH-1):0], BUS = %(BUSNAME)s
PORT %(busname)s_awsize = AWSIZE, DIR = O, VEC = [2:0], BUS = %(BUSNAME)s
PORT %(busname)s_awburst = AWBURST, DIR = O, VEC = [1:0], BUS = %(BUSNAME)s
PORT %(busname)s_awprot = AWPROT, DIR = O, VEC = [(C_%(BUSNAME)s_PROT_WIDTH-1):0], BUS = %(BUSNAME)s
PORT %(busname)s_awcache = AWCACHE, DIR = O, VEC = [(C_%(BUSNAME)s_CACHE_WIDTH-1):0], BUS = %(BUSNAME)s
PORT %(busname)s_wready = WREADY, DIR = I, BUS = %(BUSNAME)s
PORT %(busname)s_wvalid = WVALID, DIR = O, BUS = %(BUSNAME)s
PORT %(busname)s_wdata = WDATA, DIR = O, VEC = [(C_%(BUSNAME)s_DATA_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(busname)s_wstrb = WSTRB, DIR = O, VEC = [((C_%(BUSNAME)s_DATA_WIDTH/8)-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(busname)s_wlast = WLAST, DIR = O, BUS = %(BUSNAME)s
PORT %(busname)s_bready = BREADY, DIR = O, BUS = %(BUSNAME)s
PORT %(busname)s_bid = BID, DIR = I, VEC = [((C_%(BUSNAME)s_ID_WIDTH)-1):0], BUS = %(BUSNAME)s
PORT %(busname)s_bvalid = BVALID, DIR = I, BUS = %(BUSNAME)s
PORT %(busname)s_bresp = BRESP, DIR = I, VEC = [1:0], BUS = %(BUSNAME)s
'''

axi_slave_port_declaration_mpd_template='''
PORT %(BUSNAME)s_ACLK = "", DIR = I, SIGIS = CLK, BUS = %(BUSNAME)s, ASSIGNMENT = REQUIRE
PORT %(BUSNAME)s_ARESETN = ARESETN, DIR = I, SIGIS = RST, BUS = %(BUSNAME)s, ASSIGNMENT = REQUIRE
PORT %(BUSNAME)s_AWADDR = AWADDR, DIR = I, VEC = [(C_%(BUSNAME)s_ADDR_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_AWVALID = AWVALID, DIR = I, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_WDATA = WDATA, DIR = I, VEC = [(C_%(BUSNAME)s_DATA_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_WSTRB = WSTRB, DIR = I, VEC = [((C_%(BUSNAME)s_DATA_WIDTH/8)-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_WVALID = WVALID, DIR = I, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_BREADY = BREADY, DIR = I, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARADDR = ARADDR, DIR = I, VEC = [(C_%(BUSNAME)s_ADDR_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARVALID = ARVALID, DIR = I, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_RREADY = RREADY, DIR = I, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARREADY = ARREADY, DIR = O, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_RDATA = RDATA, DIR = O, VEC = [(C_%(BUSNAME)s_DATA_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_RRESP = RRESP, DIR = O, VEC = [1:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_RVALID = RVALID, DIR = O, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_WREADY = WREADY, DIR = O, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_BRESP = BRESP, DIR = O, VEC = [1:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_BVALID = BVALID, DIR = O, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_AWREADY = AWREADY, DIR = O, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_AWID = AWID, DIR = I, VEC = [(C_%(BUSNAME)s_ID_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_AWLEN = AWLEN, DIR = I, VEC = [4:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_AWSIZE = AWSIZE, DIR = I, VEC = [2:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_AWBURST = AWBURST, DIR = I, VEC = [1:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_AWLOCK = AWLOCK, DIR = I, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_AWCACHE = AWCACHE, DIR = I, VEC = [2:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_AWPROT = AWPROT, DIR = I, VEC = [1:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_WLAST = WLAST, DIR = I, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_BID = BID, DIR = O, VEC = [(C_%(BUSNAME)s_ID_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARID = ARID, DIR = I, VEC = [(C_%(BUSNAME)s_ID_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARLEN = ARLEN, DIR = I, VEC = [3:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARSIZE = ARSIZE, DIR = I, VEC = [2:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARBURST = ARBURST, DIR = I, VEC = [1:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARLOCK = ARLOCK, DIR = I, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARCACHE = ARCACHE, DIR = I, VEC = [2:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARPROT = ARPROT, DIR = I, VEC = [1:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_RID = RID, DIR = O, VEC = [(C_%(BUSNAME)s_ID_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_RLAST = RLAST, DIR = O, BUS = %(BUSNAME)s
'''

hdmi_port_declaration_mpd_template='''
PORT hdmi_clk_in = "", DIR = I, SIGIS = CLK
PORT hdmi_clk = "", DIR = O, SIGIS = CLK, IO_IF=%(busname)s
PORT hdmi_vsync = "", DIR = O, IO_IF=%(busname)s
PORT hdmi_hsync = "", DIR = O, IO_IF=%(busname)s
PORT hdmi_de = "", DIR = O, IO_IF=%(busname)s
PORT hdmi_data = "", DIR = O, VEC = [15:0], IO_IF=%(busname)s

PORT xadc_gpio_0 = "", DIR = O
PORT xadc_gpio_1 = "", DIR = O
PORT xadc_gpio_2 = "", DIR = O
PORT xadc_gpio_3 = "", DIR = O
'''

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

bif_template='''
the_ROM_image:
{
	[bootloader] zynq_fsbl.elf
	implementation/%(dut)s.bit
	zcomposite.elf
}
'''

pao_template='''
lib proc_common_v3_00_a  all 
lib %(dut)s_v1_00_a %(Dut)s verilog
lib %(dut)s_v1_00_a mk%(Dut)sWrapper verilog
'''

top_verilog_template='''
`timescale 1 ps / 1 ps
// lib IP_Integrator_Lib
(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLanguage=VERILOG}" *) 
module %(dut)s_top_1
   (DDR_Addr,
    DDR_BankAddr,
    DDR_CAS_n,
    DDR_Clk_n,
    DDR_Clk_p,
    DDR_CKE,
    DDR_CS_n,
    DDR_DM,
    DDR_DQ,
    DDR_DQS_n,
    DDR_DQS_p,
    DDR_ODT,
    DDR_RAS_n,
    DDR_DRSTB,
    DDR_WEB,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    GPIO_leds);
  inout [14:0]DDR_Addr;
  inout [2:0]DDR_BankAddr;
  inout DDR_CAS_n;
  inout DDR_Clk_n;
  inout DDR_Clk_p;
  inout DDR_CKE;
  inout DDR_CS_n;
  inout [3:0]DDR_DM;
  inout [31:0]DDR_DQ;
  inout [3:0]DDR_DQS_n;
  inout [3:0]DDR_DQS_p;
  inout DDR_ODT;
  inout DDR_RAS_n;
  inout DDR_DRSTB;
  inout DDR_WEB;
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout [53:0]FIXED_IO_mio;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  output [7:0] GPIO_leds;

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

GND GND
       (.G(GND_1));
%(dut)s#(
.C_CTRL_MEM0_BASEADDR (32'h6e400000),
.C_CTRL_MEM0_HIGHADDR (32'h6e41ffff),
.C_CTRL_ADDR_WIDTH(64),
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
        .PS_CLK(FIXED_IO_ps_clk),
        .PS_PORB(FIXED_IO_ps_porb),
        .PS_SRSTB(FIXED_IO_ps_srstb));
   
endmodule
'''

top_axi_master_wires_template='''
  wire [31:0]%(dut)s_1_%(busname)s_ARADDR;
  wire [1:0]%(dut)s_1_%(busname)s_ARBURST;
  wire [2:0]%(dut)s_1_%(busname)s_ARCACHE;
  wire [5:0]%(dut)s_1_%(busname)s_ARID;
  wire [3:0]%(dut)s_1_%(busname)s_ARLEN;
  wire [1:0]%(dut)s_1_%(busname)s_ARPROT;
  wire %(dut)s_1_%(busname)s_ARREADY;
  wire [2:0]%(dut)s_1_%(busname)s_ARSIZE;
  wire %(dut)s_1_%(busname)s_ARVALID;
  wire [31:0]%(dut)s_1_%(busname)s_AWADDR;
  wire [1:0]%(dut)s_1_%(busname)s_AWBURST;
  wire [2:0]%(dut)s_1_%(busname)s_AWCACHE;
  wire [5:0]%(dut)s_1_%(busname)s_AWID;
  wire [3:0]%(dut)s_1_%(busname)s_AWLEN;
  wire [1:0]%(dut)s_1_%(busname)s_AWPROT;
  wire %(dut)s_1_%(busname)s_AWREADY;
  wire [2:0]%(dut)s_1_%(busname)s_AWSIZE;
  wire %(dut)s_1_%(busname)s_AWVALID;
  wire [5:0]%(dut)s_1_%(busname)s_BID;
  wire %(dut)s_1_%(busname)s_BREADY;
  wire [1:0]%(dut)s_1_%(busname)s_BRESP;
  wire %(dut)s_1_%(busname)s_BVALID;
  wire [63:0]%(dut)s_1_%(busname)s_RDATA;
  wire [5:0]%(dut)s_1_%(busname)s_RID;
  wire %(dut)s_1_%(busname)s_RLAST;
  wire %(dut)s_1_%(busname)s_RREADY;
  wire [1:0]%(dut)s_1_%(busname)s_RRESP;
  wire %(dut)s_1_%(busname)s_RVALID;
  wire [63:0]%(dut)s_1_%(busname)s_WDATA;
  wire [5:0]%(dut)s_1_%(busname)s_WID;
  wire %(dut)s_1_%(busname)s_WLAST;
  wire %(dut)s_1_%(busname)s_WREADY;
  wire [7:0]%(dut)s_1_%(busname)s_WSTRB;
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
        .S_AXI_HP%(busnumber)s_ACLK(processing_system7_1_fclk_clk0),
        .S_AXI_HP%(busnumber)s_ARADDR(%(dut)s_1_%(busname)s_ARADDR),
        .S_AXI_HP%(busnumber)s_ARBURST(%(dut)s_1_%(busname)s_ARBURST),
        .S_AXI_HP%(busnumber)s_ARCACHE(%(dut)s_1_%(busname)s_ARCACHE),
        .S_AXI_HP%(busnumber)s_ARID(%(dut)s_1_%(busname)s_ARID),
        .S_AXI_HP%(busnumber)s_ARLEN(%(dut)s_1_%(busname)s_ARLEN),
        .S_AXI_HP%(busnumber)s_ARLOCK({GND_1,GND_1}),
        .S_AXI_HP%(busnumber)s_ARPROT(%(dut)s_1_%(busname)s_ARPROT),
        .S_AXI_HP%(busnumber)s_ARQOS({GND_1,GND_1,GND_1,GND_1}),
        .S_AXI_HP%(busnumber)s_ARREADY(%(dut)s_1_%(busname)s_ARREADY),
        .S_AXI_HP%(busnumber)s_ARSIZE(%(dut)s_1_%(busname)s_ARSIZE),
        .S_AXI_HP%(busnumber)s_ARVALID(%(dut)s_1_%(busname)s_ARVALID),
        .S_AXI_HP%(busnumber)s_AWADDR(%(dut)s_1_%(busname)s_AWADDR),
        .S_AXI_HP%(busnumber)s_AWBURST(%(dut)s_1_%(busname)s_AWBURST),
        .S_AXI_HP%(busnumber)s_AWCACHE(%(dut)s_1_%(busname)s_AWCACHE),
        .S_AXI_HP%(busnumber)s_AWID(%(dut)s_1_%(busname)s_AWID),
        .S_AXI_HP%(busnumber)s_AWLEN(%(dut)s_1_%(busname)s_AWLEN),
        .S_AXI_HP%(busnumber)s_AWLOCK({GND_1,GND_1}),
        .S_AXI_HP%(busnumber)s_AWPROT(%(dut)s_1_%(busname)s_AWPROT),
        .S_AXI_HP%(busnumber)s_AWQOS({GND_1,GND_1,GND_1,GND_1}),
        .S_AXI_HP%(busnumber)s_AWREADY(%(dut)s_1_%(busname)s_AWREADY),
        .S_AXI_HP%(busnumber)s_AWSIZE(%(dut)s_1_%(busname)s_AWSIZE),
        .S_AXI_HP%(busnumber)s_AWVALID(%(dut)s_1_%(busname)s_AWVALID),
        .S_AXI_HP%(busnumber)s_BID(%(dut)s_1_%(busname)s_BID),
        .S_AXI_HP%(busnumber)s_BREADY(%(dut)s_1_%(busname)s_BREADY),
        .S_AXI_HP%(busnumber)s_BRESP(%(dut)s_1_%(busname)s_BRESP),
        .S_AXI_HP%(busnumber)s_BVALID(%(dut)s_1_%(busname)s_BVALID),
        .S_AXI_HP%(busnumber)s_RDATA(%(dut)s_1_%(busname)s_RDATA),
        .S_AXI_HP%(busnumber)s_RDISSUECAP1_EN(GND_1),
        .S_AXI_HP%(busnumber)s_RID(%(dut)s_1_%(busname)s_RID),
        .S_AXI_HP%(busnumber)s_RLAST(%(dut)s_1_%(busname)s_RLAST),
        .S_AXI_HP%(busnumber)s_RREADY(%(dut)s_1_%(busname)s_RREADY),
        .S_AXI_HP%(busnumber)s_RRESP(%(dut)s_1_%(busname)s_RRESP),
        .S_AXI_HP%(busnumber)s_RVALID(%(dut)s_1_%(busname)s_RVALID),
        .S_AXI_HP%(busnumber)s_WDATA(%(dut)s_1_%(busname)s_WDATA),
        .S_AXI_HP%(busnumber)s_WID(%(dut)s_1_%(busname)s_WID),
        .S_AXI_HP%(busnumber)s_WLAST(%(dut)s_1_%(busname)s_WLAST),
        .S_AXI_HP%(busnumber)s_WREADY(%(dut)s_1_%(busname)s_WREADY),
        .S_AXI_HP%(busnumber)s_WRISSUECAP1_EN(GND_1),
        .S_AXI_HP%(busnumber)s_WSTRB(%(dut)s_1_%(busname)s_WSTRB),
        .S_AXI_HP%(busnumber)s_WVALID(%(dut)s_1_%(busname)s_WVALID),
'''

verilog_template='''
`uselib lib=unisims_ver
`uselib lib=proc_common_v3_00_a

module %(dut)s
(
    xadc_gpio_0,
    xadc_gpio_1,
    xadc_gpio_2,
    xadc_gpio_3,

%(axi_master_ports)s
%(axi_slave_ports)s
%(hdmi_ports)s

    interrupt
  );

%(axi_master_parameters)s
%(axi_slave_parameters)s
parameter C_FAMILY = "virtex6";

output xadc_gpio_0;
output xadc_gpio_1;
output xadc_gpio_2;
output xadc_gpio_3;

%(axi_master_port_decls)s
%(axi_slave_port_decls)s
%(hdmi_port_decls)s

output interrupt;



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
%(hdmi_iobufs)s

endmodule
'''

## causes multiple source errors on other signals
obuf_verilog_template='''
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_xadc_gpio_0
    (
    .O(xadc_gpio_0),
    // Buffer output (connect directly to top-level port)
    .I(CTRL_ACLK)
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_xadc_gpio_1
    (
    .O(xadc_gpio_1),
    // Buffer output (connect directly to top-level port)
    .I(CTRL_ARREADY_unbuf)
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_xadc_gpio_2 (
    .O(xadc_gpio_2),
    // Buffer output (connect directly to top-level port)
    .I(CTRL_RVALID_unbuf)
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_xadc_gpio_3
    (
    .O(xadc_gpio_3),
    // Buffer output (connect directly to top-level port)
    .I(CTRL_AWVALID)
    // Buffer input
    );
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
    %(busname)s_aclk,
    %(busname)s_aresetn,
    %(busname)s_arready,
    %(busname)s_arvalid,
    %(busname)s_arid,
    %(busname)s_araddr,
    %(busname)s_arlen,
    %(busname)s_arsize,
    %(busname)s_arburst,
    %(busname)s_arprot,
    %(busname)s_arcache,
    %(busname)s_rready,
    %(busname)s_rvalid,
    %(busname)s_rid,
    %(busname)s_rdata,
    %(busname)s_rresp,
    %(busname)s_rlast,
    %(busname)s_awready,
    %(busname)s_awvalid,
    %(busname)s_awid,
    %(busname)s_awaddr,
    %(busname)s_awlen,
    %(busname)s_awsize,
    %(busname)s_awburst,
    %(busname)s_awprot,
    %(busname)s_awcache,
    %(busname)s_wready,
    %(busname)s_wvalid,
    %(busname)s_wid,
    %(busname)s_wdata,
    %(busname)s_wstrb,
    %(busname)s_wlast,
    %(busname)s_bready,
    %(busname)s_bid,
    %(busname)s_bvalid,
    %(busname)s_bresp,
//============ %(BUSNAME)s ============
'''

axi_slave_port_verilog_template='''
//============ %(BUSNAME)s ============
    %(BUSNAME)s_ACLK,
    %(BUSNAME)s_ARESETN,
    %(BUSNAME)s_AWADDR,
    %(BUSNAME)s_AWVALID,
    %(BUSNAME)s_WDATA,
    %(BUSNAME)s_WSTRB,
    %(BUSNAME)s_WVALID,
    %(BUSNAME)s_BREADY,
    %(BUSNAME)s_ARADDR,
    %(BUSNAME)s_ARVALID,
    %(BUSNAME)s_RREADY,
    %(BUSNAME)s_ARREADY,
    %(BUSNAME)s_RDATA,
    %(BUSNAME)s_RRESP,
    %(BUSNAME)s_RVALID,
    %(BUSNAME)s_WREADY,
    %(BUSNAME)s_BRESP,
    %(BUSNAME)s_BVALID,
    %(BUSNAME)s_AWREADY,
    %(BUSNAME)s_AWID,
    %(BUSNAME)s_AWLEN,
    %(BUSNAME)s_AWSIZE,
    %(BUSNAME)s_AWBURST,
    %(BUSNAME)s_AWLOCK,
    %(BUSNAME)s_AWCACHE,
    %(BUSNAME)s_AWPROT,
    %(BUSNAME)s_WLAST,
    %(BUSNAME)s_BID,
    %(BUSNAME)s_ARID,
    %(BUSNAME)s_ARLEN,
    %(BUSNAME)s_ARSIZE,
    %(BUSNAME)s_ARBURST,
    %(BUSNAME)s_ARLOCK,
    %(BUSNAME)s_ARCACHE,
    %(BUSNAME)s_ARPROT,
    %(BUSNAME)s_RID,
    %(BUSNAME)s_RLAST,
//============ %(BUSNAME)s ============
'''

hdmi_port_verilog_template='''
    hdmi_clk_in,
    hdmi_clk,
    hdmi_vsync,
    hdmi_hsync,
    hdmi_de,
    hdmi_data,
'''


axi_master_port_decl_verilog_template='''
//============ %(BUSNAME)s ============
input %(busname)s_aclk;
input %(busname)s_aresetn;
input %(busname)s_arready;
output %(busname)s_arvalid;
output [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(busname)s_arid;
output [C_%(BUSNAME)s_ADDR_WIDTH-1 : 0] %(busname)s_araddr;
output [C_%(BUSNAME)s_BURSTLEN_WIDTH-1 : 0] %(busname)s_arlen;
output [2 : 0] %(busname)s_arsize;
output [1 : 0] %(busname)s_arburst;
output [(C_%(BUSNAME)s_PROT_WIDTH-1) : 0] %(busname)s_arprot;
output [(C_%(BUSNAME)s_CACHE_WIDTH-1) : 0] %(busname)s_arcache;
output %(busname)s_rready;
input %(busname)s_rvalid;
input [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(busname)s_rid;
input [C_%(BUSNAME)s_DATA_WIDTH-1 : 0] %(busname)s_rdata;
input [1 : 0] %(busname)s_rresp;
input %(busname)s_rlast;
input %(busname)s_awready;
output %(busname)s_awvalid;
output [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(busname)s_awid;
output [C_%(BUSNAME)s_ADDR_WIDTH-1 : 0] %(busname)s_awaddr;
output [C_%(BUSNAME)s_BURSTLEN_WIDTH-1 : 0] %(busname)s_awlen;
output [2 : 0] %(busname)s_awsize;
output [1 : 0] %(busname)s_awburst;
output [(C_%(BUSNAME)s_PROT_WIDTH-1) : 0] %(busname)s_awprot;
output [(C_%(BUSNAME)s_CACHE_WIDTH-1) : 0] %(busname)s_awcache;
input %(busname)s_wready;
output %(busname)s_wvalid;
output [C_%(BUSNAME)s_ID_WIDTH - 1 : 0] %(busname)s_wid;
output [C_%(BUSNAME)s_DATA_WIDTH - 1 : 0] %(busname)s_wdata;
wire [C_%(BUSNAME)s_DATA_WIDTH - 1 : 0] %(busname)s_wdata_wire;
output [(C_%(BUSNAME)s_DATA_WIDTH)/8 - 1 : 0] %(busname)s_wstrb;
output %(busname)s_wlast;
output %(busname)s_bready;
input [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(busname)s_bid;
input %(busname)s_bvalid;
input [1 : 0] %(busname)s_bresp;
//============ %(BUSNAME)s ============
'''

axi_slave_port_decl_verilog_template='''
//============ %(BUSNAME)s ============
input %(BUSNAME)s_ACLK;
input %(BUSNAME)s_ARESETN;
input [C_%(BUSNAME)s_ADDR_WIDTH-1 : 0] %(BUSNAME)s_AWADDR;
input %(BUSNAME)s_AWVALID;
input [C_%(BUSNAME)s_DATA_WIDTH-1 : 0] %(BUSNAME)s_WDATA;
input [(C_%(BUSNAME)s_DATA_WIDTH/8)-1 : 0] %(BUSNAME)s_WSTRB;
input %(BUSNAME)s_WVALID;
input %(BUSNAME)s_BREADY;
input [C_%(BUSNAME)s_ADDR_WIDTH-1 : 0] %(BUSNAME)s_ARADDR;
input %(BUSNAME)s_ARVALID;
input %(BUSNAME)s_RREADY;
output %(BUSNAME)s_ARREADY;
wire %(BUSNAME)s_ARREADY_unbuf;
output [C_%(BUSNAME)s_DATA_WIDTH-1 : 0] %(BUSNAME)s_RDATA;
output [1 : 0] %(BUSNAME)s_RRESP;
output %(BUSNAME)s_RVALID;
wire %(BUSNAME)s_RVALID_unbuf;
output %(BUSNAME)s_WREADY;
output [1 : 0] %(BUSNAME)s_BRESP;
output %(BUSNAME)s_BVALID;
output %(BUSNAME)s_AWREADY;
input [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(BUSNAME)s_AWID;
input [3 : 0] %(BUSNAME)s_AWLEN;
input [2 : 0] %(BUSNAME)s_AWSIZE;
input [1 : 0] %(BUSNAME)s_AWBURST;
input %(BUSNAME)s_AWLOCK;
input [2 : 0] %(BUSNAME)s_AWCACHE;
input [1 : 0] %(BUSNAME)s_AWPROT;
input %(BUSNAME)s_WLAST;
output [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(BUSNAME)s_BID;
input [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(BUSNAME)s_ARID;
input [3 : 0] %(BUSNAME)s_ARLEN;
input [2 : 0] %(BUSNAME)s_ARSIZE;
input [1 : 0] %(BUSNAME)s_ARBURST;
input %(BUSNAME)s_ARLOCK;
input [2 : 0] %(BUSNAME)s_ARCACHE;
input [1 : 0] %(BUSNAME)s_ARPROT;
output [C_%(BUSNAME)s_ID_WIDTH-1 : 0] %(BUSNAME)s_RID;
output %(BUSNAME)s_RLAST;
//============ %(BUSNAME)s ============
'''

hdmi_port_decl_verilog_template='''
input hdmi_clk_in;
output hdmi_clk;
output hdmi_vsync;
output hdmi_hsync;
output hdmi_de;
output [15:0] hdmi_data;
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
      .%(busname)s_hdmi_vsync(hdmi_vsync_unbuf),
      .%(busname)s_hdmi_hsync(hdmi_hsync_unbuf),
      .%(busname)s_hdmi_de(hdmi_de_unbuf),
      .%(busname)s_hdmi_data(hdmi_data_unbuf),
'''

axi_master_signal_verilog_template='''
  wire RDY_%(busname)s_write_writeAddr;
  wire RDY_%(busname)s_write_writeData;
  wire RDY_%(busname)s_write_writeResponse;
  wire RDY_%(busname)s_read_readAddr;
  wire RDY_%(busname)s_read_readData;
  wire WILL_FIRE_%(busname)s_write_writeAddr;
  wire WILL_FIRE_%(busname)s_write_writeData;
  wire [C_%(BUSNAME)s_DATA_WIDTH-1 : 0] %(busname)s_wdata_wire;
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
    OBUF#(
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_%(busname)s_clk
    (
    .O(%(busname)s_clk),
    // Buffer output (connect directly to top-level port)
    .I( hdmi_clk_in)
    // Buffer input
    );

    OBUF#(
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_hsync
    (
    .O(%(busname)s_hsync),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_hsync_unbuf)
    // Buffer input
    );
    OBUF#(
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_vsync
    (
    .O(%(busname)s_vsync),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_vsync_unbuf)
    // Buffer input
    );
    OBUF#(
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_de
    (
    .O(%(busname)s_de),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_de_unbuf)
    // Buffer input
    );

    OBUF#(
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_0
    (
    .O(%(busname)s_data[0]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[0])
    // Buffer input
    );
    OBUF #(
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_1
    (
    .O(%(busname)s_data[1]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[1])
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_2
    (
    .O(%(busname)s_data[2]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[2])
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_3
    (
    .O(%(busname)s_data[3]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[3])
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_4
    (
    .O(%(busname)s_data[4]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[4])
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_5
    (
    .O(%(busname)s_data[5]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[5])
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_6
    (
    .O(%(busname)s_data[6]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[6])
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_7
    (
    .O(%(busname)s_data[7]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[7])
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_8
    (
    .O(%(busname)s_data[8]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[8])
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_9
    (
    .O(%(busname)s_data[9]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[9])
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_10
    (
    .O(%(busname)s_data[10]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[10])
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_11
    (
    .O(%(busname)s_data[11]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[11])
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_12
    (
    .O(%(busname)s_data[12]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[12])
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_13
    (
    .O(%(busname)s_data[13]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[13])
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_14
    (
    .O(%(busname)s_data[14]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[14])
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_data_15
    (
    .O(%(busname)s_data[15]),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_data_unbuf[15])
    // Buffer input
    );

    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_xadc_gpio_0
    (
    .O(xadc_gpio_0),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_vsync_unbuf)
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_xadc_gpio_1
    (
    .O(xadc_gpio_1),
    // Buffer output (connect directly to top-level port)
    .I(WILL_FIRE_m_axi_read_readAddr)
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_xadc_gpio_2 (
    .O(xadc_gpio_2),
    // Buffer output (connect directly to top-level port)
    .I(WILL_FIRE_m_axi_read_readData)
    // Buffer input
    );
    OBUF # (
    .DRIVE(12),
    .IOSTANDARD("LVCMOS25"),
    .SLEW("SLOW")) OBUF_xadc_gpio_3
    (
    .O(xadc_gpio_3),
    // Buffer output (connect directly to top-level port)
    .I(%(busname)s_de_unbuf)
    // Buffer input
    );

'''

class InterfaceMixin:
    def axiMasterBusSubst(self, busnumber, businfo):
        (busname,t,params) = businfo
        print 'bustype: ', t, ('AXI4' if (t == 'AxiMaster') else 'AXI3'), params[0].numeric()
        dutName = util.decapitalize(self.name)
        return {
            'dut': dutName,
            'BUSNAME': busname.upper(),
            'busname': busname,
            'busnumber': 0,
            'datawidth': params[0].numeric(),
            'burstlenwidth': 8 if (t == 'AxiMaster') else 4,
            'protwidth': 3 if (t == 'AxiMaster') else 2,
            'cachewidth': 4 if (t == 'AxiMaster') else 3,
            'axiprotocol': 'AXI4' if (t == 'AxiMaster') else 'AXI3',
            }
    def writeMpd(self, mpdname, silent=False):
        if not silent:
            print 'Writing MPD file', mpdname
        mpd = util.createDirAndOpen(mpdname, 'w')
        dutName = util.decapitalize(self.name)
        axiMasters = self.collectInterfaceNames('Axi3?Client')
        axiSlaves = [('ctrl','AxiSlave',[])] + self.collectInterfaceNames('AxiSlave')
        hdmiBus = self.collectInterfaceNames('HDMI')
        masterBusSubsts = [ self.axiMasterBusSubst(busnumber,axiMasters[busnumber]) for busnumber in range(len(axiMasters)) ]
        substs = {
            'dut': dutName,
            'Dut': util.capitalize(self.name),
            'bus_declarations': ''.join([axi_master_bus_mpd_template % subst for subst in masterBusSubsts ]
                                        + ['\n']
                                        + [axi_slave_bus_mpd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                                           for (busname,t,params) in axiSlaves]
                                        + ['\n']
                                        + [hdmi_bus_mpd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                                           for (busname,t,params) in hdmiBus]),
            'parameter_declarations': ''.join([axi_master_parameter_mpd_template % subst for subst in masterBusSubsts ]
                                              + ['\n']
                                              + [axi_slave_parameter_mpd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                                                 for (busname,t,params) in axiSlaves]),
            'port_declarations': ''.join([axi_master_port_declaration_mpd_template % subst for subst in masterBusSubsts ]
                                         + ['\n']
                                         + [axi_slave_port_declaration_mpd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                                            for (busname,t,params) in axiSlaves]
                                         + ['\n']
                                         + [hdmi_port_declaration_mpd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                                            for (busname,t,params) in hdmiBus])
            }
        mpd.write(mpd_template % substs)
        return

    def writeMhs(self, mhsname, silent=False):
        if not silent:
            print 'Writing MHS file', mhsname
        mhs = util.createDirAndOpen(mhsname, 'w')
        dutName = self.name.lower()
        axiMasters = self.collectInterfaceNames('Axi3?Client')
        axiSlaves = [('ctrl','AxiSlave',[])] + self.collectInterfaceNames('AxiSlave')
        hdmiBus = self.collectInterfaceNames('HDMI')
        masterBusSubsts = [ self.axiMasterBusSubst(busnumber,axiMasters[busnumber]) for busnumber in range(len(axiMasters))]
        substs = {
            'dut': dutName,
            'axi_master_interconnects': ''.join([ axi_master_interconnect_mhs_template 
                                                  % {'busnumber': i,
                                                     'BUSNAME': axiMasters[i][0].upper(),
                                                     'chipscopenumber': i+1,
                                                     'dut': dutName } for i in range(len(axiMasters))]),
            'axi_slave_interconnects': ''.join([ axi_slave_interconnect_mhs_template 
                                        % {'busnumber': i} for i in range(len(axiSlaves)) ]),
            'dut_axi_master_config': ''.join([ dut_axi_master_config_mhs_template
                                               % {'busnumber': i, 'busname': axiMasters[i][0]}
                                               for i in range(len(axiMasters))]),
            'dut_axi_slave_config': ''.join([ dut_axi_slave_config_mhs_template
                                              % {'busnumber': i, 
                                                 'busname': axiSlaves[i][0],
                                                 'BUSNAME': axiSlaves[i][0].upper(),
                                                 'busbase': hex(0x6e400000 + 0x00020000*i),
                                                 'bushigh': hex(0x6e400000 + 0x00020000*i + 0x1FFFF)}
                                              for i in range(len(axiSlaves))]),
            'ps7_axi_master_config': ''.join([ ps7_axi_master_config_mhs_template
                                               % {'dut': dutName,
                                                  'busnumber': i,
                                                  'busname': axiMasters[i][0],
                                                  'BUSNAME': axiMasters[i][0].upper()}
                                               for i in range(len(axiMasters))]),
            'ps7_hdmi_config': ''.join(['''
 PARAMETER C_EN_EMIO_I2C1 = 1
 PARAMETER C_EN_I2C1 = 1
 PORT I2C1_SCL = processing_system7_0_I2C1_SCL
 PORT I2C1_SDA = processing_system7_0_I2C1_SDA
'''
                                        for v in hdmiBus]),
            'dut_hdmi_config': ''.join([ dut_hdmi_config_mhs_template % {'dut':dutName} for v in hdmiBus]),
            'system_hdmi_ports': ''.join([system_hdmi_port_mhs_template % {'dut':dutName} for v in hdmiBus]),
            'chipscopecontrols': ''.join([ (' PORT control%d = chipscope_icon_0_control%d\n' % (i+1, i+1)) for i in range(len(axiMasters))]),
            'chipscopecount': len(axiMasters)+1
            }
        mhs.write(mhs_template % substs)
        return

    def writeXmp(self, xmpname, silent=False):
        if not silent:
            print 'Writing XPS project file', xmpname
        xmp = util.createDirAndOpen(xmpname, 'w')
        dutName = self.name.lower()
        substs = {
            'dut': dutName,
            'edkversion': edkversion,
            }
        xmp.write(xmp_template % substs)
        return

    def writePao(self, paoname, silent=False):
        if os.path.exists(paoname):
            if not silent:
                print 'Not overwriting PAO file', paoname
            return
        print 'Writing PAO file', paoname
        pao = util.createDirAndOpen(paoname, 'w')
        dutName = self.name.lower()
        substs = {
            'dut': dutName,
            'Dut': util.capitalize(self.name),
            'DUT': self.name.upper(),
        }
        pao.write(pao_template % substs)
        return

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
            'hdmi_port_decls':
                ''.join([hdmi_port_decl_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
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
            'hdmi_iobufs':
                ''.join([hdmi_iobuf_verilog_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in hdmiBus]),
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

    def writeBif(self, bifname, silent=False):
        if not silent:
            print 'Writing BIF file', bifname
        bif = util.createDirAndOpen(bifname, 'w')
        bif.write(bif_template % {'dut': self.name.lower() })
        bif.close()
        return
