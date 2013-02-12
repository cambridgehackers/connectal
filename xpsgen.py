
import os
import util

xmp_template='''
#Please do not modify this file by hand
XmpVersion: 14.3
VerMgmt: 14.3
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
%(system_hdmi_ports)s

BEGIN processing_system7
 PARAMETER INSTANCE = processing_system7_0
 PARAMETER HW_VER = 4.02.a
 PARAMETER C_DDR_RAM_HIGHADDR = 0x3FFFFFFF
 PARAMETER C_USE_M_AXI_GP0 = 1
 PARAMETER C_EN_EMIO_CAN0 = 0
 PARAMETER C_EN_EMIO_CAN1 = 0
 PARAMETER C_EN_EMIO_ENET0 = 0
 PARAMETER C_EN_EMIO_ENET1 = 0
 PARAMETER C_EN_EMIO_I2C0 = 0
 PARAMETER C_EN_EMIO_I2C1 = 0
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
 PARAMETER C_EN_EMIO_TTC0 = 1
 PARAMETER C_EN_EMIO_TTC1 = 0
 PARAMETER C_EN_EMIO_UART0 = 0
 PARAMETER C_EN_EMIO_UART1 = 0
 PARAMETER C_EN_EMIO_MODEM_UART0 = 0
 PARAMETER C_EN_EMIO_MODEM_UART1 = 0
 PARAMETER C_EN_EMIO_WDT = 0
 PARAMETER C_EN_QSPI = 1
 PARAMETER C_EN_SMC = 0
 PARAMETER C_EN_CAN0 = 0
 PARAMETER C_EN_CAN1 = 0
 PARAMETER C_EN_ENET0 = 1
 PARAMETER C_EN_ENET1 = 0
 PARAMETER C_EN_I2C0 = 0
 PARAMETER C_EN_I2C1 = 0
 PARAMETER C_EN_PJTAG = 0
 PARAMETER C_EN_SDIO0 = 1
 PARAMETER C_EN_SDIO1 = 0
 PARAMETER C_EN_SPI0 = 0
 PARAMETER C_EN_SPI1 = 0
 PARAMETER C_EN_TRACE = 0
 PARAMETER C_EN_TTC0 = 1
 PARAMETER C_EN_TTC1 = 0
 PARAMETER C_EN_UART0 = 0
 PARAMETER C_EN_UART1 = 1
 PARAMETER C_EN_MODEM_UART0 = 0
 PARAMETER C_EN_MODEM_UART1 = 0
 PARAMETER C_EN_USB0 = 1
 PARAMETER C_EN_USB1 = 0
 PARAMETER C_EN_WDT = 0
 PARAMETER C_EN_DDR = 1
 PARAMETER C_EN_GPIO = 1
 PARAMETER C_FCLK_CLK0_FREQ = 100000000
 PARAMETER C_FCLK_CLK1_FREQ = 142857132
 PARAMETER C_FCLK_CLK2_FREQ = 50000000
 PARAMETER C_FCLK_CLK3_FREQ = 50000000
 PARAMETER C_USE_CR_FABRIC = 1
 PARAMETER C_USE_M_AXI_GP1 = 0
 PARAMETER C_USE_S_AXI_ACP = 0
 PARAMETER C_EMIO_GPIO_WIDTH = 64
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
 PORT M_AXI_GP0_ACLK = processing_system7_0_FCLK_CLK0_0
 PORT M_AXI_GP0_ARESETN = processing_system7_0_M_AXI_GP0_ARESETN
 BUS_INTERFACE M_AXI_GP0 = axi_slave_interconnect_0

%(ps7_axi_master_config)s

 PORT IRQ_F2P = %(dut)s_0_interrupt
END

%(axi_master_interconnects)s
%(axi_slave_interconnects)s

BEGIN %(dut)s
 PARAMETER INSTANCE = %(dut)s_0
 PARAMETER HW_VER = 1.00.a
 PORT clk = processing_system7_0_FCLK_CLK0_0
 PORT rst_n = processing_system7_0_M_AXI_GP0_ARESETN
 PORT interrupt = %(dut)s_0_interrupt
%(dut_axi_master_config)s
%(dut_axi_slave_config)s
%(dut_hdmi_config)s
END
'''

system_hdmi_port_mhs_template='''
 PORT usr_clk_n_pin = %(dut)s_0_usr_clk_n, DIR = I
 PORT usr_clk_p_pin = %(dut)s_0_usr_clk_p, DIR = I
 PORT hdmi_vsync_pin = %(dut)s_0_hdmi_vsync, DIR = O
 PORT hdmi_hsync_pin = %(dut)s_0_hdmi_hsync, DIR = O
 PORT hdmi_de_pin = %(dut)s_0_hdmi_de, DIR = O
 PORT hdmi_data_pin = %(dut)s_0_hdmi_data, DIR = O, VEC = [15:0]
 PORT hdmi_clk_pin = %(dut)s_0_hdmi_clk, DIR = O, SIGIS = CLK
 PORT xadc_gpio_0_pin = %(dut)s_0_xadc_gpio_0, DIR = O
 PORT xadc_gpio_1_pin = %(dut)s_0_xadc_gpio_1, DIR = O
 PORT xadc_gpio_2_pin = %(dut)s_0_xadc_gpio_2, DIR = O
 PORT xadc_gpio_3_pin = %(dut)s_0_xadc_gpio_3, DIR = O
'''

ps7_axi_master_config_mhs_template='''
 PARAMETER C_INTERCONNECT_S_AXI_HP%(busnumber)s_MASTERS = %(dut)s_0.%(BUSNAME)s
 PARAMETER C_USE_S_AXI_HP%(busnumber)s = 1
 BUS_INTERFACE S_AXI_HP%(busnumber)s = axi_master_interconnect_%(busnumber)s
 PORT S_AXI_HP%(busnumber)s_ACLK = processing_system7_0_FCLK_CLK0_0
 PORT S_AXI_HP%(busnumber)s_ARESETN = processing_system7_0_S_AXI_HP%(busnumber)s_ARESETN
'''

dut_axi_master_config_mhs_template='''
 BUS_INTERFACE %(busname)s = axi_master_interconnect_%(busnumber)s
 PORT %(busname)s_aclk = processing_system7_0_FCLK_CLK0_0
'''

dut_axi_slave_config_mhs_template='''
 PARAMETER C_%(BUSNAME)s_MEM0_BASEADDR = %(busbase)s
 PARAMETER C_%(BUSNAME)s_MEM0_HIGHADDR = %(bushigh)s
 ## not needed for shared mode
 ##PARAMETER C_INTERCONNECT_%(BUSNAME)s_MASTERS = processing_system7_0.M_AXI_GP0
 BUS_INTERFACE %(BUSNAME)s = axi_slave_interconnect_%(busnumber)s
 PORT %(BUSNAME)s_ACLK = processing_system7_0_FCLK_CLK0_0
'''

dut_hdmi_config_mhs_template='''
 PORT usr_clk_p = %(dut)s_0_usr_clk_p
 PORT usr_clk_n = %(dut)s_0_usr_clk_n
 PORT hdmi_clk = %(dut)s_0_hdmi_clk
 PORT hdmi_vsync = %(dut)s_0_hdmi_vsync
 PORT hdmi_hsync = %(dut)s_0_hdmi_hsync
 PORT hdmi_de = %(dut)s_0_hdmi_de
 PORT hdmi_data = %(dut)s_0_hdmi_data
 PORT xadc_gpio_0 = %(dut)s_0_xadc_gpio_0
 PORT xadc_gpio_1 = %(dut)s_0_xadc_gpio_1
 PORT xadc_gpio_2 = %(dut)s_0_xadc_gpio_2
 PORT xadc_gpio_3 = %(dut)s_0_xadc_gpio_3
'''

axi_master_interconnect_mhs_template='''
BEGIN axi_interconnect
 PARAMETER INSTANCE = axi_master_interconnect_%(busnumber)s
 PARAMETER HW_VER = 1.06.a
 PARAMETER C_INTERCONNECT_CONNECTIVITY_MODE = 1
 PORT INTERCONNECT_ACLK = processing_system7_0_FCLK_CLK0_0
 PORT INTERCONNECT_ARESETN = processing_system7_0_S_AXI_HP%(busnumber)s_ARESETN
END
'''

axi_slave_interconnect_mhs_template='''
BEGIN axi_interconnect
 PARAMETER INSTANCE = axi_slave_interconnect_%(busnumber)s
 PARAMETER HW_VER = 1.06.a
 ## use shared mode, crossbar mode does not work for our design
 PARAMETER C_INTERCONNECT_CONNECTIVITY_MODE = 0
 PORT INTERCONNECT_ACLK = processing_system7_0_FCLK_CLK0_0
 PORT INTERCONNECT_ARESETN = processing_system7_0_M_AXI_GP%(busnumber)s_ARESETN
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
OPTION HDL = VHDL
OPTION IP_GROUP = MICROBLAZE:USER
OPTION DESC = %(dut)s
OPTION ARCH_SUPPORT_MAP = (others=DEVELOPMENT)

## Bus Interfaces
%(bus_declarations)s

## Generics for VHDL or Parameters for Verilog
%(parameter_declarations)s

## Ports
PORT interrupt = "", DIR = O, SIGIS = INTERRUPT
PORT clk = "", DIR = I, SIGIS = CLK, ASSIGNMENT=REQUIRE
PORT rst_n = "", DIR = I, SIGIS = RST, RST_POLARITY=0, ASSIGNMENT=REQUIRE
%(port_declarations)s
END
'''

axi_master_bus_mpd_template='''
BUS_INTERFACE BUS = %(BUSNAME)s, BUS_STD = AXI, BUS_TYPE = MASTER'''

axi_slave_bus_mpd_template='''
BUS_INTERFACE BUS = %(BUSNAME)s, BUS_STD = AXI, BUS_TYPE = SLAVE'''

hdmi_bus_mpd_template='''
IO_INTERFACE IO_IF = %(BUSNAME)s, IO_TYPE = HDMI'''

axi_master_parameter_mpd_template='''
PARAMETER C_%(BUSNAME)s_ADDR_WIDTH = 32, DT = INTEGER, BUS = %(BUSNAME)s, ASSIGNMENT = CONSTANT
PARAMETER C_%(BUSNAME)s_DATA_WIDTH = %(datawidth)s, DT = INTEGER, BUS = %(BUSNAME)s, ASSIGNMENT = CONSTANT
PARAMETER C_%(BUSNAME)s_PROT_WIDTH = %(protwidth)s, DT = INTEGER, BUS = %(BUSNAME)s, ASSIGNMENT = CONSTANT
PARAMETER C_%(BUSNAME)s_BURSTLEN_WIDTH = %(burstlenwidth)s, DT = INTEGER, BUS = %(BUSNAME)s, ASSIGNMENT = CONSTANT
PARAMETER C_%(BUSNAME)s_CACHE_WIDTH = %(cachewidth)s, DT = INTEGER, BUS = %(BUSNAME)s, ASSIGNMENT = CONSTANT
PARAMETER C_%(BUSNAME)s_ID_WIDTH = 1, DT = integer, BUS = %(BUSNAME)s
PARAMETER C_%(BUSNAME)s_SUPPORTS_WRITE = 1, DT = INTEGER, BUS = %(BUSNAME)s
PARAMETER C_%(BUSNAME)s_SUPPORTS_READ = 1, DT = INTEGER, BUS = %(BUSNAME)s
PARAMETER C_%(BUSNAME)s_PROTOCOL = %(axiprotocol)s, TYPE = NON_HDL, ASSIGNMENT = CONSTANT, DT = STRING, BUS = %(BUSNAME)s
'''

axi_slave_parameter_mpd_template='''
PARAMETER C_%(BUSNAME)s_DATA_WIDTH = 32, DT = INTEGER, BUS = %(BUSNAME)s, ASSIGNMENT = CONSTANT
PARAMETER C_%(BUSNAME)s_ADDR_WIDTH = 32, DT = INTEGER, BUS = %(BUSNAME)s, ASSIGNMENT = CONSTANT
PARAMETER C_%(BUSNAME)s_ID_WIDTH = 4, DT = INTEGER, BUS = %(BUSNAME)s
PARAMETER C_%(BUSNAME)s_NUM_ADDR_RANGES = 1, DT = INTEGER, BUS = %(BUSNAME)s
PARAMETER C_%(BUSNAME)s_MEM0_BASEADDR = 0xffffffff, DT = std_logic_vector, PAIR = C_%(BUSNAME)s_MEM0_HIGHADDR, ADDRESS = BASE, CACHEABLE = FALSE, MIN_SIZE=0x1000, ADDR_TYPE=REGISTER, BUS = %(BUSNAME)s
PARAMETER C_%(BUSNAME)s_MEM0_HIGHADDR = 0x00000000, DT = std_logic_vector, PAIR = C_%(BUSNAME)s_MEM0_BASEADDR, ADDRESS = HIGH, CACHEABLE = FALSE, MIN_SIZE=0x1000, ADDR_TYPE=REGISTER, BUS = %(BUSNAME)s
PARAMETER C_%(BUSNAME)s_SUPPORTS_WRITE = 1, DT = INTEGER, BUS = %(BUSNAME)s
PARAMETER C_%(BUSNAME)s_SUPPORTS_READ = 1, DT = INTEGER, BUS = %(BUSNAME)s
PARAMETER C_%(BUSNAME)s_SUPPORTS_REORDERING = 0, DT = INTEGER, BUS = %(BUSNAME)s
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
PORT %(BUSNAME)s_AWLEN = AWLEN, DIR = I, VEC = [7:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_AWSIZE = AWSIZE, DIR = I, VEC = [2:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_AWBURST = AWBURST, DIR = I, VEC = [1:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_AWLOCK = AWLOCK, DIR = I, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_AWCACHE = AWCACHE, DIR = I, VEC = [3:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_AWPROT = AWPROT, DIR = I, VEC = [2:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_WLAST = WLAST, DIR = I, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_BID = BID, DIR = O, VEC = [(C_%(BUSNAME)s_ID_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARID = ARID, DIR = I, VEC = [(C_%(BUSNAME)s_ID_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARLEN = ARLEN, DIR = I, VEC = [7:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARSIZE = ARSIZE, DIR = I, VEC = [2:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARBURST = ARBURST, DIR = I, VEC = [1:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARLOCK = ARLOCK, DIR = I, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARCACHE = ARCACHE, DIR = I, VEC = [3:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_ARPROT = ARPROT, DIR = I, VEC = [2:0], BUS = %(BUSNAME)s
PORT %(BUSNAME)s_RID = RID, DIR = O, VEC = [(C_%(BUSNAME)s_ID_WIDTH-1):0], ENDIAN = LITTLE, BUS = %(BUSNAME)s
PORT %(BUSNAME)s_RLAST = RLAST, DIR = O, BUS = %(BUSNAME)s
'''

hdmi_port_declaration_mpd_template='''
PORT hdmi_clk = "", DIR = O, SIGIS = CLK, IO_IF=%(busname)s
PORT hdmi_vsync = "", DIR = O, IO_IF=%(busname)s
PORT hdmi_hsync = "", DIR = O, IO_IF=%(busname)s
PORT hdmi_de = "", DIR = O, IO_IF=%(busname)s
PORT hdmi_data = "", DIR = O, VEC = [15:0], IO_IF=%(busname)s

PORT usr_clk_p = "", DIR = I
PORT usr_clk_n = "", DIR = I
PORT xadc_gpio_0 = "", DIR = O
PORT xadc_gpio_1 = "", DIR = O
PORT xadc_gpio_2 = "", DIR = O
PORT xadc_gpio_3 = "", DIR = O
'''

hdmi_ucf_template='''
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
'''

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

xadc_ucf_template='''
NET "xadc_gpio_0_pin" LOC = H17;
NET "xadc_gpio_0_pin" IOSTANDARD = LVCMOS25;
NET "xadc_gpio_1_pin" LOC = H22;
NET "xadc_gpio_1_pin" IOSTANDARD = LVCMOS25;
NET "xadc_gpio_2_pin" LOC = G22;
NET "xadc_gpio_2_pin" IOSTANDARD = LVCMOS25;
NET "xadc_gpio_3_pin" LOC = H18;
NET "xadc_gpio_3_pin" IOSTANDARD = LVCMOS25;
'''

default_clk_ucf_template='''
NET "processing_system7_0/FCLK_CLK0" TNM_NET = "processing_system7_0/FCLK_CLK0";
TIMESPEC TS_FCLK0 = PERIOD "processing_system7_0/FCLK_CLK0" 133 MHz;
'''

bif_template='''
the_ROM_image:
{
	[bootloader]zynq_fsbl.elf
	implementation/%(dut)s.bit
	u-boot.elf
}
'''

pao_template='''
lib proc_common_v3_00_a  all 
lib %(dut)s_v1_00_a %(Dut)s vhdl
lib %(dut)s_v1_00_a mk%(Dut)sWrapper verilog
'''

vhd_template='''
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity %(dut)s is
  generic
  (
%(axi_master_parameters)s
%(axi_slave_parameters)s
    C_FAMILY                       : string               := "virtex6"
  );
  port
  (
    CLK : in std_logic;
    RST_N : in std_logic;

    xadc_gpio_0 : out std_logic;
    xadc_gpio_1 : out std_logic;
    xadc_gpio_2 : out std_logic;
    xadc_gpio_3 : out std_logic;

%(axi_master_ports)s
%(axi_slave_ports)s
%(hdmi_ports)s

    interrupt : out std_logic
  );

  attribute MAX_FANOUT : string;
  attribute SIGIS : string;
  attribute MAX_FANOUT of CLK       : signal is "10000";
  attribute MAX_FANOUT of RST_N       : signal is "10000";
  attribute SIGIS of CLK       : signal is "Clk";
  attribute SIGIS of RST_N       : signal is "Rst";

%(axi_master_clocks)s
%(axi_slave_clocks)s
%(hdmi_clocks)s
end entity %(dut)s;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of %(dut)s is

%(axi_master_signals)s
%(axi_slave_signals)s
%(hdmi_signals)s

begin

  %(Dut)sIMPLEMENTATION : entity mk%(Dut)sWrapper
    port map (
      %(dut_hdmi_clock_arg)s
      CLK => CLK,
      RST_N  => RST_N,
      %(axi_master_port_map)s
      %(axi_slave_port_map)s
      %(hdmi_port_map)s

      interrupt => interrupt
      );

%(axi_master_scheduler)s
%(axi_slave_scheduler)s
%(hdmi_iobufs)s
end IMP;
'''

axi_master_parameter_vhd_template='''
    C_%(BUSNAME)s_DATA_WIDTH             : integer              := %(datawidth)s;
    C_%(BUSNAME)s_ADDR_WIDTH             : integer              := 32;
    C_%(BUSNAME)s_BURSTLEN_WIDTH         : integer              := %(burstlenwidth)s;
    C_%(BUSNAME)s_PROT_WIDTH             : integer              := %(protwidth)s;
    C_%(BUSNAME)s_CACHE_WIDTH            : integer              := %(cachewidth)s;
    C_%(BUSNAME)s_ID_WIDTH               : integer              := 1;
'''

axi_slave_parameter_vhd_template='''
    C_%(BUSNAME)s_DATA_WIDTH             : integer              := 32;
    C_%(BUSNAME)s_ADDR_WIDTH             : integer              := 32;
    C_%(BUSNAME)s_ID_WIDTH               : integer              := 4;
    C_%(BUSNAME)s_MEM0_BASEADDR          : std_logic_vector     := X"FFFFFFFF";
    C_%(BUSNAME)s_MEM0_HIGHADDR          : std_logic_vector     := X"00000000";
'''

axi_master_port_vhd_template='''
    %(busname)s_aclk                     : in  std_logic;
    %(busname)s_aresetn                  : in  std_logic;
    %(busname)s_arready                  : in  std_logic;
    %(busname)s_arvalid                  : out std_logic;
    %(busname)s_arid                     : out std_logic_vector(C_%(busname)s_ID_WIDTH-1 downto 0);
    %(busname)s_araddr                   : out std_logic_vector(C_%(busname)s_ADDR_WIDTH-1 downto 0);
    %(busname)s_arlen                    : out std_logic_vector(C_%(busname)s_BURSTLEN_WIDTH-1 downto 0);
    %(busname)s_arsize                   : out std_logic_vector(2 downto 0);
    %(busname)s_arburst                  : out std_logic_vector(1 downto 0);
    %(busname)s_arprot                   : out std_logic_vector((C_%(BUSNAME)s_PROT_WIDTH-1) downto 0);
    %(busname)s_arcache                  : out std_logic_vector((C_%(BUSNAME)s_CACHE_WIDTH-1) downto 0);
    %(busname)s_rready                   : out std_logic;
    %(busname)s_rvalid                   : in  std_logic;
    %(busname)s_rid                      : in  std_logic_vector(C_%(busname)s_ID_WIDTH-1 downto 0);
    %(busname)s_rdata                    : in  std_logic_vector(C_%(busname)s_DATA_WIDTH-1 downto 0);
    %(busname)s_rresp                    : in  std_logic_vector(1 downto 0);
    %(busname)s_rlast                    : in  std_logic;
    %(busname)s_awready                  : in  std_logic;
    %(busname)s_awvalid                  : out std_logic;
    %(busname)s_awid                     : out std_logic_vector(C_%(busname)s_ID_WIDTH-1 downto 0);
    %(busname)s_awaddr                   : out std_logic_vector(C_%(busname)s_ADDR_WIDTH-1 downto 0);
    %(busname)s_awlen                    : out std_logic_vector(C_%(busname)s_BURSTLEN_WIDTH-1 downto 0);
    %(busname)s_awsize                   : out std_logic_vector(2 downto 0);
    %(busname)s_awburst                  : out std_logic_vector(1 downto 0);
    %(busname)s_awprot                   : out std_logic_vector((C_%(BUSNAME)s_PROT_WIDTH-1) downto 0);
    %(busname)s_awcache                  : out std_logic_vector((C_%(BUSNAME)s_CACHE_WIDTH-1) downto 0);
    %(busname)s_wready                   : in  std_logic;
    %(busname)s_wvalid                   : out std_logic;
    %(busname)s_wdata                    : out std_logic_vector(C_%(busname)s_DATA_WIDTH-1 downto 0);
    %(busname)s_wstrb                    : out std_logic_vector((C_%(busname)s_DATA_WIDTH)/8 - 1 downto 0);
    %(busname)s_wlast                    : out std_logic;
    %(busname)s_bready                   : out std_logic;
    %(busname)s_bid                      : in std_logic_vector(C_%(busname)s_ID_WIDTH-1 downto 0);
    %(busname)s_bvalid                   : in  std_logic;
    %(busname)s_bresp                    : in  std_logic_vector(1 downto 0);
'''

axi_slave_port_vhd_template='''
    %(BUSNAME)s_ACLK                     : in  std_logic;
    %(BUSNAME)s_ARESETN                  : in  std_logic;
    %(BUSNAME)s_AWADDR                   : in  std_logic_vector(C_%(BUSNAME)s_ADDR_WIDTH-1 downto 0);
    %(BUSNAME)s_AWVALID                  : in  std_logic;
    %(BUSNAME)s_WDATA                    : in  std_logic_vector(C_%(BUSNAME)s_DATA_WIDTH-1 downto 0);
    %(BUSNAME)s_WSTRB                    : in  std_logic_vector((C_%(BUSNAME)s_DATA_WIDTH/8)-1 downto 0);
    %(BUSNAME)s_WVALID                   : in  std_logic;
    %(BUSNAME)s_BREADY                   : in  std_logic;
    %(BUSNAME)s_ARADDR                   : in  std_logic_vector(C_%(BUSNAME)s_ADDR_WIDTH-1 downto 0);
    %(BUSNAME)s_ARVALID                  : in  std_logic;
    %(BUSNAME)s_RREADY                   : in  std_logic;
    %(BUSNAME)s_ARREADY                  : out std_logic;
    %(BUSNAME)s_RDATA                    : out std_logic_vector(C_%(BUSNAME)s_DATA_WIDTH-1 downto 0);
    %(BUSNAME)s_RRESP                    : out std_logic_vector(1 downto 0);
    %(BUSNAME)s_RVALID                   : out std_logic;
    %(BUSNAME)s_WREADY                   : out std_logic;
    %(BUSNAME)s_BRESP                    : out std_logic_vector(1 downto 0);
    %(BUSNAME)s_BVALID                   : out std_logic;
    %(BUSNAME)s_AWREADY                  : out std_logic;
    %(BUSNAME)s_AWID                     : in  std_logic_vector(C_%(BUSNAME)s_ID_WIDTH-1 downto 0);
    %(BUSNAME)s_AWLEN                    : in  std_logic_vector(7 downto 0);
    %(BUSNAME)s_AWSIZE                   : in  std_logic_vector(2 downto 0);
    %(BUSNAME)s_AWBURST                  : in  std_logic_vector(1 downto 0);
    %(BUSNAME)s_AWLOCK                   : in  std_logic;
    %(BUSNAME)s_AWCACHE                  : in  std_logic_vector(3 downto 0);
    %(BUSNAME)s_AWPROT                   : in  std_logic_vector(2 downto 0);
    %(BUSNAME)s_WLAST                    : in  std_logic;
    %(BUSNAME)s_BID                      : out std_logic_vector(C_%(BUSNAME)s_ID_WIDTH-1 downto 0);
    %(BUSNAME)s_ARID                     : in  std_logic_vector(C_%(BUSNAME)s_ID_WIDTH-1 downto 0);
    %(BUSNAME)s_ARLEN                    : in  std_logic_vector(7 downto 0);
    %(BUSNAME)s_ARSIZE                   : in  std_logic_vector(2 downto 0);
    %(BUSNAME)s_ARBURST                  : in  std_logic_vector(1 downto 0);
    %(BUSNAME)s_ARLOCK                   : in  std_logic;
    %(BUSNAME)s_ARCACHE                  : in  std_logic_vector(3 downto 0);
    %(BUSNAME)s_ARPROT                   : in  std_logic_vector(2 downto 0);
    %(BUSNAME)s_RID                      : out std_logic_vector(C_%(BUSNAME)s_ID_WIDTH-1 downto 0);
    %(BUSNAME)s_RLAST                    : out std_logic;
'''

hdmi_port_vhd_template='''
    usr_clk_p : in std_logic;
    usr_clk_n : in std_logic;
    hdmi_clk : out std_logic;
    hdmi_vsync : out std_logic;
    hdmi_hsync : out std_logic;
    hdmi_de : out std_logic;
    hdmi_data : out std_logic_vector(15 downto 0);
'''

axi_clock_vhd_template='''
  attribute MAX_FANOUT of %(BUSNAME)s_ACLK       : signal is "10000";
  attribute MAX_FANOUT of %(BUSNAME)s_ARESETN       : signal is "10000";
  attribute SIGIS of %(BUSNAME)s_ACLK       : signal is "Clk";
  attribute SIGIS of %(BUSNAME)s_ARESETN       : signal is "Rst";
'''

hdmi_clock_vhd_template='''
  attribute SIGIS of hdmi_clk : signal is "Clk";
'''

axi_master_port_map_vhd_template='''
      EN_%(busname)s_write_writeAddr => WILL_FIRE_%(busname)s_write_writeAddr,
      %(busname)s_write_writeAddr => %(busname)s_awaddr,
      %(busname)s_write_writeId => %(busname)s_awid(0),
      RDY_%(busname)s_write_writeAddr => RDY_%(busname)s_write_writeAddr,

      %(busname)s_write_writeBurstLen => %(busname)s_awlen,
      -- RDY_%(busname)s_write_writeBurstLen,

      %(busname)s_write_writeBurstWidth => %(busname)s_awsize,
      -- RDY_%(busname)s_write_writeBurstWidth,

      %(busname)s_write_writeBurstType => %(busname)s_awburst,
      -- RDY_%(busname)s_write_writeBurstType,

      %(busname)s_write_writeBurstProt => %(busname)s_awprot,
      -- RDY_%(busname)s_write_writeBurstProt,

      %(busname)s_write_writeBurstCache => %(busname)s_awcache,
      -- RDY_%(busname)s_write_writeBurstCache,

      EN_%(busname)s_write_writeData => WILL_FIRE_%(busname)s_write_writeData,
      %(busname)s_write_writeData => %(busname)s_wdata,
      RDY_%(busname)s_write_writeData => RDY_%(busname)s_write_writeData,

      %(busname)s_write_writeDataByteEnable => %(busname)s_wstrb,
      -- RDY_%(busname)s_write_writeDataByteEnable,

      %(busname)s_write_writeLastDataBeat => %(busname)s_wlast,
      -- RDY_%(busname)s_write_writeLastDataBeat,

      EN_%(busname)s_write_writeResponse => WILL_FIRE_%(busname)s_write_writeResponse,
      %(busname)s_write_writeResponse_responseCode => %(busname)s_bresp,
      %(busname)s_write_writeResponse_id => %(busname)s_bid(0),
      RDY_%(busname)s_write_writeResponse => RDY_%(busname)s_write_writeResponse,

      EN_%(busname)s_read_readAddr => WILL_FIRE_%(busname)s_read_readAddr,
      %(busname)s_read_readId => %(busname)s_arid(0),
      %(busname)s_read_readAddr => %(busname)s_araddr,
      RDY_%(busname)s_read_readAddr => RDY_%(busname)s_read_readAddr,

      %(busname)s_read_readBurstLen => %(busname)s_arlen,
      -- RDY_%(busname)s_read_readBurstLen,

      %(busname)s_read_readBurstWidth => %(busname)s_arsize,
      -- RDY_%(busname)s_read_readBurstWidth,

      %(busname)s_read_readBurstType => %(busname)s_arburst,
      -- RDY_%(busname)s_read_readBurstType,

      %(busname)s_read_readBurstProt => %(busname)s_arprot,
      -- RDY_%(busname)s_read_readBurstProt,

      %(busname)s_read_readBurstCache => %(busname)s_arcache,
      -- RDY_%(busname)s_read_readBurstCache,

      %(busname)s_read_readData_data => %(busname)s_rdata,
      %(busname)s_read_readData_resp => %(busname)s_rresp,
      %(busname)s_read_readData_last => %(busname)s_rlast,
      %(busname)s_read_readData_id => %(busname)s_rid(0),
      EN_%(busname)s_read_readData => WILL_FIRE_%(busname)s_read_readData,
      RDY_%(busname)s_read_readData => RDY_%(busname)s_read_readData,
'''

axi_slave_port_map_vhd_template='''
      %(busname)s_read_readAddr_addr => %(BUSNAME)s_ARADDR,
      %(busname)s_read_readAddr_burstLen => %(BUSNAME)s_ARLEN,
      %(busname)s_read_readAddr_burstWidth => %(BUSNAME)s_ARSIZE,
      %(busname)s_read_readAddr_burstType => %(BUSNAME)s_ARBURST,
      %(busname)s_read_readAddr_burstProt => %(BUSNAME)s_ARPROT,
      %(busname)s_read_readAddr_burstCache => %(BUSNAME)s_ARCACHE,
      EN_%(busname)s_read_readAddr => EN_%(busname)s_read_readAddr,
      RDY_%(busname)s_read_readAddr => RDY_%(busname)s_read_readAddr,

      %(busname)s_read_last => %(busname)s_read_last,
      EN_%(busname)s_read_readData => EN_%(busname)s_read_readData,
      %(busname)s_read_readData => %(busname)s_read_readData,
      RDY_%(busname)s_read_readData => RDY_%(busname)s_read_readData,

      %(busname)s_write_writeAddr_addr => %(BUSNAME)s_AWADDR,
      %(busname)s_write_writeAddr_burstLen => %(BUSNAME)s_AWLEN,
      %(busname)s_write_writeAddr_burstWidth => %(BUSNAME)s_AWSIZE,
      %(busname)s_write_writeAddr_burstType => %(BUSNAME)s_AWBURST,
      %(busname)s_write_writeAddr_burstProt => %(BUSNAME)s_AWPROT,
      %(busname)s_write_writeAddr_burstCache => %(BUSNAME)s_AWCACHE,
      EN_%(busname)s_write_writeAddr => EN_%(busname)s_write_writeAddr,
      RDY_%(busname)s_write_writeAddr => RDY_%(busname)s_write_writeAddr,

      %(busname)s_write_writeData_data => %(BUSNAME)s_WDATA,
      %(busname)s_write_writeData_byteEnable => %(BUSNAME)s_WSTRB,
      %(busname)s_write_writeData_last => %(BUSNAME)s_WLAST,
      EN_%(busname)s_write_writeData => EN_%(busname)s_write_writeData,
      RDY_%(busname)s_write_writeData => RDY_%(busname)s_write_writeData,

      EN_%(busname)s_write_writeResponse => EN_%(busname)s_write_writeResponse,
      RDY_%(busname)s_write_writeResponse => RDY_%(busname)s_write_writeResponse,
      %(busname)s_write_writeResponse => %(busname)s_write_writeResponse,
'''

hdmi_port_map_vhd_template='''
      %(busname)s_hdmi_vsync => hdmi_vsync_unbuf,
      %(busname)s_hdmi_hsync => hdmi_hsync_unbuf,
      %(busname)s_hdmi_de => hdmi_de_unbuf,
      %(busname)s_hdmi_data => hdmi_data_unbuf,
'''

axi_master_signal_vhd_template='''
  signal RDY_%(busname)s_write_writeAddr : std_logic;
  signal RDY_%(busname)s_write_writeData : std_logic;
  signal RDY_%(busname)s_write_writeResponse : std_logic;
  signal RDY_%(busname)s_read_readAddr : std_logic;
  signal RDY_%(busname)s_read_readData : std_logic;
  signal WILL_FIRE_%(busname)s_write_writeAddr : std_logic;
  signal WILL_FIRE_%(busname)s_write_writeData : std_logic;
  signal WILL_FIRE_%(busname)s_write_writeResponse : std_logic;
  signal WILL_FIRE_%(busname)s_read_readAddr : std_logic;
  signal WILL_FIRE_%(busname)s_read_readData : std_logic;
'''

axi_slave_signal_vhd_template='''
  signal %(busname)s_mem0_araddr_matches : boolean;
  signal %(busname)s_mem0_awaddr_matches : boolean;

  signal %(busname)s_read_readData : std_logic_vector(C_%(BUSNAME)s_DATA_WIDTH-1 downto 0);
  signal %(busname)s_write_writeResponse : std_logic_vector(1 downto 0);

  signal EN_%(busname)s_read_readAddr : std_logic;
  signal RDY_%(busname)s_read_readAddr : std_logic;
  signal EN_%(busname)s_read_readData : std_logic;
  signal RDY_%(busname)s_read_readData : std_logic;
  signal EN_%(busname)s_write_writeAddr : std_logic;
  signal RDY_%(busname)s_write_writeAddr : std_logic;
  signal EN_%(busname)s_write_writeData : std_logic;
  signal RDY_%(busname)s_write_writeData : std_logic;
  signal EN_%(busname)s_write_writeResponse : std_logic;
  signal RDY_%(busname)s_write_writeResponse : std_logic;
  signal %(busname)s_read_last : std_logic;
'''

hdmi_signal_vhd_template='''
  signal usr_clk : std_logic;
  attribute MAX_FANOUT of usr_clk : signal is "10000";
  attribute SIGIS of usr_clk      : signal is "CLK";
  signal %(busname)s_vsync_unbuf, %(busname)s_hsync_unbuf, %(busname)s_de_unbuf : std_logic;
  signal %(busname)s_data_unbuf : std_logic_vector(15 downto 0);
'''

axi_master_scheduler_vhd_template='''
  WILL_FIRE_%(busname)s_read_readAddr <= (%(busname)s_arready and RDY_%(busname)s_read_readAddr);
  WILL_FIRE_%(busname)s_read_readData <= (%(busname)s_rvalid and RDY_%(busname)s_read_readData);
  %(busname)s_arvalid <= RDY_%(busname)s_read_readAddr;
  %(busname)s_rready <= RDY_%(busname)s_read_readData;

  WILL_FIRE_%(busname)s_write_writeAddr <= (%(busname)s_awready and RDY_%(busname)s_write_writeAddr);
  WILL_FIRE_%(busname)s_write_writeData <= (%(busname)s_wready and RDY_%(busname)s_write_writeData);
  WILL_FIRE_%(busname)s_write_writeResponse <= (%(busname)s_bvalid and RDY_%(busname)s_write_writeResponse);
  %(busname)s_awvalid <= RDY_%(busname)s_write_writeAddr;
  %(busname)s_wvalid <= RDY_%(busname)s_write_writeData;
  %(busname)s_bready <= RDY_%(busname)s_write_writeResponse;
'''

axi_slave_scheduler_vhd_template='''
  %(busname)s_mem0_araddr_matches <= (%(BUSNAME)s_ARADDR >= C_%(BUSNAME)s_MEM0_BASEADDR and %(BUSNAME)s_ARADDR <= C_%(BUSNAME)s_MEM0_HIGHADDR);
  %(busname)s_mem0_awaddr_matches <= (%(BUSNAME)s_AWADDR >= C_%(BUSNAME)s_MEM0_BASEADDR and %(BUSNAME)s_AWADDR <= C_%(BUSNAME)s_MEM0_HIGHADDR);

  %(BUSNAME)s_ARREADY  <= RDY_%(busname)s_read_readAddr when %(busname)s_mem0_araddr_matches else '0';
  %(BUSNAME)s_RVALID <= EN_%(busname)s_read_readData;
  %(BUSNAME)s_RRESP  <= "00";

  %(BUSNAME)s_RDATA  <= %(busname)s_read_readData when EN_%(busname)s_read_readData = '1' else (others => '0');
  %(BUSNAME)s_RLAST  <= %(busname)s_read_last when EN_%(busname)s_read_readData = '1' else '0';


  %(BUSNAME)s_RID <= (others => '0');
  %(BUSNAME)s_BID <= (others => '0');
  %(BUSNAME)s_AWREADY  <= RDY_%(busname)s_write_writeAddr when %(busname)s_mem0_awaddr_matches else '0';
  %(BUSNAME)s_WREADY <= RDY_%(busname)s_write_writeData;
  %(BUSNAME)s_BVALID  <= EN_%(busname)s_write_writeResponse;
  %(BUSNAME)s_BRESP <= %(busname)s_write_writeResponse when EN_%(busname)s_write_writeResponse = '1' else
                 (others => '0');

  EN_%(busname)s_read_readAddr <= RDY_%(busname)s_read_readAddr and %(BUSNAME)s_ARVALID when %(busname)s_mem0_araddr_matches else '0';
  EN_%(busname)s_read_readData <= RDY_%(busname)s_read_readData and %(BUSNAME)s_RREADY;

  EN_%(busname)s_write_writeAddr <= RDY_%(busname)s_write_writeAddr and %(BUSNAME)s_AWVALID when %(busname)s_mem0_awaddr_matches else '0';
  EN_%(busname)s_write_writeData <= RDY_%(busname)s_write_writeData and %(BUSNAME)s_WVALID;
  EN_%(busname)s_write_writeResponse <= RDY_%(busname)s_write_writeResponse and %(BUSNAME)s_BREADY;
'''

hdmi_iobuf_vhd_template='''
    IBUFGDS_usr_clk : IBUFGDS
    generic map (
    DIFF_TERM => FALSE,
    IBUF_LOW_PWR => TRUE,
    IOSTANDARD => "DEFAULT")
    port map (
    O => usr_clk,
    -- Buffer output (connect directly to top-level port)
    I => usr_clk_p,
    IB => usr_clk_n
    -- Buffer input
    );

    OBUF_%(busname)s_clk : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_clk,
    -- Buffer output (connect directly to top-level port)
    I => usr_clk
    -- Buffer input
    );

    OBUF_hsync : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_hsync,
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_hsync_unbuf
    -- Buffer input
    );
    OBUF_vsync : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_vsync,
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_vsync_unbuf
    -- Buffer input
    );
    OBUF_de : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_de,
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_de_unbuf
    -- Buffer input
    );

    OBUF_data_0 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(0),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(0)
    -- Buffer input
    );
    OBUF_data_1 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(1),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(1)
    -- Buffer input
    );
    OBUF_data_2 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(2),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(2)
    -- Buffer input
    );
    OBUF_data_3 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(3),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(3)
    -- Buffer input
    );
    OBUF_data_4 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(4),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(4)
    -- Buffer input
    );
    OBUF_data_5 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(5),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(5)
    -- Buffer input
    );
    OBUF_data_6 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(6),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(6)
    -- Buffer input
    );
    OBUF_data_7 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(7),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(7)
    -- Buffer input
    );
    OBUF_data_8 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(8),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(8)
    -- Buffer input
    );
    OBUF_data_9 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(9),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(9)
    -- Buffer input
    );
    OBUF_data_10 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(10),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(10)
    -- Buffer input
    );
    OBUF_data_11 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(11),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(11)
    -- Buffer input
    );
    OBUF_data_12 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(12),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(12)
    -- Buffer input
    );
    OBUF_data_13 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(13),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(13)
    -- Buffer input
    );
    OBUF_data_14 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(14),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(14)
    -- Buffer input
    );
    OBUF_data_15 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => %(busname)s_data(15),
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_data_unbuf(15)
    -- Buffer input
    );

    OBUF_xadc_gpio_0 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => xadc_gpio_0,
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_vsync_unbuf
    -- Buffer input
    );
    OBUF_xadc_gpio_1 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => xadc_gpio_1,
    -- Buffer output (connect directly to top-level port)
    I => WILL_FIRE_m_axi_read_readAddr
    -- Buffer input
    );
    OBUF_xadc_gpio_2 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => xadc_gpio_2,
    -- Buffer output (connect directly to top-level port)
    I => WILL_FIRE_m_axi_read_readData
    -- Buffer input
    );
    OBUF_xadc_gpio_3 : OBUF
    generic map (
    DRIVE => 12,
    IOSTANDARD => "LVCMOS25",
    SLEW => "SLOW")
    port map (
    O => xadc_gpio_3,
    -- Buffer output (connect directly to top-level port)
    I => %(busname)s_de_unbuf
    -- Buffer input
    );

'''

class InterfaceMixin:
    def axiMasterBusSubst(self, busname,t,params):
        print 'bustype: ', t, ('AXI4' if (t == 'AxiMaster') else 'AXI3'), params[0].numeric()
        return {
            'BUSNAME': busname.upper(),
            'busname': busname,
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
        axiMasters = self.collectInterfaceNames('Axi3?Master')
        axiSlaves = [('ctrl','AxiSlave',[]), ('fifo','AxiSlave',[])] + self.collectInterfaceNames('AxiSlave')
        hdmiBus = self.collectInterfaceNames('HDMI')
        masterBusSubsts = [ self.axiMasterBusSubst(busname,t,params) for (busname,t,params) in axiMasters ]
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
        axiMasters = self.collectInterfaceNames('Axi3?Master')
        axiSlaves = [('ctrl','AxiSlave',[]), ('fifo','AxiSlave',[])] + self.collectInterfaceNames('AxiSlave')
        hdmiBus = self.collectInterfaceNames('HDMI')
        masterBusSubsts = [ self.axiMasterBusSubst(busname,t,params) for (busname,t,params) in axiMasters ]
        substs = {
            'dut': dutName,
            'axi_master_interconnects': ''.join([ axi_master_interconnect_mhs_template 
                                                  % {'busnumber': i} for i in range(len(axiMasters))]),
            'axi_slave_interconnects': (axi_slave_interconnect_mhs_template 
                                        % {'busnumber': 0}),
            'dut_axi_master_config': ''.join([ dut_axi_master_config_mhs_template
                                               % {'busnumber': i, 'busname': axiMasters[i][0]}
                                               for i in range(len(axiMasters))]),
            'dut_axi_slave_config': ''.join([ dut_axi_slave_config_mhs_template
                                              % {'busnumber': 0, 
                                                 'busname': axiSlaves[i][0],
                                                 'BUSNAME': axiSlaves[i][0].upper(),
                                                 'busbase': hex(0x6e400000 + 4096*i),
                                                 'bushigh': hex(0x6e400FFF + 4096*i)}
                                              for i in range(len(axiSlaves))]),
            'ps7_axi_master_config': ''.join([ ps7_axi_master_config_mhs_template
                                               % {'dut': dutName,
                                                  'busnumber': i,
                                                  'busname': axiMasters[i][0],
                                                  'BUSNAME': axiMasters[i][0].upper()}
                                               for i in range(len(axiMasters))]),
            'dut_hdmi_config': ''.join([ dut_hdmi_config_mhs_template % {'dut':dutName} for v in hdmiBus]),
            'system_hdmi_ports': ''.join([system_hdmi_port_mhs_template % {'dut':dutName} for v in hdmiBus])
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

    def writeVhd(self, vhdname, silent=False):
        if not silent:
            print 'Writing wrapper VHDL file', vhdname
        vhd = util.createDirAndOpen(vhdname, 'w')
        dutName = util.decapitalize(self.name)
        axiMasters = self.collectInterfaceNames('Axi3?Master')
        axiSlaves = [('ctrl','AxiSlave',[]), ('fifo','AxiSlave',[])] + self.collectInterfaceNames('AxiSlave')
        hdmiBus = self.collectInterfaceNames('HDMI')
        masterBusSubsts = [ self.axiMasterBusSubst(busname,t,params) for (busname,t,params) in axiMasters ]
        substs = {
            'dut': dutName,
            'Dut': util.capitalize(self.name),
            'axi_master_parameters':
                ''.join([axi_master_parameter_vhd_template % subst for subst in masterBusSubsts]),
            'axi_slave_parameters':
                ''.join([axi_slave_parameter_vhd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            'axi_master_ports':
                ''.join([axi_master_port_vhd_template % subst for subst in masterBusSubsts]),
            'axi_slave_ports':
                ''.join([axi_slave_port_vhd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            'hdmi_ports':
                ''.join([hdmi_port_vhd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in hdmiBus]),
            'dut_hdmi_clock_arg': '      CLK_hdmi_clk => usr_clk,' if len(hdmiBus) else '',
            'axi_master_port_map':
                ''.join([axi_master_port_map_vhd_template % subst for subst in masterBusSubsts]),
            'axi_slave_port_map':
                ''.join([axi_slave_port_map_vhd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            'hdmi_port_map':
                ''.join([hdmi_port_map_vhd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in hdmiBus]),
            'axi_master_clocks':
                ''.join([axi_clock_vhd_template % subst for subst in masterBusSubsts]),
            'axi_slave_clocks':
                ''.join([axi_clock_vhd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            'hdmi_clocks':
                ''.join([hdmi_clock_vhd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in hdmiBus]),
            'iobufs': '',
            'axi_master_signals':
                ''.join([axi_master_signal_vhd_template % subst for subst in masterBusSubsts]),
            'axi_slave_signals':
                ''.join([axi_slave_signal_vhd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            'hdmi_signals':
                ''.join([hdmi_signal_vhd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in hdmiBus]),
            'axi_master_scheduler':
                ''.join([axi_master_scheduler_vhd_template % subst for subst in masterBusSubsts ]),
            'axi_slave_scheduler':
                ''.join([axi_slave_scheduler_vhd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in axiSlaves]),
            'hdmi_iobufs':
                ''.join([hdmi_iobuf_vhd_template % {'BUSNAME': busname.upper(), 'busname': busname}
                         for (busname,t,params) in hdmiBus]),
            }
        vhd.write(vhd_template % substs)
        vhd.close()
        return

    def writeUcf(self, ucfname, silent=False):
        if not silent:
            print 'Writing UCF file', ucfname
        ucf = util.createDirAndOpen(ucfname, 'w')
        dutName = util.decapitalize(self.name)
        hdmiBus = self.collectInterfaceNames('HDMI')
        if len(hdmiBus):
            ucf.write(hdmi_ucf_template)
            ucf.write(usr_clk_ucf_template)
            ucf.write(xadc_ucf_template)
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
