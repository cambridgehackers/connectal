`timescale 1ps/1ps
`default_nettype none
module axi_passthrough #
  (
   parameter integer C_NUM_SLAVE_SLOTS = 1,
   parameter integer C_NUM_MASTER_SLOTS = 1,
   parameter integer C_AXI_ID_WIDTH = 1,
   parameter integer C_AXI_ADDR_WIDTH = 32,
   parameter integer C_AXI_DATA_MAX_WIDTH = 32,
   parameter integer C_INTERCONNECT_CONNECTIVITY_MODE = 1
 )
  (
   input  wire                                                  INTERCONNECT_ACLK,
   (* KEEP = "TRUE" *) input  wire                              INTERCONNECT_ARESETN /* synthesis syn_keep = 1 */,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                          S_AXI_ARESET_OUT_N,  // Non-AXI resynchronized reset output
   output wire [C_NUM_MASTER_SLOTS-1:0]                         M_AXI_ARESET_OUT_N,  // Non-AXI resynchronized reset output
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                          S_AXI_ACLK,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]           S_AXI_AWID,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ADDR_WIDTH-1:0]         S_AXI_AWADDR,
   input  wire [C_NUM_SLAVE_SLOTS*8-1:0]                        S_AXI_AWLEN,
   input  wire [C_NUM_SLAVE_SLOTS*3-1:0]                        S_AXI_AWSIZE,
   input  wire [C_NUM_SLAVE_SLOTS*2-1:0]                        S_AXI_AWBURST,
   input  wire [C_NUM_SLAVE_SLOTS*2-1:0]                        S_AXI_AWLOCK,
   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                        S_AXI_AWCACHE,
   input  wire [C_NUM_SLAVE_SLOTS*3-1:0]                        S_AXI_AWPROT,
   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                        S_AXI_AWQOS,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                          S_AXI_AWVALID,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                          S_AXI_AWREADY,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]           S_AXI_WID,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_DATA_MAX_WIDTH-1:0]     S_AXI_WDATA,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_DATA_MAX_WIDTH/8-1:0]   S_AXI_WSTRB,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                          S_AXI_WLAST,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                          S_AXI_WVALID,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                          S_AXI_WREADY,
   output wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]           S_AXI_BID,
   output wire [C_NUM_SLAVE_SLOTS*2-1:0]                        S_AXI_BRESP,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                          S_AXI_BVALID,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                          S_AXI_BREADY,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]           S_AXI_ARID,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ADDR_WIDTH-1:0]         S_AXI_ARADDR,
   input  wire [C_NUM_SLAVE_SLOTS*8-1:0]                        S_AXI_ARLEN,
   input  wire [C_NUM_SLAVE_SLOTS*3-1:0]                        S_AXI_ARSIZE,
   input  wire [C_NUM_SLAVE_SLOTS*2-1:0]                        S_AXI_ARBURST,
   input  wire [C_NUM_SLAVE_SLOTS*2-1:0]                        S_AXI_ARLOCK,
   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                        S_AXI_ARCACHE,
   input  wire [C_NUM_SLAVE_SLOTS*3-1:0]                        S_AXI_ARPROT,
   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                        S_AXI_ARQOS,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                          S_AXI_ARVALID,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                          S_AXI_ARREADY,
   output wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]           S_AXI_RID,
   output wire [C_NUM_SLAVE_SLOTS*C_AXI_DATA_MAX_WIDTH-1:0]     S_AXI_RDATA,
   output wire [C_NUM_SLAVE_SLOTS*2-1:0]                        S_AXI_RRESP,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                          S_AXI_RLAST,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                          S_AXI_RVALID,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                          S_AXI_RREADY,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                         M_AXI_ACLK,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]          M_AXI_AWID,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ADDR_WIDTH-1:0]        M_AXI_AWADDR,
   output wire [C_NUM_MASTER_SLOTS*8-1:0]                       M_AXI_AWLEN,
   output wire [C_NUM_MASTER_SLOTS*3-1:0]                       M_AXI_AWSIZE,
   output wire [C_NUM_MASTER_SLOTS*2-1:0]                       M_AXI_AWBURST,
   output wire [C_NUM_MASTER_SLOTS*2-1:0]                       M_AXI_AWLOCK,
   output wire [C_NUM_MASTER_SLOTS*4-1:0]                       M_AXI_AWCACHE,
   output wire [C_NUM_MASTER_SLOTS*3-1:0]                       M_AXI_AWPROT,
   output wire [C_NUM_MASTER_SLOTS*4-1:0]                       M_AXI_AWQOS,
   output wire [C_NUM_MASTER_SLOTS-1:0]                         M_AXI_AWVALID,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                         M_AXI_AWREADY,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]          M_AXI_WID,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_DATA_MAX_WIDTH-1:0]    M_AXI_WDATA,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_DATA_MAX_WIDTH/8-1:0]  M_AXI_WSTRB,
   output wire [C_NUM_MASTER_SLOTS-1:0]                         M_AXI_WLAST,
   output wire [C_NUM_MASTER_SLOTS-1:0]                         M_AXI_WVALID,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                         M_AXI_WREADY,
   input  wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]          M_AXI_BID,
   input  wire [C_NUM_MASTER_SLOTS*2-1:0]                       M_AXI_BRESP,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                         M_AXI_BVALID,
   output wire [C_NUM_MASTER_SLOTS-1:0]                         M_AXI_BREADY,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]          M_AXI_ARID,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ADDR_WIDTH-1:0]        M_AXI_ARADDR,
   output wire [C_NUM_MASTER_SLOTS*8-1:0]                       M_AXI_ARLEN,
   output wire [C_NUM_MASTER_SLOTS*3-1:0]                       M_AXI_ARSIZE,
   output wire [C_NUM_MASTER_SLOTS*2-1:0]                       M_AXI_ARBURST,
   output wire [C_NUM_MASTER_SLOTS*2-1:0]                       M_AXI_ARLOCK,
   output wire [C_NUM_MASTER_SLOTS*4-1:0]                       M_AXI_ARCACHE,
   output wire [C_NUM_MASTER_SLOTS*3-1:0]                       M_AXI_ARPROT,
   output wire [C_NUM_MASTER_SLOTS*4-1:0]                       M_AXI_ARQOS,
   output wire [C_NUM_MASTER_SLOTS-1:0]                         M_AXI_ARVALID,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                         M_AXI_ARREADY,
   input  wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]          M_AXI_RID,
   input  wire [C_NUM_MASTER_SLOTS*C_AXI_DATA_MAX_WIDTH-1:0]    M_AXI_RDATA,
   input  wire [C_NUM_MASTER_SLOTS*2-1:0]                       M_AXI_RRESP,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                         M_AXI_RLAST,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                         M_AXI_RVALID,
   output wire [C_NUM_MASTER_SLOTS-1:0]                         M_AXI_RREADY
 );

  assign S_AXI_ARESET_OUT_N = 0;
  assign M_AXI_ARESET_OUT_N = 0;
  assign S_AXI_ARREADY = M_AXI_ARREADY;
  assign S_AXI_AWREADY = M_AXI_AWREADY;
  assign S_AXI_BID = M_AXI_BID;
  assign S_AXI_BRESP = M_AXI_BRESP;
  assign S_AXI_BVALID = M_AXI_BVALID;
  assign S_AXI_RDATA = M_AXI_RDATA;
  assign S_AXI_RID = M_AXI_RID;
  assign S_AXI_RLAST = M_AXI_RLAST;
  assign S_AXI_RRESP = M_AXI_RRESP;
  assign S_AXI_RVALID = M_AXI_RVALID;
  assign S_AXI_WREADY = M_AXI_WREADY;

  assign M_AXI_ARADDR = S_AXI_ARADDR;
  assign M_AXI_ARBURST = S_AXI_ARBURST;
  assign M_AXI_ARCACHE = S_AXI_ARCACHE;
  assign M_AXI_ARID = S_AXI_ARID;
  assign M_AXI_ARLEN = S_AXI_ARLEN;
  assign M_AXI_ARLOCK = S_AXI_ARLOCK;
  assign M_AXI_ARPROT = S_AXI_ARPROT;
  assign M_AXI_ARQOS = S_AXI_ARQOS;
  assign M_AXI_ARSIZE = S_AXI_ARSIZE;
  assign M_AXI_ARVALID = S_AXI_ARVALID;
  assign M_AXI_AWADDR = S_AXI_AWADDR;
  assign M_AXI_AWBURST = S_AXI_AWBURST;
  assign M_AXI_AWCACHE = S_AXI_AWCACHE;
  assign M_AXI_AWID = S_AXI_AWID;
  assign M_AXI_AWLEN = S_AXI_AWLEN;
  assign M_AXI_AWLOCK = S_AXI_AWLOCK;
  assign M_AXI_AWPROT = S_AXI_AWPROT;
  assign M_AXI_AWQOS = S_AXI_AWQOS;
  assign M_AXI_AWSIZE = S_AXI_AWSIZE;
  assign M_AXI_AWVALID = S_AXI_AWVALID;
  assign M_AXI_BREADY = S_AXI_BREADY;
  assign M_AXI_RREADY = S_AXI_RREADY;
  assign M_AXI_WDATA = S_AXI_WDATA;
  assign M_AXI_WID = {(C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH){1'b0}};
  assign M_AXI_WLAST = S_AXI_WLAST;
  assign M_AXI_WSTRB = S_AXI_WSTRB;
  assign M_AXI_WVALID = S_AXI_WVALID;
endmodule
`default_nettype wire
