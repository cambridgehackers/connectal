
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

/* dut goes here */
mkZynqTop dutIMPLEMENTATION (
        .CLK_axi_clock(processing_system7_1_fclk_clk0),
	.DDR_arb_v(0),
	.CLK_fclk_clk0(processing_system7_1_fclk_clk0),
        .DDR_addr(DDR_Addr[14:0]),
        .DDR_bankaddr(DDR_BankAddr[2:0]),
        .DDR_cas_n(DDR_CAS_n),
        .DDR_cke(DDR_CKE),
        .DDR_cs_n(DDR_CS_n),
        .DDR_clk(DDR_Clk_p),
        .DDR_clk_n(DDR_Clk_n),
        .DDR_dm(DDR_DM[3:0]),
        .DDR_dq(DDR_DQ[31:0]),
        .DDR_dqs(DDR_DQS_p[3:0]),
        .DDR_dqs_n(DDR_DQS_n[3:0]),
        .DDR_drstb(DDR_DRSTB),
        .DDR_odt(DDR_ODT),
        .DDR_ras_n(DDR_RAS_n),
        .DDR_vrn(FIXED_IO_ddr_vrn),
        .DDR_vrp(FIXED_IO_ddr_vrp),
        .DDR_web(DDR_WEB),
        .MIO(FIXED_IO_mio[53:0]),
        .PS_porb(FIXED_IO_ps_porb),
        .PS_srstb(FIXED_IO_ps_srstb),
        .PS_clk(FIXED_IO_ps_clk),
      .CLK(processing_system7_1_fclk_clk0),
      .RST_N(processing_system7_1_fclk_reset0_n),
      .leds_leds(GPIO_leds)
      );

endmodule
