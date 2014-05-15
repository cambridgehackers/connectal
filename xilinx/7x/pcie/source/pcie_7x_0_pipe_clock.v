//-----------------------------------------------------------------------------
//
// (c) Copyright 2010-2011 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
// Project    : Series-7 Integrated Block for PCI Express
// File       : pcie_7x_0_pipe_clock.v
// Version    : 3.0
//------------------------------------------------------------------------------
//  Filename     :  pipe_clock.v
//  Description  :  PIPE Clock Module for 7 Series Transceiver
//  Version      :  15.3
//------------------------------------------------------------------------------
`timescale 1ns / 1ps
//---------- PIPE Clock Module -------------------------------------------------
(* DowngradeIPIdentifiedWarnings = "yes" *)
module pcie_7x_0_foo_pipe_clock # (
    parameter PCIE_LANE          = 1,                       // PCIe number of lanes
    parameter PCIE_USERCLK1_FREQ = 2,                       // PCIe user clock 1 frequency
    parameter PCIE_USERCLK2_FREQ = 2                       // PCIe user clock 2 frequency
) ( input                       CLK_CLK,
    input                       CLK_TXOUTCLK,
    input       [PCIE_LANE-1:0] CLK_RXOUTCLK_IN,
    input       [PCIE_LANE-1:0] CLK_PCLK_SEL,
    input       [PCIE_LANE-1:0] CLK_PCLK_SEL_SLAVE,
    input                       CLK_GEN3,
    output                      CLK_PCLK,
    output                      CLK_PCLK_SLAVE,
    output                      CLK_RXUSRCLK,
    output      [PCIE_LANE-1:0] CLK_RXOUTCLK_OUT,
    output                      CLK_DCLK,
    output                      CLK_OOBCLK,
    output                      CLK_USERCLK1,
    output                      CLK_USERCLK2,
    output                      CLK_MMCM_LOCK );
    //---------- Select Clock Divider ----------------------
    localparam          DIVCLK_DIVIDE    = 1;
    localparam          CLKFBOUT_MULT_F  = 10;
    localparam          CLKIN1_PERIOD    = 10;
    localparam          CLKOUT0_DIVIDE_F = 8;
    localparam          CLKOUT1_DIVIDE   = 4;
    localparam          CLKOUT2_DIVIDE   = (PCIE_USERCLK1_FREQ == 5) ?  2 : (PCIE_USERCLK1_FREQ == 4) ?  4 :
                                           (PCIE_USERCLK1_FREQ == 3) ?  8 : (PCIE_USERCLK1_FREQ == 1) ? 32 : 16;
    localparam          CLKOUT3_DIVIDE   = (PCIE_USERCLK2_FREQ == 5) ?  2 : (PCIE_USERCLK2_FREQ == 4) ?  4 :
                                           (PCIE_USERCLK2_FREQ == 3) ?  8 : (PCIE_USERCLK2_FREQ == 1) ? 32 : 16;
    localparam          CLKOUT4_DIVIDE   = 20;
    //---------- Input Registers ---------------------------
(* ASYNC_REG = "TRUE", SHIFT_EXTRACT = "NO" *)    reg         [PCIE_LANE-1:0] pclk_sel_reg1 = {PCIE_LANE{1'd0}};
(* ASYNC_REG = "TRUE", SHIFT_EXTRACT = "NO" *)    reg         [PCIE_LANE-1:0] pclk_sel_slave_reg1 = {PCIE_LANE{1'd0}};
(* ASYNC_REG = "TRUE", SHIFT_EXTRACT = "NO" *)    reg                         gen3_reg1     = 1'd0;

(* ASYNC_REG = "TRUE", SHIFT_EXTRACT = "NO" *)    reg         [PCIE_LANE-1:0] pclk_sel_reg2 = {PCIE_LANE{1'd0}};
(* ASYNC_REG = "TRUE", SHIFT_EXTRACT = "NO" *)    reg         [PCIE_LANE-1:0] pclk_sel_slave_reg2 = {PCIE_LANE{1'd0}};
(* ASYNC_REG = "TRUE", SHIFT_EXTRACT = "NO" *)    reg                         gen3_reg2     = 1'd0;

    wire                        refclk;
    wire                        mmcm_fb;
    wire                        clk_125mhz;
    wire                        clk_125mhz_buf;
    wire                        clk_250mhz;
    wire                        userclk1;
    wire                        userclk2;
    wire                        oobclk;
    reg                         pclk_sel = 1'd0;
    reg                         pclk_sel_slave = 1'd0;
    wire                        pclk_1;
    wire                        pclk;
    wire                        userclk1_1;
    wire                        userclk2_1;
    wire                        mmcm_lock;

//---------- Input FF ----------------------------------------------------------
always @ (posedge pclk)
begin
        //---------- 1st Stage FF --------------------------
        pclk_sel_reg1 <= CLK_PCLK_SEL;
        pclk_sel_slave_reg1 <= CLK_PCLK_SEL_SLAVE;
        gen3_reg1     <= CLK_GEN3;
        //---------- 2nd Stage FF --------------------------
        pclk_sel_reg2 <= pclk_sel_reg1;
        pclk_sel_slave_reg2 <= pclk_sel_slave_reg1;
        gen3_reg2     <= gen3_reg1;
end

BUFG txoutclk_i ( .I (CLK_TXOUTCLK), .O (refclk) );

MMCME2_ADV #( .BANDWIDTH("OPTIMIZED"), .CLKOUT4_CASCADE("FALSE"),
    .COMPENSATION("ZHOLD"), .STARTUP_WAIT("FALSE"), .DIVCLK_DIVIDE(DIVCLK_DIVIDE),
    .CLKFBOUT_MULT_F(CLKFBOUT_MULT_F), .CLKFBOUT_PHASE(0.000), .CLKFBOUT_USE_FINE_PS("FALSE"),
    .CLKOUT0_DIVIDE_F(CLKOUT0_DIVIDE_F), .CLKOUT0_PHASE(0.000), .CLKOUT0_DUTY_CYCLE(0.500), .CLKOUT0_USE_FINE_PS("FALSE"),
    .CLKOUT1_DIVIDE(CLKOUT1_DIVIDE), .CLKOUT1_PHASE(0.000), .CLKOUT1_DUTY_CYCLE(0.500), .CLKOUT1_USE_FINE_PS("FALSE"),
    .CLKOUT2_DIVIDE(CLKOUT2_DIVIDE), .CLKOUT2_PHASE(0.000), .CLKOUT2_DUTY_CYCLE(0.500), .CLKOUT2_USE_FINE_PS("FALSE"),
    .CLKOUT3_DIVIDE(CLKOUT3_DIVIDE), .CLKOUT3_PHASE(0.000), .CLKOUT3_DUTY_CYCLE(0.500), .CLKOUT3_USE_FINE_PS("FALSE"),
    .CLKOUT4_DIVIDE(CLKOUT4_DIVIDE), .CLKOUT4_PHASE(0.000), .CLKOUT4_DUTY_CYCLE(0.500), .CLKOUT4_USE_FINE_PS("FALSE"),
    .CLKIN1_PERIOD(CLKIN1_PERIOD),
    .REF_JITTER1                (0.010) )
mmcm_i ( .CLKIN1(refclk), .CLKIN2(1'd0),  // not used, comment out CLKIN2 if it cause implementation issues
    .CLKINSEL(1'd1), .CLKFBIN(mmcm_fb), .RST(1'b0), .PWRDWN(1'd0),
    .CLKFBOUT(mmcm_fb), .CLKFBOUTB(),
    .CLKOUT0(clk_125mhz), .CLKOUT0B(),
    .CLKOUT1(clk_250mhz), .CLKOUT1B(),
    .CLKOUT2(userclk1), .CLKOUT2B(),
    .CLKOUT3(userclk2), .CLKOUT3B(),
    .CLKOUT4(oobclk), .CLKOUT5(), .CLKOUT6(),
    .LOCKED(mmcm_lock),
    .DCLK( 1'd0), .DADDR( 7'd0), .DEN( 1'd0), .DWE( 1'd0), .DI(16'd0), .DO(), .DRDY(),
    .PSCLK(1'd0), .PSEN(1'd0), .PSINCDEC(1'd0), .PSDONE(),
    .CLKINSTOPPED(), .CLKFBSTOPPED()  );

    BUFGCTRL pclk_i1 ( .CE0 (1'd1), .CE1 (1'd1),
        .I0 (clk_125mhz), .I1 (clk_250mhz), .IGNORE0 (1'd0), .IGNORE1 (1'd0),
        .S0 (~pclk_sel), .S1 ( pclk_sel), .O (pclk_1));
    assign CLK_PCLK_SLAVE = 1'b0;
    assign CLK_RXOUTCLK_OUT = {PCIE_LANE{1'd0}};

generate if (PCIE_USERCLK2_FREQ <= 3)
    begin : dclk_i
    assign CLK_DCLK = userclk2_1;                       // always less than 125Mhz
    end
else
    begin : dclk_i_bufg
    BUFG dclk_i ( .I (clk_125mhz), .O (CLK_DCLK));
    end
endgenerate
generate if (PCIE_USERCLK1_FREQ == 3)
    begin :userclk1_i1_no_bufg
    assign userclk1_1 = pclk_1;
    end
else
    begin : userclk1_i1
    BUFG usrclk1_i1 ( .I (userclk1), .O (userclk1_1));
    end
endgenerate
    assign userclk2_1 = userclk1_1;
    assign CLK_OOBCLK = pclk;
// Disabled Second Stage Buffers
    assign pclk         = pclk_1;
    assign CLK_RXUSRCLK = pclk_1;
    assign CLK_USERCLK1 = userclk1_1;
    assign CLK_USERCLK2 = userclk2_1;

//---------- Select PCLK -------------------------------------------------------
always @ (posedge pclk)
begin

        //---------- Select 250 MHz ------------------------
        if (&pclk_sel_reg2)
            pclk_sel <= 1'd1;
        //---------- Select 125 MHz ------------------------
        else if (&(~pclk_sel_reg2))
            pclk_sel <= 1'd0;
        //---------- Hold PCLK -----------------------------
        else
            pclk_sel <= pclk_sel;
        //---------- Select 250 MHz ------------------------
        if (&pclk_sel_slave_reg2)
            pclk_sel_slave <= 1'd1;
        //---------- Select 125 MHz ------------------------
        else if (&(~pclk_sel_slave_reg2))
            pclk_sel_slave <= 1'd0;
        //---------- Hold PCLK -----------------------------
        else
            pclk_sel_slave <= pclk_sel_slave;
end
assign CLK_PCLK      = pclk;
assign CLK_MMCM_LOCK = mmcm_lock;
endmodule
