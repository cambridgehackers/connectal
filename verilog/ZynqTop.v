
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
      
      .EN_m_axi_read_readAddr(WILL_FIRE_m_axi_read_readAddr),
      .m_axi_read_readAddr(m_axi_araddr),
      .RDY_m_axi_read_readAddr(RDY_m_axi_read_readAddr),

      .m_axi_read_readBurstLen(m_axi_arlen),
      .RDY_m_axi_read_readBurstLen(RDY_m_axi_read_readBurstLen),

      .m_axi_read_readBurstWidth(m_axi_arsize),
      .RDY_m_axi_read_readBurstWidth(RDY_m_axi_read_readBurstWidth),

      .m_axi_read_readBurstType(m_axi_arburst),
      .RDY_m_axi_read_readBurstType(RDY_m_axi_read_readBurstType),

      .m_axi_read_readBurstProt(m_axi_arprot),
      .RDY_m_axi_read_readBurstProt(RDY_m_axi_read_readBurstProt),

      .m_axi_read_readBurstCache(m_axi_arcache),
      .RDY_m_axi_read_readBurstCache(RDY_m_axi_read_readBurstCache),

      .m_axi_read_readId(m_axi_arid),
      .RDY_m_axi_read_readId(RDY_m_axi_read_readId),

      .m_axi_read_readData_data(m_axi_rdata),
      .m_axi_read_readData_resp(m_axi_rresp),
      .m_axi_read_readData_last(m_axi_rlast),
      .m_axi_read_readData_id(m_axi_rid),
      .EN_m_axi_read_readData(WILL_FIRE_m_axi_read_readData),
      .RDY_m_axi_read_readData(RDY_m_axi_read_readData),

      .EN_m_axi_write_writeAddr(WILL_FIRE_m_axi_write_writeAddr),
      .m_axi_write_writeAddr(m_axi_awaddr),
      .RDY_m_axi_write_writeAddr(RDY_m_axi_write_writeAddr),

      .m_axi_write_writeBurstLen(m_axi_awlen),
      .RDY_m_axi_write_writeBurstLen(RDY_m_axi_write_writeBurstLen),

      .m_axi_write_writeBurstWidth(m_axi_awsize),
      .RDY_m_axi_write_writeBurstWidth(RDY_m_axi_write_writeBurstWidth),

      .m_axi_write_writeBurstType(m_axi_awburst),
      .RDY_m_axi_write_writeBurstType(RDY_m_axi_write_writeBurstType),

      .m_axi_write_writeBurstProt(m_axi_awprot),
      .RDY_m_axi_write_writeBurstProt(RDY_m_axi_write_writeBurstProt),

      .m_axi_write_writeBurstCache(m_axi_awcache),
      .RDY_m_axi_write_writeBurstCache(RDY_m_axi_write_writeBurstCache),

      .m_axi_write_writeId(m_axi_awid),
      .RDY_m_axi_write_writeId(RDY_m_axi_write_writeId),

      .EN_m_axi_write_writeData(WILL_FIRE_m_axi_write_writeData),
      .m_axi_write_writeData(m_axi_wdata_wire),
      .RDY_m_axi_write_writeData(RDY_m_axi_write_writeData),

      .m_axi_write_writeWid(m_axi_wid),
      .RDY_m_axi_write_writeWid(RDY_m_axi_write_writeWid),

      .m_axi_write_writeDataByteEnable(m_axi_wstrb),
      .RDY_m_axi_write_writeDataByteEnable(RDY_m_axi_write_writeDataByteEnable),

      .m_axi_write_writeLastDataBeat(m_axi_wlast),
      .RDY_m_axi_write_writeLastDataBeat(RDY_m_axi_write_writeLastDataBeat),

      .m_axi_write_writeResponse_responseCode(m_axi_bresp),
      .m_axi_write_writeResponse_id(m_axi_bid),
      .EN_m_axi_write_writeResponse(WILL_FIRE_m_axi_write_writeResponse),
      .RDY_m_axi_write_writeResponse(RDY_m_axi_write_writeResponse),

      
      .ctrl_read_readAddr_addr(ctrl_araddr),
      .ctrl_read_readAddr_burstLen(ctrl_arlen),
      .ctrl_read_readAddr_burstWidth(ctrl_arsize),
      .ctrl_read_readAddr_burstType(ctrl_arburst),
      .ctrl_read_readAddr_burstProt(ctrl_arprot),
      .ctrl_read_readAddr_burstCache(ctrl_arcache),
      .ctrl_read_readAddr_arid(ctrl_arid),
      .EN_ctrl_read_readAddr(EN_ctrl_read_readAddr),
      .RDY_ctrl_read_readAddr(RDY_ctrl_read_readAddr),

      .ctrl_read_last(ctrl_rlast),
      .ctrl_read_rid(ctrl_rid),
      .EN_ctrl_read_readData(EN_ctrl_read_readData),
      .ctrl_read_readData(ctrl_rdata),
      .RDY_ctrl_read_readData(RDY_ctrl_read_readData),

      .ctrl_write_writeAddr_addr(ctrl_awaddr),
      .ctrl_write_writeAddr_burstLen(ctrl_awlen),
      .ctrl_write_writeAddr_burstWidth(ctrl_awsize),
      .ctrl_write_writeAddr_burstType(ctrl_awburst),
      .ctrl_write_writeAddr_burstProt(ctrl_awprot),
      .ctrl_write_writeAddr_burstCache(ctrl_awcache),
      .ctrl_write_writeAddr_awid(ctrl_awid),
      .EN_ctrl_write_writeAddr(EN_ctrl_write_writeAddr),
      .RDY_ctrl_write_writeAddr(RDY_ctrl_write_writeAddr),

      .ctrl_write_writeData_data(ctrl_wdata),
      .ctrl_write_writeData_byteEnable(ctrl_wstrb),
      .ctrl_write_writeData_last(ctrl_wlast),
      .ctrl_write_writeData_wid(ctrl_wid),
      .EN_ctrl_write_writeData(EN_ctrl_write_writeData),
      .RDY_ctrl_write_writeData(RDY_ctrl_write_writeData),

      .EN_ctrl_write_writeResponse(EN_ctrl_write_writeResponse),
      .RDY_ctrl_write_writeResponse(RDY_ctrl_write_writeResponse),
      .ctrl_write_writeResponse(ctrl_bresp),
      .EN_ctrl_write_bid(EN_ctrl_write_writeResponse),
      .RDY_ctrl_write_bid(RDY_ctrl_write_bid),
      .ctrl_write_bid(ctrl_bid),

      
      .CLK(processing_system7_1_fclk_clk0),
      .RST_N(processing_system7_1_fclk_reset0_n),

      .interrupt__read(interrupt),
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



wire [15:0] irq_f2p;
assign irq_f2p[0] = interrupt;
assign irq_f2p[1] = 0;
assign irq_f2p[2] = 0;
assign irq_f2p[3] = 0;
assign irq_f2p[4] = 0;
assign irq_f2p[5] = 0;
assign irq_f2p[6] = 0;
assign irq_f2p[7] = 0;
assign irq_f2p[8] = 0;
assign irq_f2p[9] = 0;
assign irq_f2p[10] = 0;
assign irq_f2p[11] = 0;
assign irq_f2p[12] = 0;
assign irq_f2p[13] = 0;
assign irq_f2p[14] = 0;


processing_system7#(.C_NUM_F2P_INTR_INPUTS(16))
 processing_system7_1(

        .M_AXI_GP0_ACLK(processing_system7_1_fclk_clk0),
        .M_AXI_GP0_ARLOCK(ctrl_arlock),
        .M_AXI_GP0_AWLOCK(ctrl_awlock),
        .M_AXI_GP0_ARADDR(ctrl_araddr),
        .M_AXI_GP0_ARBURST(ctrl_arburst),
        .M_AXI_GP0_ARCACHE(ctrl_arcache),
        .M_AXI_GP0_ARID(ctrl_arid),
        .M_AXI_GP0_ARLEN(ctrl_arlen),
        .M_AXI_GP0_ARPROT(ctrl_arprot),
        .M_AXI_GP0_ARREADY(ctrl_arready),
        .M_AXI_GP0_ARSIZE(ctrl_arsize),
        .M_AXI_GP0_ARVALID(ctrl_arvalid),
        .M_AXI_GP0_AWADDR(ctrl_awaddr),
        .M_AXI_GP0_AWBURST(ctrl_awburst),
        .M_AXI_GP0_AWCACHE(ctrl_awcache),
        .M_AXI_GP0_AWID(ctrl_awid),
        .M_AXI_GP0_AWLEN(ctrl_awlen),
        .M_AXI_GP0_AWPROT(ctrl_awprot),
        .M_AXI_GP0_AWREADY(ctrl_awready),
        .M_AXI_GP0_AWSIZE(ctrl_awsize),
        .M_AXI_GP0_AWVALID(ctrl_awvalid),
        .M_AXI_GP0_BID(ctrl_bid),
        .M_AXI_GP0_BREADY(ctrl_bready),
        .M_AXI_GP0_BRESP(ctrl_bresp),
        .M_AXI_GP0_BVALID(ctrl_bvalid),
        .M_AXI_GP0_RDATA(ctrl_rdata),
        .M_AXI_GP0_RID(ctrl_rid),
        .M_AXI_GP0_RLAST(ctrl_rlast),
        .M_AXI_GP0_RREADY(ctrl_rready),
        .M_AXI_GP0_RRESP(ctrl_rresp),
        .M_AXI_GP0_RVALID(ctrl_rvalid),
        .M_AXI_GP0_WDATA(ctrl_wdata),
        .M_AXI_GP0_WID(ctrl_wid),
        .M_AXI_GP0_WLAST(ctrl_wlast),
        .M_AXI_GP0_WREADY(ctrl_wready),
        .M_AXI_GP0_WSTRB(ctrl_wstrb),
        .M_AXI_GP0_WVALID(ctrl_wvalid),


        .S_AXI_HP0_ACLK(processing_system7_1_fclk_clk0),
        .S_AXI_HP0_ARLOCK({GND_1,GND_1}),
        .S_AXI_HP0_ARQOS({GND_1,GND_1,GND_1,GND_1}),
        .S_AXI_HP0_AWLOCK({GND_1,GND_1}),
        .S_AXI_HP0_AWQOS({GND_1,GND_1,GND_1,GND_1}),
        /* .S_AXI_HP0_RDISSUECAP1_EN(GND_1), */
        /* .S_AXI_HP0_WRISSUECAP1_EN(GND_1), */
        .S_AXI_HP0_ARADDR(m_axi_araddr),
        .S_AXI_HP0_ARBURST(m_axi_arburst),
        .S_AXI_HP0_ARCACHE(m_axi_arcache),
        .S_AXI_HP0_ARID(m_axi_arid),
        .S_AXI_HP0_ARLEN(m_axi_arlen),
        .S_AXI_HP0_ARPROT(m_axi_arprot),
        .S_AXI_HP0_ARREADY(m_axi_arready),
        .S_AXI_HP0_ARSIZE(m_axi_arsize),
        .S_AXI_HP0_ARVALID(m_axi_arvalid),
        .S_AXI_HP0_AWADDR(m_axi_awaddr),
        .S_AXI_HP0_AWBURST(m_axi_awburst),
        .S_AXI_HP0_AWCACHE(m_axi_awcache),
        .S_AXI_HP0_AWID(m_axi_awid),
        .S_AXI_HP0_AWLEN(m_axi_awlen),
        .S_AXI_HP0_AWPROT(m_axi_awprot),
        .S_AXI_HP0_AWREADY(m_axi_awready),
        .S_AXI_HP0_AWSIZE(m_axi_awsize),
        .S_AXI_HP0_AWVALID(m_axi_awvalid),
        .S_AXI_HP0_BID(m_axi_bid),
        .S_AXI_HP0_BREADY(m_axi_bready),
        .S_AXI_HP0_BRESP(m_axi_bresp),
        .S_AXI_HP0_BVALID(m_axi_bvalid),
        .S_AXI_HP0_RDATA(m_axi_rdata),
        .S_AXI_HP0_RID(m_axi_rid),
        .S_AXI_HP0_RLAST(m_axi_rlast),
        .S_AXI_HP0_RREADY(m_axi_rready),
        .S_AXI_HP0_RRESP(m_axi_rresp),
        .S_AXI_HP0_RVALID(m_axi_rvalid),
        .S_AXI_HP0_WDATA(m_axi_wdata),
        .S_AXI_HP0_WID(m_axi_wid),
        .S_AXI_HP0_WLAST(m_axi_wlast),
        .S_AXI_HP0_WREADY(m_axi_wready),
        .S_AXI_HP0_WSTRB(m_axi_wstrb),
        .S_AXI_HP0_WVALID(m_axi_wvalid),


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

        .PS_CLK(FIXED_IO_ps_clk));
   
endmodule
