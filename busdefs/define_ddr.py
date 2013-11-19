#

class Register:
    def __init__(self, busHandlers):
        busHandlers['DDR'] = self
    def top_bus_ports(self, busname,t,params):
        return '''    inout [14:0]DDR_Addr,
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
'''
    def top_bus_wires(self, busname,t,params):
        return '''
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
  wire GND_1;
GND GND
       (.G(GND_1));
'''
    def ps7_bus_port_map(self,busname,t,params):
        return '''
        .DDR_Addr(DDR_Addr[14:0]),
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
        .PS_PORB(FIXED_IO_ps_porb),
        .PS_SRSTB(FIXED_IO_ps_srstb),
'''
    def dut_bus_port_map(self, busname,t,params):
        return '''
      .CLK(processing_system7_1_fclk_clk0),
      .RST_N(processing_system7_1_fclk_reset0_n),
''' % {'busname': busname}
    def top_bus_assignments(self,busname,t,params):
        return '''
'''
    def bus_assignments(self,busname,t,params):
        return ''
    def pinout(self, board):
        return []
