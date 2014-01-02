
`timescale 1 ps / 1 ps
// lib IP_Integrator_Lib
(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLanguage=VERILOG}" *) 
module ztop_1(
    inout [14:0]DDR_Addr,
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

    output [7:0] GPIO_leds
);


parameter C_M_AXI_DATA_WIDTH = 64;
parameter C_M_AXI_ADDR_WIDTH = 32;
parameter C_M_AXI_BURSTLEN_WIDTH = 4;
parameter C_M_AXI_PROT_WIDTH = 2;
parameter C_M_AXI_CACHE_WIDTH = 3;
parameter C_M_AXI_ID_WIDTH = 6;


parameter C_CTRL_DATA_WIDTH = 32;
parameter C_CTRL_ADDR_WIDTH = 32;
parameter C_CTRL_ID_WIDTH = 12;
parameter C_CTRL_MEM0_BASEADDR = 32'h6e400000;
parameter C_CTRL_MEM0_HIGHADDR = 32'h6e4fffff;

parameter C_FAMILY = "virtex6";

  wire interrupt;

  wire [C_M_AXI_DATA_WIDTH-1:0]m_axi_rdata;
  wire [C_M_AXI_DATA_WIDTH-1:0]m_axi_wdata;
  wire [C_M_AXI_DATA_WIDTH-1 : 0] m_axi_wdata_wire;
  wire [(C_M_AXI_DATA_WIDTH/8)-1:0]m_axi_wstrb;
  wire RDY_m_axi_write_writeAddr;
  wire RDY_m_axi_write_writeData;
  wire RDY_m_axi_write_writeResponse;
  wire RDY_m_axi_read_readAddr;
  wire RDY_m_axi_read_readData;
  wire WILL_FIRE_m_axi_write_writeAddr;
  wire WILL_FIRE_m_axi_write_writeData;
  wire WILL_FIRE_m_axi_write_writeResponse;
  wire WILL_FIRE_m_axi_read_readAddr;
  wire WILL_FIRE_m_axi_read_readData;
  wire [31:0]m_axi_araddr;
  wire [1:0]m_axi_arburst;
  wire [3:0]m_axi_arcache;
  wire [5:0]m_axi_arid;
  wire [3:0]m_axi_arlen;
  wire [2:0]m_axi_arprot;
  wire m_axi_arready;
  wire [2:0]m_axi_arsize;
  wire m_axi_arvalid;
  wire [31:0]m_axi_awaddr;
  wire [1:0]m_axi_awburst;
  wire [3:0]m_axi_awcache;
  wire [5:0]m_axi_awid;
  wire [3:0]m_axi_awlen;
  wire [2:0]m_axi_awprot;
  wire m_axi_awready;
  wire [2:0]m_axi_awsize;
  wire m_axi_awvalid;
  wire [5:0]m_axi_bid;
  wire m_axi_bready;
  wire [1:0]m_axi_bresp;
  wire m_axi_bvalid;
  wire [5:0]m_axi_rid;
  wire m_axi_rlast;
  wire m_axi_rready;
  wire [1:0]m_axi_rresp;
  wire m_axi_rvalid;
  wire [5:0]m_axi_wid;
  wire m_axi_wlast;
  wire m_axi_wready;
  wire m_axi_wvalid;


  wire [1:0]ctrl_arlock;
  wire [1:0]ctrl_awlock;
  wire ctrl_mem0_araddr_matches;
  wire ctrl_mem0_awaddr_matches;
  wire [C_CTRL_DATA_WIDTH-1 : 0] ctrl_read_readData;
  wire [1 : 0] ctrl_write_writeResponse;
  wire EN_ctrl_read_readAddr;
  wire RDY_ctrl_read_readAddr;
  wire EN_ctrl_read_readData;
  wire RDY_ctrl_read_readData;
  wire EN_ctrl_write_writeAddr;
  wire RDY_ctrl_write_writeAddr;
  wire EN_ctrl_write_writeData;
  wire RDY_ctrl_write_writeData;
  wire EN_ctrl_write_writeResponse;
  wire RDY_ctrl_write_writeResponse;
  wire RDY_ctrl_write_bid;
  wire [31:0]ctrl_araddr;
  wire [1:0]ctrl_arburst;
  wire [3:0]ctrl_arcache;
  wire [11:0]ctrl_arid;
  wire [3:0]ctrl_arlen;
  wire [2:0]ctrl_arprot;
  wire ctrl_arready;
  wire [2:0]ctrl_arsize;
  wire ctrl_arvalid;
  wire [31:0]ctrl_awaddr;
  wire [1:0]ctrl_awburst;
  wire [3:0]ctrl_awcache;
  wire [11:0]ctrl_awid;
  wire [3:0]ctrl_awlen;
  wire [2:0]ctrl_awprot;
  wire ctrl_awready;
  wire [2:0]ctrl_awsize;
  wire ctrl_awvalid;
  wire [11:0]ctrl_bid;
  wire ctrl_bready;
  wire [1:0]ctrl_bresp;
  wire ctrl_bvalid;
  wire [31:0]ctrl_rdata;
  wire [11:0]ctrl_rid;
  wire ctrl_rlast;
  wire ctrl_rready;
  wire [1:0]ctrl_rresp;
  wire ctrl_rvalid;
  wire [31:0]ctrl_wdata;
  wire [11:0]ctrl_wid;
  wire ctrl_wlast;
  wire ctrl_wready;
  wire [3:0]ctrl_wstrb;
  wire ctrl_wvalid;


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


/* dut goes here */
mkZynqTop dutIMPLEMENTATION (
        .CLK_axi_clock(processing_system7_1_fclk_clk0),
	.ddr_arb_v(0),
	.CLK_fclk_clk0(processing_system7_1_fclk_clk0),
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
        .MIO(FIXED_IO_mio[53:0]),
        .PS_PORB(FIXED_IO_ps_porb),
        .PS_SRSTB(FIXED_IO_ps_srstb),
        .PS_CLK(FIXED_IO_ps_clk));
      .CLK(processing_system7_1_fclk_clk0),
      .RST_N(processing_system7_1_fclk_reset0_n),
      .leds_leds(GPIO_leds)
      );


assign WILL_FIRE_m_axi_read_readAddr = (m_axi_arready & RDY_m_axi_read_readAddr);
assign WILL_FIRE_m_axi_read_readData = (m_axi_rvalid & RDY_m_axi_read_readData);
assign m_axi_arvalid = RDY_m_axi_read_readAddr;
assign m_axi_rready = RDY_m_axi_read_readData;

assign WILL_FIRE_m_axi_write_writeAddr = (m_axi_awready & RDY_m_axi_write_writeAddr);
assign WILL_FIRE_m_axi_write_writeData = (m_axi_wready & RDY_m_axi_write_writeData);
assign WILL_FIRE_m_axi_write_writeResponse = (m_axi_bvalid & RDY_m_axi_write_writeResponse);
assign m_axi_awvalid = RDY_m_axi_write_writeAddr;
assign m_axi_wvalid = RDY_m_axi_write_writeData;
assign m_axi_bready = RDY_m_axi_write_writeResponse;
assign m_axi_wdata = (RDY_m_axi_write_writeData == 1) ? m_axi_wdata_wire : 32'hdeadd00d;


assign ctrl_mem0_araddr_matches = (ctrl_araddr >= C_CTRL_MEM0_BASEADDR & ctrl_araddr <= C_CTRL_MEM0_HIGHADDR);
assign ctrl_mem0_awaddr_matches = (ctrl_awaddr >= C_CTRL_MEM0_BASEADDR & ctrl_awaddr <= C_CTRL_MEM0_HIGHADDR);

assign ctrl_arready_unbuf = RDY_ctrl_read_readAddr & ctrl_arvalid & ctrl_mem0_araddr_matches;
assign ctrl_arready = ctrl_arready_unbuf;
assign ctrl_rvalid_unbuf = EN_ctrl_read_readData;
assign ctrl_rvalid = ctrl_rvalid_unbuf;
assign ctrl_rresp[1:0]  = "00";

assign ctrl_awready  = RDY_ctrl_write_writeAddr & ctrl_mem0_awaddr_matches;
assign ctrl_wready = RDY_ctrl_write_writeData;
assign ctrl_bvalid  = EN_ctrl_write_writeResponse;
assign ctrl_bresp = ctrl_write_writeResponse;

assign EN_ctrl_read_readAddr = RDY_ctrl_read_readAddr & ctrl_arvalid & ctrl_mem0_araddr_matches;
assign EN_ctrl_read_readData = RDY_ctrl_read_readData & ctrl_rready;

assign EN_ctrl_write_writeAddr = RDY_ctrl_write_writeAddr & ctrl_awvalid & ctrl_mem0_awaddr_matches;
assign EN_ctrl_write_writeData = RDY_ctrl_write_writeData & ctrl_wvalid;
assign EN_ctrl_write_writeResponse = RDY_ctrl_write_writeResponse & ctrl_bready;


endmodule
