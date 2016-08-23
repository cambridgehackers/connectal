`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/22/2016 11:06:00 AM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top
   (FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    MIO,
    RST_N_pcie_sys_reset_n,
    ddrx_addr,
    ddrx_ba,
    ddrx_cas_n,
    ddrx_ck_n,
    ddrx_ck_p,
    ddrx_cke,
    ddrx_cs_n,
    ddrx_dm,
    ddrx_dq,
    ddrx_dqs_n,
    ddrx_dqs_p,
    ddrx_odt,
    ddrx_ras_n,
    ddrx_reset_n,
    ddrx_we_n,
    pcie_exp_rxn,
    pcie_exp_rxp,
    pcie_exp_txn,
    pcie_exp_txp,
    pcie_refclk_clk_n,
    pcie_refclk_clk_p);
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  inout [53:0]MIO;
  output RST_N_pcie_sys_reset_n;
  inout [14:0]ddrx_addr;
  inout [2:0]ddrx_ba;
  inout ddrx_cas_n;
  inout ddrx_ck_n;
  inout ddrx_ck_p;
  inout ddrx_cke;
  inout ddrx_cs_n;
  inout [3:0]ddrx_dm;
  inout [31:0]ddrx_dq;
  inout [3:0]ddrx_dqs_n;
  inout [3:0]ddrx_dqs_p;
  inout ddrx_odt;
  inout ddrx_ras_n;
  inout ddrx_reset_n;
  inout ddrx_we_n;
  input [3:0]pcie_exp_rxn;
  input [3:0]pcie_exp_rxp;
  output [3:0]pcie_exp_txn;
  output [3:0]pcie_exp_txp;
  input pcie_refclk_clk_n;
  input pcie_refclk_clk_p;

  wire [127:0]mkSearchAcceleratorClient_0_dataToNvme_TDATA;
  wire [15:0]mkSearchAcceleratorClient_0_dataToNvme_TKEEP;
  wire mkSearchAcceleratorClient_0_dataToNvme_TLAST;
  wire mkSearchAcceleratorClient_0_dataToNvme_TREADY;
  wire mkSearchAcceleratorClient_0_dataToNvme_TVALID;
  wire [31:0]mkSearchAcceleratorClient_0_msgToSoftware_TDATA;
  wire [3:0]mkSearchAcceleratorClient_0_msgToSoftware_TKEEP;
  wire mkSearchAcceleratorClient_0_msgToSoftware_TLAST;
  wire mkSearchAcceleratorClient_0_msgToSoftware_TREADY;
  wire mkSearchAcceleratorClient_0_msgToSoftware_TVALID;
  wire [159:0]mkSearchAcceleratorClient_0_request_TDATA;
  wire [19:0]mkSearchAcceleratorClient_0_request_TKEEP;
  wire mkSearchAcceleratorClient_0_request_TLAST;
  wire mkSearchAcceleratorClient_0_request_TREADY;
  wire mkSearchAcceleratorClient_0_request_TVALID;
  wire nvmehost_0_CLK_accel_clock;
  wire nvmehost_0_RST_N_accel_reset;
  wire nvmehost_0_RST_N_pcie_sys_reset_n;
  wire [127:0]nvmehost_0_accel_dataFromNvme_TDATA;
  wire [15:0]nvmehost_0_accel_dataFromNvme_TKEEP;
  wire nvmehost_0_accel_dataFromNvme_TLAST;
  wire nvmehost_0_accel_dataFromNvme_TREADY;
  wire nvmehost_0_accel_dataFromNvme_TVALID;
  wire [31:0]nvmehost_0_accel_msgFromSoftware_TDATA;
  wire [3:0]nvmehost_0_accel_msgFromSoftware_TKEEP;
  wire nvmehost_0_accel_msgFromSoftware_TLAST;
  wire nvmehost_0_accel_msgFromSoftware_TREADY;
  wire nvmehost_0_accel_msgFromSoftware_TVALID;
  wire [47:0]nvmehost_0_accel_response_TDATA;
  wire [5:0]nvmehost_0_accel_response_TKEEP;
  wire nvmehost_0_accel_response_TLAST;
  wire nvmehost_0_accel_response_TREADY;
  wire nvmehost_0_accel_response_TVALID;
  wire [14:0]nvmehost_0_ddrx_ADDR;
  wire [2:0]nvmehost_0_ddrx_BA;
  wire nvmehost_0_ddrx_CAS_N;
  wire nvmehost_0_ddrx_CKE;
  wire nvmehost_0_ddrx_CK_N;
  wire nvmehost_0_ddrx_CK_P;
  wire nvmehost_0_ddrx_CS_N;
  wire [3:0]nvmehost_0_ddrx_DM;
  wire [31:0]nvmehost_0_ddrx_DQ;
  wire [3:0]nvmehost_0_ddrx_DQS_N;
  wire [3:0]nvmehost_0_ddrx_DQS_P;
  wire nvmehost_0_ddrx_ODT;
  wire nvmehost_0_ddrx_RAS_N;
  wire nvmehost_0_ddrx_RESET_N;
  wire nvmehost_0_ddrx_WE_N;
  wire [3:0]nvmehost_0_pcie_exp_rxn;
  wire [3:0]nvmehost_0_pcie_exp_rxp;
  wire [3:0]nvmehost_0_pcie_exp_txn;
  wire [3:0]nvmehost_0_pcie_exp_txp;
  wire pcie_refclk_1_CLK_N;
  wire pcie_refclk_1_CLK_P;

  assign RST_N_pcie_sys_reset_n = nvmehost_0_RST_N_pcie_sys_reset_n;
  assign nvmehost_0_pcie_exp_rxn = pcie_exp_rxn[3:0];
  assign nvmehost_0_pcie_exp_rxp = pcie_exp_rxp[3:0];
  assign pcie_exp_txn[3:0] = nvmehost_0_pcie_exp_txn;
  assign pcie_exp_txp[3:0] = nvmehost_0_pcie_exp_txp;
  assign pcie_refclk_1_CLK_N = pcie_refclk_clk_n;
  assign pcie_refclk_1_CLK_P = pcie_refclk_clk_p;


// user design goes here
   
  countwords countwords_0 (
			   .accel_clock(nvmehost_0_CLK_accel_clock),
			   .accel_reset(nvmehost_0_RST_N_accel_reset),
			   .accel_dataFromNvme_tdata(nvmehost_0_accel_dataFromNvme_TDATA),
			   .accel_dataFromNvme_tkeep(nvmehost_0_accel_dataFromNvme_TKEEP),
			   .accel_dataFromNvme_tlast(nvmehost_0_accel_dataFromNvme_TLAST),
			   .accel_dataFromNvme_tready(nvmehost_0_accel_dataFromNvme_TREADY),
			   .accel_dataFromNvme_tvalid(nvmehost_0_accel_dataFromNvme_TVALID),

			   .accel_msgToSoftware_tdata(mkSearchAcceleratorClient_0_msgToSoftware_TDATA),
			   .accel_msgToSoftware_tkeep(mkSearchAcceleratorClient_0_msgToSoftware_TKEEP),
			   .accel_msgToSoftware_tlast(mkSearchAcceleratorClient_0_msgToSoftware_TLAST),
			   .accel_msgToSoftware_tready(mkSearchAcceleratorClient_0_msgToSoftware_TREADY),
			   .accel_msgToSoftware_tvalid(mkSearchAcceleratorClient_0_msgToSoftware_TVALID)
			   );

  nvmehost_0 nvmehost_0
       (.CLK_accel_clock(nvmehost_0_CLK_accel_clock),
        .DDR_Addr(ddrx_addr[14:0]),
        .DDR_BankAddr(ddrx_ba[2:0]),
        .DDR_CAS_n(ddrx_cas_n),
        .DDR_CKE(ddrx_cke),
        .DDR_CS_n(ddrx_cs_n),
        .DDR_Clk_n(ddrx_ck_n),
        .DDR_Clk_p(ddrx_ck_p),
        .DDR_DM(ddrx_dm[3:0]),
        .DDR_DQ(ddrx_dq[31:0]),
        .DDR_DQS_n(ddrx_dqs_n[3:0]),
        .DDR_DQS_p(ddrx_dqs_p[3:0]),
        .DDR_DRSTB(ddrx_reset_n),
        .DDR_ODT(ddrx_odt),
        .DDR_RAS_n(ddrx_ras_n),
        .DDR_WEB(ddrx_we_n),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .MIO(MIO[53:0]),
        .RST_N_accel_reset(nvmehost_0_RST_N_accel_reset),
        .RST_N_pcie_sys_reset_n(nvmehost_0_RST_N_pcie_sys_reset_n),
        .accel_dataFromNvme_tdata(nvmehost_0_accel_dataFromNvme_TDATA),
        .accel_dataFromNvme_tkeep(nvmehost_0_accel_dataFromNvme_TKEEP),
        .accel_dataFromNvme_tlast(nvmehost_0_accel_dataFromNvme_TLAST),
        .accel_dataFromNvme_tready(nvmehost_0_accel_dataFromNvme_TREADY),
        .accel_dataFromNvme_tvalid(nvmehost_0_accel_dataFromNvme_TVALID),
        .accel_dataToNvme_tdata(mkSearchAcceleratorClient_0_dataToNvme_TDATA),
        .accel_dataToNvme_tkeep(mkSearchAcceleratorClient_0_dataToNvme_TKEEP),
        .accel_dataToNvme_tlast(mkSearchAcceleratorClient_0_dataToNvme_TLAST),
        .accel_dataToNvme_tready(mkSearchAcceleratorClient_0_dataToNvme_TREADY),
        .accel_dataToNvme_tvalid(mkSearchAcceleratorClient_0_dataToNvme_TVALID),
        .accel_msgFromSoftware_tdata(nvmehost_0_accel_msgFromSoftware_TDATA),
        .accel_msgFromSoftware_tkeep(nvmehost_0_accel_msgFromSoftware_TKEEP),
        .accel_msgFromSoftware_tlast(nvmehost_0_accel_msgFromSoftware_TLAST),
        .accel_msgFromSoftware_tready(nvmehost_0_accel_msgFromSoftware_TREADY),
        .accel_msgFromSoftware_tvalid(nvmehost_0_accel_msgFromSoftware_TVALID),
        .accel_msgToSoftware_tdata(mkSearchAcceleratorClient_0_msgToSoftware_TDATA),
        .accel_msgToSoftware_tkeep(mkSearchAcceleratorClient_0_msgToSoftware_TKEEP),
        .accel_msgToSoftware_tlast(mkSearchAcceleratorClient_0_msgToSoftware_TLAST),
        .accel_msgToSoftware_tready(mkSearchAcceleratorClient_0_msgToSoftware_TREADY),
        .accel_msgToSoftware_tvalid(mkSearchAcceleratorClient_0_msgToSoftware_TVALID),
        .accel_request_tdata(mkSearchAcceleratorClient_0_request_TDATA),
        .accel_request_tkeep(mkSearchAcceleratorClient_0_request_TKEEP),
        .accel_request_tlast(mkSearchAcceleratorClient_0_request_TLAST),
        .accel_request_tready(mkSearchAcceleratorClient_0_request_TREADY),
        .accel_request_tvalid(mkSearchAcceleratorClient_0_request_TVALID),
        .accel_response_tdata(nvmehost_0_accel_response_TDATA),
        .accel_response_tkeep(nvmehost_0_accel_response_TKEEP),
        .accel_response_tlast(nvmehost_0_accel_response_TLAST),
        .accel_response_tready(nvmehost_0_accel_response_TREADY),
        .accel_response_tvalid(nvmehost_0_accel_response_TVALID),
        .pcie_exp_rxn_v(nvmehost_0_pcie_exp_rxn),
        .pcie_exp_rxp_v(nvmehost_0_pcie_exp_rxp),
        .pcie_exp_txn(nvmehost_0_pcie_exp_txn),
        .pcie_exp_txp(nvmehost_0_pcie_exp_txp),
        .pcie_refclk_n(pcie_refclk_1_CLK_N),
        .pcie_refclk_p(pcie_refclk_1_CLK_P));
endmodule
