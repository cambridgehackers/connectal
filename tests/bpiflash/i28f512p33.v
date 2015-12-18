//////////////////////////////////////////////////////////////////////////////
//  File name : i28f512p33.v
//////////////////////////////////////////////////////////////////////////////
//  Copyright (C) 2007-2009 Free Model Foundry; http://www.FreeModelFoundry.com
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2 as
//  published by the Free Software Foundation.
//
//  MODIFICATION HISTORY:
//
//  version: |    author:      |  mod date: | changes made:
//  V1.0       I.Milutinovic     07 Jun 13   Initial Release
//  V1.1       J.Stoickov        09 Apr 01   Write mode corrected for the WENeg
//                                           and CENeg signals rise at same time
//  V1.2       S.Petrovic        09 Apr 15   ADV LOW is removed as condition
//                                           for write address latching
//
//  Downloaded from http://www.freemodelfoundry.com/fmf_vlog_models/flash/i28f512p33.v
//////////////////////////////////////////////////////////////////////////////
//  PART DESCRIPTION:
//
//  Library:     FLASH
//  Technology:  FLASH MEMORY
//  Part:        I28F512P33
//
//  Description: 2 x 256 Mbit Intel Strata Flash Memory (P33) Family
//
//////////////////////////////////////////////////////////////////////////////
//  Comments :
//
//////////////////////////////////////////////////////////////////////////////
//  Known Bugs:
//
//////////////////////////////////////////////////////////////////////////////

`timescale 1 ns/1 ns

//////////////////////////////////////////////////////////////////////////////
// TOP MODULE DECLARATION, Top and Bottom Parameter Block Configuration     //
//////////////////////////////////////////////////////////////////////////////
module i28f512p33
    (
    input [25:0]    Addr,
    input [15:0]    DQ,

    input  ADVNeg,
    input  CENeg,
    input  CLK,
    input  OENeg,
    input  RSTNeg,
    input  WENeg,
    input  WPNeg,
    input  VPP,
	  
    output WAITOut
     );

    // parameter declaration
    parameter mem_file_name     = "none";
    parameter mem_file_name_1   = "none";
    parameter otp_blocks_file   = "none";
    parameter otp_blocks_file_1 = "none";
    parameter prot_reg_file     = "none";
    parameter prot_reg_file_1   = "none";
    parameter UserPreload       = 1'b0;
    parameter TimingModel       = "defaulttimingmodel";
    parameter VPP_voltage       = 9;

    wire CENeg1;
    wire CENeg2;

   wire [26:1] A;
   assign A[26:1] = Addr[25:0];

    assign CENeg1 = (~CENeg && A[25]) ? 1'b0 : 1'b1;
    assign CENeg2 = (~CENeg && ~A[25]) ? 1'b0 : 1'b1;

    // Instance of flash memory, Top Parameter Block Configuration
    i28f256p33_1 #(mem_file_name, otp_blocks_file, prot_reg_file,
                 UserPreload , TimingModel, VPP_voltage) UPPER_DIE
        (
            .A24(A[24]),
            .A23(A[23]),
            .A22(A[22]),
            .A21(A[21]),
            .A20(A[20]),
            .A19(A[19]),
            .A18(A[18]),
            .A17(A[17]),
            .A16(A[16]),
            .A15(A[15]),
            .A14(A[14]),
            .A13(A[13]),
            .A12(A[12]),
            .A11(A[11]),
            .A10(A[10]),
            .A9(A[9]),
            .A8(A[8]),
            .A7(A[7]),
            .A6(A[6]),
            .A5(A[5]),
            .A4(A[4]),
            .A3(A[3]),
            .A2(A[2]),
            .A1(A[1]),

            .DQ15(DQ[15]),
            .DQ14(DQ[14]),
            .DQ13(DQ[13]),
            .DQ12(DQ[12]),
            .DQ11(DQ[11]),
            .DQ10(DQ[10]),
            .DQ9(DQ[9]),
            .DQ8(DQ[8]),
            .DQ7(DQ[7]),
            .DQ6(DQ[6]),
            .DQ5(DQ[5]),
            .DQ4(DQ[4]),
            .DQ3(DQ[3]),
            .DQ2(DQ[2]),
            .DQ1(DQ[1]),
            .DQ0(DQ[0]),

            .ADVNeg (ADVNeg),
            .CENeg  (CENeg1),
            .CLK    (CLK   ),
            .OENeg  (OENeg ),
            .RSTNeg (RSTNeg),
            .WENeg  (WENeg ),
            .WPNeg  (WPNeg ),
            .VPP    (VPP   ),

            .WAITOut(WAITOut)
        );

    // Instance of flash memory, Bottom Parameter Block Configuration
    i28f256p33_2 #(mem_file_name_1, otp_blocks_file_1, prot_reg_file_1,
                 UserPreload, TimingModel ,VPP_voltage) LOWER_DIE
        (
            .A24(A[24]),
            .A23(A[23]),
            .A22(A[22]),
            .A21(A[21]),
            .A20(A[20]),
            .A19(A[19]),
            .A18(A[18]),
            .A17(A[17]),
            .A16(A[16]),
            .A15(A[15]),
            .A14(A[14]),
            .A13(A[13]),
            .A12(A[12]),
            .A11(A[11]),
            .A10(A[10]),
            .A9(A[9]),
            .A8(A[8]),
            .A7(A[7]),
            .A6(A[6]),
            .A5(A[5]),
            .A4(A[4]),
            .A3(A[3]),
            .A2(A[2]),
            .A1(A[1]),

            .DQ15(DQ[15]),
            .DQ14(DQ[14]),
            .DQ13(DQ[13]),
            .DQ12(DQ[12]),
            .DQ11(DQ[11]),
            .DQ10(DQ[10]),
            .DQ9(DQ[9]),
            .DQ8(DQ[8]),
            .DQ7(DQ[7]),
            .DQ6(DQ[6]),
            .DQ5(DQ[5]),
            .DQ4(DQ[4]),
            .DQ3(DQ[3]),
            .DQ2(DQ[2]),
            .DQ1(DQ[1]),
            .DQ0(DQ[0]),

            .ADVNeg (ADVNeg),
            .CENeg  (CENeg2),
            .CLK    (CLK   ),
            .OENeg  (OENeg ),
            .RSTNeg (RSTNeg),
            .WENeg  (WENeg ),
            .WPNeg  (WPNeg ),
            .VPP    (VPP   ),

            .WAITOut(WAITOut)
        );

endmodule

//////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION, Top Parameter Block Configuration                    //
//////////////////////////////////////////////////////////////////////////////
module i28f256p33_1
    (
        A24             ,
        A23             ,
        A22             ,
        A21             ,
        A20             ,
        A19             ,
        A18             ,
        A17             ,
        A16             ,
        A15             ,
        A14             ,
        A13             ,
        A12             ,
        A11             ,
        A10             ,
        A9              ,
        A8              ,
        A7              ,
        A6              ,
        A5              ,
        A4              ,
        A3              ,
        A2              ,
        A1              ,

        DQ15            ,
        DQ14            ,
        DQ13            ,
        DQ12            ,
        DQ11            ,
        DQ10            ,
        DQ9             ,
        DQ8             ,
        DQ7             ,
        DQ6             ,
        DQ5             ,
        DQ4             ,
        DQ3             ,
        DQ2             ,
        DQ1             ,
        DQ0             ,

        ADVNeg          ,
        CENeg           ,
        CLK             ,
        OENeg           ,
        RSTNeg          ,
        WENeg           ,
        WPNeg           ,
        VPP             ,

        WAITOut
     );

////////////////////////////////////////////////////////////////////////
// Port / Part Pin Declarations
////////////////////////////////////////////////////////////////////////
    input  A24             ;
    input  A23             ;
    input  A22             ;
    input  A21             ;
    input  A20             ;
    input  A19             ;
    input  A18             ;
    input  A17             ;
    input  A16             ;
    input  A15             ;
    input  A14             ;
    input  A13             ;
    input  A12             ;
    input  A11             ;
    input  A10             ;
    input  A9              ;
    input  A8              ;
    input  A7              ;
    input  A6              ;
    input  A5              ;
    input  A4              ;
    input  A3              ;
    input  A2              ;
    input  A1              ;

    inout  DQ15            ;
    inout  DQ14            ;
    inout  DQ13            ;
    inout  DQ12            ;
    inout  DQ11            ;
    inout  DQ10            ;
    inout  DQ9             ;
    inout  DQ8             ;
    inout  DQ7             ;
    inout  DQ6             ;
    inout  DQ5             ;
    inout  DQ4             ;
    inout  DQ3             ;
    inout  DQ2             ;
    inout  DQ1             ;
    inout  DQ0             ;

    input  ADVNeg          ;
    input  CENeg           ;
    input  CLK             ;
    input  OENeg           ;
    input  RSTNeg          ;
    input  WENeg           ;
    input  WPNeg           ;
    input  VPP             ;

    output WAITOut         ;

    // interconnect path delay signals
    wire  A24_ipd  ;
    wire  A23_ipd  ;
    wire  A22_ipd  ;
    wire  A21_ipd  ;
    wire  A20_ipd  ;
    wire  A19_ipd  ;
    wire  A18_ipd  ;
    wire  A17_ipd  ;
    wire  A16_ipd  ;
    wire  A15_ipd  ;
    wire  A14_ipd  ;
    wire  A13_ipd  ;
    wire  A12_ipd  ;
    wire  A11_ipd  ;
    wire  A10_ipd  ;
    wire  A9_ipd   ;
    wire  A8_ipd   ;
    wire  A7_ipd   ;
    wire  A6_ipd   ;
    wire  A5_ipd   ;
    wire  A4_ipd   ;
    wire  A3_ipd   ;
    wire  A2_ipd   ;
    wire  A1_ipd   ;

    wire [23 : 0] A;
    assign A = {
                A24_ipd,
                A23_ipd,
                A22_ipd,
                A21_ipd,
                A20_ipd,
                A19_ipd,
                A18_ipd,
                A17_ipd,
                A16_ipd,
                A15_ipd,
                A14_ipd,
                A13_ipd,
                A12_ipd,
                A11_ipd,
                A10_ipd,
                A9_ipd,
                A8_ipd,
                A7_ipd,
                A6_ipd,
                A5_ipd,
                A4_ipd,
                A3_ipd,
                A2_ipd,
                A1_ipd };

    wire  DQ15_ipd  ;
    wire  DQ14_ipd  ;
    wire  DQ13_ipd  ;
    wire  DQ12_ipd  ;
    wire  DQ11_ipd  ;
    wire  DQ10_ipd  ;
    wire  DQ9_ipd   ;
    wire  DQ8_ipd   ;
    wire  DQ7_ipd   ;
    wire  DQ6_ipd   ;
    wire  DQ5_ipd   ;
    wire  DQ4_ipd   ;
    wire  DQ3_ipd   ;
    wire  DQ2_ipd   ;
    wire  DQ1_ipd   ;
    wire  DQ0_ipd   ;

    wire [15 : 0 ] DQIn;
    assign DQIn = {DQ15_ipd,
                   DQ14_ipd,
                   DQ13_ipd,
                   DQ12_ipd,
                   DQ11_ipd,
                   DQ10_ipd,
                   DQ9_ipd,
                   DQ8_ipd,
                   DQ7_ipd,
                   DQ6_ipd,
                   DQ5_ipd,
                   DQ4_ipd,
                   DQ3_ipd,
                   DQ2_ipd,
                   DQ1_ipd,
                   DQ0_ipd };

    wire [15 : 0 ] DQOut;
    assign DQOut = {DQ15,
                    DQ14,
                    DQ13,
                    DQ12,
                    DQ11,
                    DQ10,
                    DQ9,
                    DQ8,
                    DQ7,
                    DQ6,
                    DQ5,
                    DQ4,
                    DQ3,
                    DQ2,
                    DQ1,
                    DQ0 };

    wire  ADVNeg_ipd      ;
    wire  CENeg_ipd       ;
    wire  CLK_ipd         ;
    wire  OENeg_ipd       ;
    wire  RSTNeg_ipd      ;
    wire  WENeg_ipd       ;
    wire  WPNeg_ipd       ;

    wire  DQ15_zd  ;
    wire  DQ14_zd  ;
    wire  DQ13_zd  ;
    wire  DQ12_zd  ;
    wire  DQ11_zd  ;
    wire  DQ10_zd  ;
    wire  DQ9_zd   ;
    wire  DQ8_zd   ;
    wire  DQ7_zd   ;
    wire  DQ6_zd   ;
    wire  DQ5_zd   ;
    wire  DQ4_zd   ;
    wire  DQ3_zd   ;
    wire  DQ2_zd   ;
    wire  DQ1_zd   ;
    wire  DQ0_zd   ;

    wire  DQ15_Pass  ;
    wire  DQ14_Pass  ;
    wire  DQ13_Pass  ;
    wire  DQ12_Pass  ;
    wire  DQ11_Pass  ;
    wire  DQ10_Pass  ;
    wire  DQ9_Pass   ;
    wire  DQ8_Pass   ;
    wire  DQ7_Pass   ;
    wire  DQ6_Pass   ;
    wire  DQ5_Pass   ;
    wire  DQ4_Pass   ;
    wire  DQ3_Pass   ;
    wire  DQ2_Pass   ;
    wire  DQ1_Pass   ;
    wire  DQ0_Pass   ;

    reg [15 : 0] DQOut_zd = 16'bz;
    reg [15 : 0] DQOut_Pass = 16'bz;

    assign {DQ15_zd,
            DQ14_zd,
            DQ13_zd,
            DQ12_zd,
            DQ11_zd,
            DQ10_zd,
            DQ9_zd,
            DQ8_zd,
            DQ7_zd,
            DQ6_zd,
            DQ5_zd,
            DQ4_zd,
            DQ3_zd,
            DQ2_zd,
            DQ1_zd,
            DQ0_zd  } = DQOut_zd;

    assign {DQ15_Pass,
            DQ14_Pass,
            DQ13_Pass,
            DQ12_Pass,
            DQ11_Pass,
            DQ10_Pass,
            DQ9_Pass,
            DQ8_Pass,
            DQ7_Pass,
            DQ6_Pass,
            DQ5_Pass,
            DQ4_Pass,
            DQ3_Pass,
            DQ2_Pass,
            DQ1_Pass,
            DQ0_Pass  } = DQOut_Pass;

    reg WAITOut_zd = 1'bz;

    parameter mem_file_name   = "none";
    parameter otp_blocks_file = "none";
    parameter prot_reg_file   = "none";
    parameter UserPreload     = 1'b0;
    parameter TimingModel     = "DefaultTimingModel";
    parameter VPP_voltage = 9;    // this parameter specifies if
                                  // 9V or 2V is applied to Vpp pin
                                  // (when VPP pin is 1'b1)

    parameter MaxData            = 16'hFFFF;
    parameter HiAddrBit          = 23;
    parameter MemSize            = 32'hFFFFFF;
    parameter BlockNum           = 258;
    parameter DeviceID_B         = 16'h8922;
    parameter DeviceID_T         = 16'h891F;
    parameter MainBlockSize      = 32'h10000;
    parameter ParameterBlockSize = 32'h04000;

    // If speedsimulation is needed uncomment following line

//       `define SPEEDSIM;

    // FSM states
    parameter        RESET_POWER_DOWN    = 5'd0;
    parameter        READY               = 5'd1;
    parameter        LOCK_SETUP          = 5'd2;
    parameter        OTP_SETUP           = 5'd3;
    parameter        OTP_BUSY            = 5'd4;
    parameter        PROG_SETUP          = 5'd5;
    parameter        PROG_BUSY           = 5'd6;
    parameter        PROG_SUSP           = 5'd7;
    parameter        BP_SETUP            = 5'd8;
    parameter        BP_LOAD             = 5'd9;
    parameter        BP_CONFIRM          = 5'd10;
    parameter        BP_BUSY             = 5'd11;
    parameter        BP_SUSP             = 5'd12;
    parameter        ERASE_SETUP         = 5'd13;
    parameter        ERASE_BUSY          = 5'd14;
    parameter        ERS_SUSP            = 5'd15;
    parameter        PROG_SETUP_ERS_SUSP = 5'd16;
    parameter        PROG_BUSY_ERS_SUSP  = 5'd17;
    parameter        PROG_SUSP_ERS_SUSP  = 5'd18;
    parameter        BP_SETUP_ERS_SUSP   = 5'd19;
    parameter        BP_LOAD_ERS_SUSP    = 5'd20;
    parameter        BP_CONFIRM_ERS_SUSP = 5'd21;
    parameter        BP_BUSY_ERS_SUSP    = 5'd22;
    parameter        BP_SUSP_ERS_SUSP    = 5'd23;
    parameter        LOCK_SETUP_ERS_SUSP = 5'd24;
    parameter        BEFP_SETUP          = 5'd25;
    parameter        BEFP_LOAD           = 5'd26;
    parameter        BEFP_BUSY           = 5'd27;

    // read mode
    parameter        READ_ARRAY   = 2'd0;
    parameter        READ_ID      = 2'd1;
    parameter        READ_QUERY   = 2'd2;
    parameter        READ_STATUS  = 2'd3;

    reg [5:0]      current_state;
    reg [5:0]      next_state;

    reg [1:0]      read_state;

    reg            deq;

    // Memory declaration
    integer MemData[0:MemSize];

    // internal delays
    reg WordProgram_in         = 1'b0;
    reg WordProgram_out        = 1'b0;
    reg BuffProgram_in         = 1'b0;
    reg BuffProgram_out        = 1'b0;
    reg BEFP_in                = 1'b0;
    reg BEFP_out               = 1'b0;
    reg BEFPsetup_in           = 1'b0;
    reg BEFPsetup_out          = 1'b0;
    reg ParameterErase_in      = 1'b0;
    reg MainErase_in           = 1'b0;
    reg ParameterErase_out     = 1'b0;
    reg MainErase_out          = 1'b0;
    reg ProgramSuspend_in      = 1'b0;
    reg ProgramSuspend_out     = 1'b0;
    reg EraseSuspend_in        = 1'b0;
    reg EraseSuspend_out       = 1'b0;
    reg RstDuringErsPrg_in     = 1'b0;
    reg RstDuringErsPrg_out    = 1'b0;

    // event control registers
    reg falling_edge_ADVNeg = 1'b0;
    reg falling_edge_RSTNeg = 1'b0;
    reg falling_edge_BEFPsetup_out = 1'b0;
    reg falling_edge_BEFP_out = 1'b0;
    reg falling_edge_Read  = 1'b0;
    reg falling_edge_OENeg = 1'b0;
    reg falling_edge_CENeg = 1'b0;
    reg rising_edge_ADVNeg = 1'b0;
    reg rising_edge_CLOCK  = 1'b0;
    reg rising_edge_WENeg  = 1'b0;
    reg rising_edge_CENeg  = 1'b0;
    reg rising_edge_RSTNeg = 1'b0;
    reg rising_edge_Write  = 1'b0;
    reg rising_edge_Read   = 1'b0;
    reg RstDuringErsPrg_out_event = 1'b0;
    reg WordProgram_out_event    = 1'b0;
    reg abort_event              = 1'b0;
    reg ProgramSuspend_out_event = 1'b0;
    reg BuffProgram_out_event    = 1'b0;
    reg ExtendProgTime_event     = 1'b0;
    reg ParameterErase_out_event = 1'b0;
    reg falling_edge_MainErase_out    = 1'b0;
    reg falling_edge_EraseSuspend_out = 1'b0;
    reg Ahigh_event           = 1'b0;
    reg Alow_event            = 1'b0;
    reg A_event               = 1'b0;
    reg rising_edge_OENeg     = 1'b0;
    reg AssertWAITOut_event   = 1'b0;
    reg DeassertWAITOut_event = 1'b0;
    reg rising_edge_MainErase_in      = 1'b0;
    reg rising_edge_ParameterErase_in = 1'b0;
    reg EraseSuspend_event            = 1'b0;
    reg rising_edge_MainEraseResume   = 1'b0;
    reg rising_edge_ParameterEraseResume = 1'b0;

    integer i,j;

    // Bus cycle decode
    reg CLOCK = 1'b0;

    reg Write = 1'b0;
    reg Read  = 1'b0;

    reg Pmode = 1'b0;

    // Functional
    reg abort           = 1'b0;

    reg ExtendProgTime  = 1'b0;

    reg AssertWAITOut   = 1'b0;
    reg DeassertWAITOut = 1'b0;

    //Block Lock Status
    parameter UNLOCKED    = 2'd0;
    parameter LOCKED      = 2'd1;
    parameter LOCKED_DOWN = 2'd2;
    integer Block_Lock[BlockNum:0];
    reg [BlockNum:0] BlockLockBit;
    reg [BlockNum:0] BlockLockDownBit;
    reg OTP[0:BlockNum];

    // Status Register
    reg[7:0]    SR   = 8'b10000000;

    // Read Configuration Register
    reg[15:0]   RCR   = 16'b1011111111001111;

    // Protection registers
    integer PR[9'h80:9'h109];

    // CFI array
    integer CFI_array[9'h10:9'h156];

    reg LATCHED = 1'b0;
    reg [15:0] LatchedData;
    reg [HiAddrBit:0] LatchedAddr;
    integer ReadAddr;

    integer DataBuff[0:31];
    integer AddrBuff[0:31];

    integer burst_cntr;
    integer BurstLength;
    integer BurstDelay;
    integer DataHold;

    integer WCount;
    integer word_cntr;
    integer word_cnt;
    integer word_number;
    integer block_number;
    integer erasing_block;

    integer lowest_addr;
    integer highest_addr;
    integer start_addr;

    integer BEFP_addr;
    integer BEFP_block;
    integer BEFP_block2;

    reg [15:0] mem_bits;
    reg [15:0] prog_bits;

    reg [15:0] DQOut_tmp;
    reg read_out = 1'b0;

    reg suspended_bp = 1'b0;
    reg suspended_erase = 1'b0;

    reg aborted ;
    integer block_size;

    reg ParameterEraseResume;
    reg MainEraseResume;
    reg WordProgramResume;
    reg BP_ProgramResume;
    time merase_duration;
    time perase_duration;
    time melapsed;
    time pelapsed;
    time mstart;
    time pstart;
    event merase_event;
    event perase_event;

    // timing check violation
    reg Viol = 1'b0;

    //TPD_XX_DATA
    time           OEDQ_t;
    time           CEDQ_t;
    time           ADDRDQ_t;
    time           OENeg_event;
    time           CENeg_event;
    time           ADDR_event;
    reg            FROMOE;
    reg            FROMCE;
    reg            FROMADDR;
    reg            OPENLATCH;
    integer        OEDQ_01;
    integer        CEDQ_01;
    integer        ADDRDQIN_01;
    integer        ADDRDQPAGE_01;
    reg [15:0]     TempData;

    wire InitialPageAccess;
    assign InitialPageAccess = FROMADDR && ~Pmode;

    wire SubsequentPageAccess;
    assign SubsequentPageAccess = FROMADDR && Pmode;

    wire CLK_rising;
    assign CLK_rising = RCR[6] && ~CENeg_ipd;

    wire CLK_falling;
    assign CLK_falling = ~(RCR[6]) && ~CENeg_ipd;

///////////////////////////////////////////////////////////////////////////////
//Interconnect Path Delay Section
///////////////////////////////////////////////////////////////////////////////
    buf   (A24_ipd, A24);
    buf   (A23_ipd, A23);
    buf   (A22_ipd, A22);
    buf   (A21_ipd, A21);
    buf   (A20_ipd, A20);
    buf   (A19_ipd, A19);
    buf   (A18_ipd, A18);
    buf   (A17_ipd, A17);
    buf   (A16_ipd, A16);
    buf   (A15_ipd, A15);
    buf   (A14_ipd, A14);
    buf   (A13_ipd, A13);
    buf   (A12_ipd, A12);
    buf   (A11_ipd, A11);
    buf   (A10_ipd, A10);
    buf   (A9_ipd , A9 );
    buf   (A8_ipd , A8 );
    buf   (A7_ipd , A7 );
    buf   (A6_ipd , A6 );
    buf   (A5_ipd , A5 );
    buf   (A4_ipd , A4 );
    buf   (A3_ipd , A3 );
    buf   (A2_ipd , A2 );
    buf   (A1_ipd , A1 );

    buf   (DQ15_ipd, DQ15);
    buf   (DQ14_ipd, DQ14);
    buf   (DQ13_ipd, DQ13);
    buf   (DQ12_ipd, DQ12);
    buf   (DQ11_ipd, DQ11);
    buf   (DQ10_ipd, DQ10);
    buf   (DQ9_ipd , DQ9 );
    buf   (DQ8_ipd , DQ8 );
    buf   (DQ7_ipd , DQ7 );
    buf   (DQ6_ipd , DQ6 );
    buf   (DQ5_ipd , DQ5 );
    buf   (DQ4_ipd , DQ4 );
    buf   (DQ3_ipd , DQ3 );
    buf   (DQ2_ipd , DQ2 );
    buf   (DQ1_ipd , DQ1 );
    buf   (DQ0_ipd , DQ0 );

    buf   (RSTNeg_ipd , RSTNeg );
    buf   (ADVNeg_ipd , ADVNeg );
    buf   (CLK_ipd    , CLK );
    buf   (CENeg_ipd  , CENeg );
    buf   (OENeg_ipd  , OENeg );
    buf   (WENeg_ipd  , WENeg );
    buf   (WPNeg_ipd  , WPNeg );

///////////////////////////////////////////////////////////////////////////////
// Propagation  delay Section
///////////////////////////////////////////////////////////////////////////////
    nmos   (DQ15,   DQ15_Pass , 1);
    nmos   (DQ14,   DQ14_Pass , 1);
    nmos   (DQ13,   DQ13_Pass , 1);
    nmos   (DQ12,   DQ12_Pass , 1);
    nmos   (DQ11,   DQ11_Pass , 1);
    nmos   (DQ10,   DQ10_Pass , 1);
    nmos   (DQ9 ,   DQ9_Pass  , 1);
    nmos   (DQ8 ,   DQ8_Pass  , 1);
    nmos   (DQ7 ,   DQ7_Pass  , 1);
    nmos   (DQ6 ,   DQ6_Pass  , 1);
    nmos   (DQ5 ,   DQ5_Pass  , 1);
    nmos   (DQ4 ,   DQ4_Pass  , 1);
    nmos   (DQ3 ,   DQ3_Pass  , 1);
    nmos   (DQ2 ,   DQ2_Pass  , 1);
    nmos   (DQ1 ,   DQ1_Pass  , 1);
    nmos   (DQ0 ,   DQ0_Pass  , 1);

    nmos   (WAITOut, WAITOut_zd, 1);

    wire deg;

specify
    // tipd delays: interconnect path delays , mapped to input port delays.
    // In Verilog is not necessary to declare any tipd_ delay variables,
    // they can be taken from SDF file
    // With all the other delays real delays would be taken from SDF file

    // tpd delays
    specparam           tpd_A1_DQ0             =1;
    specparam           tpd_A1_DQ1             =1;
    specparam           tpd_A1_DQ2             =1;
    specparam           tpd_A1_DQ3             =1;
    specparam           tpd_A1_DQ4             =1;
    specparam           tpd_A1_DQ5             =1;
    specparam           tpd_A1_DQ6             =1;
    specparam           tpd_A1_DQ7             =1;
    specparam           tpd_A1_DQ8             =1;
    specparam           tpd_A1_DQ9             =1;
    specparam           tpd_A1_DQ10            =1;
    specparam           tpd_A1_DQ11            =1;
    specparam           tpd_A1_DQ12            =1;
    specparam           tpd_A1_DQ13            =1;
    specparam           tpd_A1_DQ14            =1;
    specparam           tpd_A1_DQ15            =1;
    specparam           tpd_A2_DQ0             =1;
    specparam           tpd_A2_DQ1             =1;
    specparam           tpd_A2_DQ2             =1;
    specparam           tpd_A2_DQ3             =1;
    specparam           tpd_A2_DQ4             =1;
    specparam           tpd_A2_DQ5             =1;
    specparam           tpd_A2_DQ6             =1;
    specparam           tpd_A2_DQ7             =1;
    specparam           tpd_A2_DQ8             =1;
    specparam           tpd_A2_DQ9             =1;
    specparam           tpd_A2_DQ10            =1;
    specparam           tpd_A2_DQ11            =1;
    specparam           tpd_A2_DQ12            =1;
    specparam           tpd_A2_DQ13            =1;
    specparam           tpd_A2_DQ14            =1;
    specparam           tpd_A2_DQ15            =1;
    specparam           tpd_A3_DQ0             =1;
    specparam           tpd_A3_DQ1             =1;
    specparam           tpd_A3_DQ2             =1;
    specparam           tpd_A3_DQ3             =1;
    specparam           tpd_A3_DQ4             =1;
    specparam           tpd_A3_DQ5             =1;
    specparam           tpd_A3_DQ6             =1;
    specparam           tpd_A3_DQ7             =1;
    specparam           tpd_A3_DQ8             =1;
    specparam           tpd_A3_DQ9             =1;
    specparam           tpd_A3_DQ10            =1;
    specparam           tpd_A3_DQ11            =1;
    specparam           tpd_A3_DQ12            =1;
    specparam           tpd_A3_DQ13            =1;
    specparam           tpd_A3_DQ14            =1;
    specparam           tpd_A3_DQ15            =1;
    specparam           tpd_A4_DQ0             =1;
    specparam           tpd_A4_DQ1             =1;
    specparam           tpd_A4_DQ2             =1;
    specparam           tpd_A4_DQ3             =1;
    specparam           tpd_A4_DQ4             =1;
    specparam           tpd_A4_DQ5             =1;
    specparam           tpd_A4_DQ6             =1;
    specparam           tpd_A4_DQ7             =1;
    specparam           tpd_A4_DQ8             =1;
    specparam           tpd_A4_DQ9             =1;
    specparam           tpd_A4_DQ10            =1;
    specparam           tpd_A4_DQ11            =1;
    specparam           tpd_A4_DQ12            =1;
    specparam           tpd_A4_DQ13            =1;
    specparam           tpd_A4_DQ14            =1;
    specparam           tpd_A4_DQ15            =1;
    specparam           tpd_A5_DQ0             =1;
    specparam           tpd_A5_DQ1             =1;
    specparam           tpd_A5_DQ2             =1;
    specparam           tpd_A5_DQ3             =1;
    specparam           tpd_A5_DQ4             =1;
    specparam           tpd_A5_DQ5             =1;
    specparam           tpd_A5_DQ6             =1;
    specparam           tpd_A5_DQ7             =1;
    specparam           tpd_A5_DQ8             =1;
    specparam           tpd_A5_DQ9             =1;
    specparam           tpd_A5_DQ10            =1;
    specparam           tpd_A5_DQ11            =1;
    specparam           tpd_A5_DQ12            =1;
    specparam           tpd_A5_DQ13            =1;
    specparam           tpd_A5_DQ14            =1;
    specparam           tpd_A5_DQ15            =1;
    specparam           tpd_A6_DQ0             =1;
    specparam           tpd_A6_DQ1             =1;
    specparam           tpd_A6_DQ2             =1;
    specparam           tpd_A6_DQ3             =1;
    specparam           tpd_A6_DQ4             =1;
    specparam           tpd_A6_DQ5             =1;
    specparam           tpd_A6_DQ6             =1;
    specparam           tpd_A6_DQ7             =1;
    specparam           tpd_A6_DQ8             =1;
    specparam           tpd_A6_DQ9             =1;
    specparam           tpd_A6_DQ10            =1;
    specparam           tpd_A6_DQ11            =1;
    specparam           tpd_A6_DQ12            =1;
    specparam           tpd_A6_DQ13            =1;
    specparam           tpd_A6_DQ14            =1;
    specparam           tpd_A6_DQ15            =1;
    specparam           tpd_A7_DQ0             =1;
    specparam           tpd_A7_DQ1             =1;
    specparam           tpd_A7_DQ2             =1;
    specparam           tpd_A7_DQ3             =1;
    specparam           tpd_A7_DQ4             =1;
    specparam           tpd_A7_DQ5             =1;
    specparam           tpd_A7_DQ6             =1;
    specparam           tpd_A7_DQ7             =1;
    specparam           tpd_A7_DQ8             =1;
    specparam           tpd_A7_DQ9             =1;
    specparam           tpd_A7_DQ10            =1;
    specparam           tpd_A7_DQ11            =1;
    specparam           tpd_A7_DQ12            =1;
    specparam           tpd_A7_DQ13            =1;
    specparam           tpd_A7_DQ14            =1;
    specparam           tpd_A7_DQ15            =1;
    specparam           tpd_A8_DQ0             =1;
    specparam           tpd_A8_DQ1             =1;
    specparam           tpd_A8_DQ2             =1;
    specparam           tpd_A8_DQ3             =1;
    specparam           tpd_A8_DQ4             =1;
    specparam           tpd_A8_DQ5             =1;
    specparam           tpd_A8_DQ6             =1;
    specparam           tpd_A8_DQ7             =1;
    specparam           tpd_A8_DQ8             =1;
    specparam           tpd_A8_DQ9             =1;
    specparam           tpd_A8_DQ10            =1;
    specparam           tpd_A8_DQ11            =1;
    specparam           tpd_A8_DQ12            =1;
    specparam           tpd_A8_DQ13            =1;
    specparam           tpd_A8_DQ14            =1;
    specparam           tpd_A8_DQ15            =1;
    specparam           tpd_A9_DQ0             =1;
    specparam           tpd_A9_DQ1             =1;
    specparam           tpd_A9_DQ2             =1;
    specparam           tpd_A9_DQ3             =1;
    specparam           tpd_A9_DQ4             =1;
    specparam           tpd_A9_DQ5             =1;
    specparam           tpd_A9_DQ6             =1;
    specparam           tpd_A9_DQ7             =1;
    specparam           tpd_A9_DQ8             =1;
    specparam           tpd_A9_DQ9             =1;
    specparam           tpd_A9_DQ10            =1;
    specparam           tpd_A9_DQ11            =1;
    specparam           tpd_A9_DQ12            =1;
    specparam           tpd_A9_DQ13            =1;
    specparam           tpd_A9_DQ14            =1;
    specparam           tpd_A9_DQ15            =1;
    specparam           tpd_A10_DQ0            =1;
    specparam           tpd_A10_DQ1            =1;
    specparam           tpd_A10_DQ2            =1;
    specparam           tpd_A10_DQ3            =1;
    specparam           tpd_A10_DQ4            =1;
    specparam           tpd_A10_DQ5            =1;
    specparam           tpd_A10_DQ6            =1;
    specparam           tpd_A10_DQ7            =1;
    specparam           tpd_A10_DQ8            =1;
    specparam           tpd_A10_DQ9            =1;
    specparam           tpd_A10_DQ10           =1;
    specparam           tpd_A10_DQ11           =1;
    specparam           tpd_A10_DQ12           =1;
    specparam           tpd_A10_DQ13           =1;
    specparam           tpd_A10_DQ14           =1;
    specparam           tpd_A10_DQ15           =1;
    specparam           tpd_A11_DQ0            =1;
    specparam           tpd_A11_DQ1            =1;
    specparam           tpd_A11_DQ2            =1;
    specparam           tpd_A11_DQ3            =1;
    specparam           tpd_A11_DQ4            =1;
    specparam           tpd_A11_DQ5            =1;
    specparam           tpd_A11_DQ6            =1;
    specparam           tpd_A11_DQ7            =1;
    specparam           tpd_A11_DQ8            =1;
    specparam           tpd_A11_DQ9            =1;
    specparam           tpd_A11_DQ10           =1;
    specparam           tpd_A11_DQ11           =1;
    specparam           tpd_A11_DQ12           =1;
    specparam           tpd_A11_DQ13           =1;
    specparam           tpd_A11_DQ14           =1;
    specparam           tpd_A11_DQ15           =1;
    specparam           tpd_A12_DQ0            =1;
    specparam           tpd_A12_DQ1            =1;
    specparam           tpd_A12_DQ2            =1;
    specparam           tpd_A12_DQ3            =1;
    specparam           tpd_A12_DQ4            =1;
    specparam           tpd_A12_DQ5            =1;
    specparam           tpd_A12_DQ6            =1;
    specparam           tpd_A12_DQ7            =1;
    specparam           tpd_A12_DQ8            =1;
    specparam           tpd_A12_DQ9            =1;
    specparam           tpd_A12_DQ10           =1;
    specparam           tpd_A12_DQ11           =1;
    specparam           tpd_A12_DQ12           =1;
    specparam           tpd_A12_DQ13           =1;
    specparam           tpd_A12_DQ14           =1;
    specparam           tpd_A12_DQ15           =1;
    specparam           tpd_A13_DQ0            =1;
    specparam           tpd_A13_DQ1            =1;
    specparam           tpd_A13_DQ2            =1;
    specparam           tpd_A13_DQ3            =1;
    specparam           tpd_A13_DQ4            =1;
    specparam           tpd_A13_DQ5            =1;
    specparam           tpd_A13_DQ6            =1;
    specparam           tpd_A13_DQ7            =1;
    specparam           tpd_A13_DQ8            =1;
    specparam           tpd_A13_DQ9            =1;
    specparam           tpd_A13_DQ10           =1;
    specparam           tpd_A13_DQ11           =1;
    specparam           tpd_A13_DQ12           =1;
    specparam           tpd_A13_DQ13           =1;
    specparam           tpd_A13_DQ14           =1;
    specparam           tpd_A13_DQ15           =1;
    specparam           tpd_A14_DQ0            =1;
    specparam           tpd_A14_DQ1            =1;
    specparam           tpd_A14_DQ2            =1;
    specparam           tpd_A14_DQ3            =1;
    specparam           tpd_A14_DQ4            =1;
    specparam           tpd_A14_DQ5            =1;
    specparam           tpd_A14_DQ6            =1;
    specparam           tpd_A14_DQ7            =1;
    specparam           tpd_A14_DQ8            =1;
    specparam           tpd_A14_DQ9            =1;
    specparam           tpd_A14_DQ10           =1;
    specparam           tpd_A14_DQ11           =1;
    specparam           tpd_A14_DQ12           =1;
    specparam           tpd_A14_DQ13           =1;
    specparam           tpd_A14_DQ14           =1;
    specparam           tpd_A14_DQ15           =1;
    specparam           tpd_A15_DQ0            =1;
    specparam           tpd_A15_DQ1            =1;
    specparam           tpd_A15_DQ2            =1;
    specparam           tpd_A15_DQ3            =1;
    specparam           tpd_A15_DQ4            =1;
    specparam           tpd_A15_DQ5            =1;
    specparam           tpd_A15_DQ6            =1;
    specparam           tpd_A15_DQ7            =1;
    specparam           tpd_A15_DQ8            =1;
    specparam           tpd_A15_DQ9            =1;
    specparam           tpd_A15_DQ10           =1;
    specparam           tpd_A15_DQ11           =1;
    specparam           tpd_A15_DQ12           =1;
    specparam           tpd_A15_DQ13           =1;
    specparam           tpd_A15_DQ14           =1;
    specparam           tpd_A15_DQ15           =1;
    specparam           tpd_A16_DQ0            =1;
    specparam           tpd_A16_DQ1            =1;
    specparam           tpd_A16_DQ2            =1;
    specparam           tpd_A16_DQ3            =1;
    specparam           tpd_A16_DQ4            =1;
    specparam           tpd_A16_DQ5            =1;
    specparam           tpd_A16_DQ6            =1;
    specparam           tpd_A16_DQ7            =1;
    specparam           tpd_A16_DQ8            =1;
    specparam           tpd_A16_DQ9            =1;
    specparam           tpd_A16_DQ10           =1;
    specparam           tpd_A16_DQ11           =1;
    specparam           tpd_A16_DQ12           =1;
    specparam           tpd_A16_DQ13           =1;
    specparam           tpd_A16_DQ14           =1;
    specparam           tpd_A16_DQ15           =1;
    specparam           tpd_A17_DQ0            =1;
    specparam           tpd_A17_DQ1            =1;
    specparam           tpd_A17_DQ2            =1;
    specparam           tpd_A17_DQ3            =1;
    specparam           tpd_A17_DQ4            =1;
    specparam           tpd_A17_DQ5            =1;
    specparam           tpd_A17_DQ6            =1;
    specparam           tpd_A17_DQ7            =1;
    specparam           tpd_A17_DQ8            =1;
    specparam           tpd_A17_DQ9            =1;
    specparam           tpd_A17_DQ10           =1;
    specparam           tpd_A17_DQ11           =1;
    specparam           tpd_A17_DQ12           =1;
    specparam           tpd_A17_DQ13           =1;
    specparam           tpd_A17_DQ14           =1;
    specparam           tpd_A17_DQ15           =1;
    specparam           tpd_A18_DQ0            =1;
    specparam           tpd_A18_DQ1            =1;
    specparam           tpd_A18_DQ2            =1;
    specparam           tpd_A18_DQ3            =1;
    specparam           tpd_A18_DQ4            =1;
    specparam           tpd_A18_DQ5            =1;
    specparam           tpd_A18_DQ6            =1;
    specparam           tpd_A18_DQ7            =1;
    specparam           tpd_A18_DQ8            =1;
    specparam           tpd_A18_DQ9            =1;
    specparam           tpd_A18_DQ10           =1;
    specparam           tpd_A18_DQ11           =1;
    specparam           tpd_A18_DQ12           =1;
    specparam           tpd_A18_DQ13           =1;
    specparam           tpd_A18_DQ14           =1;
    specparam           tpd_A18_DQ15           =1;
    specparam           tpd_A19_DQ0            =1;
    specparam           tpd_A19_DQ1            =1;
    specparam           tpd_A19_DQ2            =1;
    specparam           tpd_A19_DQ3            =1;
    specparam           tpd_A19_DQ4            =1;
    specparam           tpd_A19_DQ5            =1;
    specparam           tpd_A19_DQ6            =1;
    specparam           tpd_A19_DQ7            =1;
    specparam           tpd_A19_DQ8            =1;
    specparam           tpd_A19_DQ9            =1;
    specparam           tpd_A19_DQ10           =1;
    specparam           tpd_A19_DQ11           =1;
    specparam           tpd_A19_DQ12           =1;
    specparam           tpd_A19_DQ13           =1;
    specparam           tpd_A19_DQ14           =1;
    specparam           tpd_A19_DQ15           =1;
    specparam           tpd_A20_DQ0            =1;
    specparam           tpd_A20_DQ1            =1;
    specparam           tpd_A20_DQ2            =1;
    specparam           tpd_A20_DQ3            =1;
    specparam           tpd_A20_DQ4            =1;
    specparam           tpd_A20_DQ5            =1;
    specparam           tpd_A20_DQ6            =1;
    specparam           tpd_A20_DQ7            =1;
    specparam           tpd_A20_DQ8            =1;
    specparam           tpd_A20_DQ9            =1;
    specparam           tpd_A20_DQ10           =1;
    specparam           tpd_A20_DQ11           =1;
    specparam           tpd_A20_DQ12           =1;
    specparam           tpd_A20_DQ13           =1;
    specparam           tpd_A20_DQ14           =1;
    specparam           tpd_A20_DQ15           =1;
    specparam           tpd_A21_DQ0            =1;
    specparam           tpd_A21_DQ1            =1;
    specparam           tpd_A21_DQ2            =1;
    specparam           tpd_A21_DQ3            =1;
    specparam           tpd_A21_DQ4            =1;
    specparam           tpd_A21_DQ5            =1;
    specparam           tpd_A21_DQ6            =1;
    specparam           tpd_A21_DQ7            =1;
    specparam           tpd_A21_DQ8            =1;
    specparam           tpd_A21_DQ9            =1;
    specparam           tpd_A21_DQ10           =1;
    specparam           tpd_A21_DQ11           =1;
    specparam           tpd_A21_DQ12           =1;
    specparam           tpd_A21_DQ13           =1;
    specparam           tpd_A21_DQ14           =1;
    specparam           tpd_A21_DQ15           =1;
    specparam           tpd_A22_DQ0            =1;
    specparam           tpd_A22_DQ1            =1;
    specparam           tpd_A22_DQ2            =1;
    specparam           tpd_A22_DQ3            =1;
    specparam           tpd_A22_DQ4            =1;
    specparam           tpd_A22_DQ5            =1;
    specparam           tpd_A22_DQ6            =1;
    specparam           tpd_A22_DQ7            =1;
    specparam           tpd_A22_DQ8            =1;
    specparam           tpd_A22_DQ9            =1;
    specparam           tpd_A22_DQ10           =1;
    specparam           tpd_A22_DQ11           =1;
    specparam           tpd_A22_DQ12           =1;
    specparam           tpd_A22_DQ13           =1;
    specparam           tpd_A22_DQ14           =1;
    specparam           tpd_A22_DQ15           =1;
    specparam           tpd_A23_DQ0            =1;
    specparam           tpd_A23_DQ1            =1;
    specparam           tpd_A23_DQ2            =1;
    specparam           tpd_A23_DQ3            =1;
    specparam           tpd_A23_DQ4            =1;
    specparam           tpd_A23_DQ5            =1;
    specparam           tpd_A23_DQ6            =1;
    specparam           tpd_A23_DQ7            =1;
    specparam           tpd_A23_DQ8            =1;
    specparam           tpd_A23_DQ9            =1;
    specparam           tpd_A23_DQ10           =1;
    specparam           tpd_A23_DQ11           =1;
    specparam           tpd_A23_DQ12           =1;
    specparam           tpd_A23_DQ13           =1;
    specparam           tpd_A23_DQ14           =1;
    specparam           tpd_A23_DQ15           =1;
    specparam           tpd_A24_DQ0            =1;
    specparam           tpd_A24_DQ1            =1;
    specparam           tpd_A24_DQ2            =1;
    specparam           tpd_A24_DQ3            =1;
    specparam           tpd_A24_DQ4            =1;
    specparam           tpd_A24_DQ5            =1;
    specparam           tpd_A24_DQ6            =1;
    specparam           tpd_A24_DQ7            =1;
    specparam           tpd_A24_DQ8            =1;
    specparam           tpd_A24_DQ9            =1;
    specparam           tpd_A24_DQ10           =1;
    specparam           tpd_A24_DQ11           =1;
    specparam           tpd_A24_DQ12           =1;
    specparam           tpd_A24_DQ13           =1;
    specparam           tpd_A24_DQ14           =1;
    specparam           tpd_A24_DQ15           =1;

    specparam           tpd_CENeg_DQ0           =1;
    specparam           tpd_CENeg_DQ1           =1;
    specparam           tpd_CENeg_DQ2           =1;
    specparam           tpd_CENeg_DQ3           =1;
    specparam           tpd_CENeg_DQ4           =1;
    specparam           tpd_CENeg_DQ5           =1;
    specparam           tpd_CENeg_DQ6           =1;
    specparam           tpd_CENeg_DQ7           =1;
    specparam           tpd_CENeg_DQ8           =1;
    specparam           tpd_CENeg_DQ9           =1;
    specparam           tpd_CENeg_DQ10          =1;
    specparam           tpd_CENeg_DQ11          =1;
    specparam           tpd_CENeg_DQ12          =1;
    specparam           tpd_CENeg_DQ13          =1;
    specparam           tpd_CENeg_DQ14          =1;
    specparam           tpd_CENeg_DQ15          =1;

    specparam           tpd_OENeg_DQ0           =1;
    specparam           tpd_OENeg_DQ1           =1;
    specparam           tpd_OENeg_DQ2           =1;
    specparam           tpd_OENeg_DQ3           =1;
    specparam           tpd_OENeg_DQ4           =1;
    specparam           tpd_OENeg_DQ5           =1;
    specparam           tpd_OENeg_DQ6           =1;
    specparam           tpd_OENeg_DQ7           =1;
    specparam           tpd_OENeg_DQ8           =1;
    specparam           tpd_OENeg_DQ9           =1;
    specparam           tpd_OENeg_DQ10          =1;
    specparam           tpd_OENeg_DQ11          =1;
    specparam           tpd_OENeg_DQ12          =1;
    specparam           tpd_OENeg_DQ13          =1;
    specparam           tpd_OENeg_DQ14          =1;
    specparam           tpd_OENeg_DQ15          =1;

    specparam           tpd_CLK_DQ0              =1;
    specparam           tpd_CLK_DQ1              =1;
    specparam           tpd_CLK_DQ2              =1;
    specparam           tpd_CLK_DQ3              =1;
    specparam           tpd_CLK_DQ4              =1;
    specparam           tpd_CLK_DQ5              =1;
    specparam           tpd_CLK_DQ6              =1;
    specparam           tpd_CLK_DQ7              =1;
    specparam           tpd_CLK_DQ8              =1;
    specparam           tpd_CLK_DQ9              =1;
    specparam           tpd_CLK_DQ10             =1;
    specparam           tpd_CLK_DQ11             =1;
    specparam           tpd_CLK_DQ12             =1;
    specparam           tpd_CLK_DQ13             =1;
    specparam           tpd_CLK_DQ14             =1;
    specparam           tpd_CLK_DQ15             =1;

    specparam           tpd_CE0Neg_WAITOut       =1;
    specparam           tpd_OE0Neg_WAITOut       =1;
    specparam           tpd_CLK_WAITOut          =1;

    //tsetup values
    specparam           tsetup_A1_ADVNeg               =1;
    specparam           tsetup_A2_ADVNeg               =1;
    specparam           tsetup_A3_ADVNeg               =1;
    specparam           tsetup_A4_ADVNeg               =1;
    specparam           tsetup_A5_ADVNeg               =1;
    specparam           tsetup_A6_ADVNeg               =1;
    specparam           tsetup_A7_ADVNeg               =1;
    specparam           tsetup_A8_ADVNeg               =1;
    specparam           tsetup_A9_ADVNeg               =1;
    specparam           tsetup_A10_ADVNeg              =1;
    specparam           tsetup_A11_ADVNeg              =1;
    specparam           tsetup_A12_ADVNeg              =1;
    specparam           tsetup_A13_ADVNeg              =1;
    specparam           tsetup_A14_ADVNeg              =1;
    specparam           tsetup_A15_ADVNeg              =1;
    specparam           tsetup_A16_ADVNeg              =1;
    specparam           tsetup_A17_ADVNeg              =1;
    specparam           tsetup_A18_ADVNeg              =1;
    specparam           tsetup_A19_ADVNeg              =1;
    specparam           tsetup_A20_ADVNeg              =1;
    specparam           tsetup_A21_ADVNeg              =1;
    specparam           tsetup_A22_ADVNeg              =1;
    specparam           tsetup_A23_ADVNeg              =1;
    specparam           tsetup_A24_ADVNeg              =1;

    specparam           tsetup_CENeg_ADVNeg            =1;
    specparam           tsetup_RSTNeg_ADVNeg           =1;
    specparam           tsetup_CLK_ADVNeg              =1;
    specparam           tsetup_WENeg_ADVNeg            =1;

    specparam           tsetup_A1_CLK                  =1;
    specparam           tsetup_A2_CLK                  =1;
    specparam           tsetup_A3_CLK                  =1;
    specparam           tsetup_A4_CLK                  =1;
    specparam           tsetup_A5_CLK                  =1;
    specparam           tsetup_A6_CLK                  =1;
    specparam           tsetup_A7_CLK                  =1;
    specparam           tsetup_A8_CLK                  =1;
    specparam           tsetup_A9_CLK                  =1;
    specparam           tsetup_A10_CLK                 =1;
    specparam           tsetup_A11_CLK                 =1;
    specparam           tsetup_A12_CLK                 =1;
    specparam           tsetup_A13_CLK                 =1;
    specparam           tsetup_A14_CLK                 =1;
    specparam           tsetup_A15_CLK                 =1;
    specparam           tsetup_A16_CLK                 =1;
    specparam           tsetup_A17_CLK                 =1;
    specparam           tsetup_A18_CLK                 =1;
    specparam           tsetup_A19_CLK                 =1;
    specparam           tsetup_A20_CLK                 =1;
    specparam           tsetup_A21_CLK                 =1;
    specparam           tsetup_A22_CLK                 =1;
    specparam           tsetup_A23_CLK                 =1;
    specparam           tsetup_A24_CLK                 =1;

    specparam           tsetup_ADVNeg_CLK              =1;
    specparam           tsetup_CENeg_CLK               =1;
    specparam           tsetup_WENeg_CLK               =1;

    specparam           tsetup_CENeg_WENeg             =1;

    specparam           tsetup_DQ0_WENeg               =1;
    specparam           tsetup_DQ1_WENeg               =1;
    specparam           tsetup_DQ2_WENeg               =1;
    specparam           tsetup_DQ3_WENeg               =1;
    specparam           tsetup_DQ4_WENeg               =1;
    specparam           tsetup_DQ5_WENeg               =1;
    specparam           tsetup_DQ6_WENeg               =1;
    specparam           tsetup_DQ7_WENeg               =1;
    specparam           tsetup_DQ8_WENeg               =1;
    specparam           tsetup_DQ9_WENeg               =1;
    specparam           tsetup_DQ10_WENeg              =1;
    specparam           tsetup_DQ11_WENeg              =1;
    specparam           tsetup_DQ12_WENeg              =1;
    specparam           tsetup_DQ13_WENeg              =1;
    specparam           tsetup_DQ14_WENeg              =1;
    specparam           tsetup_DQ15_WENeg              =1;

    specparam           tsetup_A1_WENeg                =1;
    specparam           tsetup_A2_WENeg                =1;
    specparam           tsetup_A3_WENeg                =1;
    specparam           tsetup_A4_WENeg                =1;
    specparam           tsetup_A5_WENeg                =1;
    specparam           tsetup_A6_WENeg                =1;
    specparam           tsetup_A7_WENeg                =1;
    specparam           tsetup_A8_WENeg                =1;
    specparam           tsetup_A9_WENeg                =1;
    specparam           tsetup_A10_WENeg               =1;
    specparam           tsetup_A11_WENeg               =1;
    specparam           tsetup_A12_WENeg               =1;
    specparam           tsetup_A13_WENeg               =1;
    specparam           tsetup_A14_WENeg               =1;
    specparam           tsetup_A15_WENeg               =1;
    specparam           tsetup_A16_WENeg               =1;
    specparam           tsetup_A17_WENeg               =1;
    specparam           tsetup_A18_WENeg               =1;
    specparam           tsetup_A19_WENeg               =1;
    specparam           tsetup_A20_WENeg               =1;
    specparam           tsetup_A21_WENeg               =1;
    specparam           tsetup_A22_WENeg               =1;
    specparam           tsetup_A23_WENeg               =1;
    specparam           tsetup_A24_WENeg               =1;

    specparam           tsetup_WPNeg_WENeg             =1;
    specparam           tsetup_ADVNeg_WENeg            =1;
    specparam           tsetup_CLK_WENeg               =1;

    specparam           tsetup_WENeg_OENeg             =1;

    // thold values: hold times
    specparam           thold_A1_ADVNeg                =1;
    specparam           thold_A2_ADVNeg                =1;
    specparam           thold_A3_ADVNeg                =1;
    specparam           thold_A4_ADVNeg                =1;
    specparam           thold_A5_ADVNeg                =1;
    specparam           thold_A6_ADVNeg                =1;
    specparam           thold_A7_ADVNeg                =1;
    specparam           thold_A8_ADVNeg                =1;
    specparam           thold_A9_ADVNeg                =1;
    specparam           thold_A10_ADVNeg               =1;
    specparam           thold_A11_ADVNeg               =1;
    specparam           thold_A12_ADVNeg               =1;
    specparam           thold_A13_ADVNeg               =1;
    specparam           thold_A14_ADVNeg               =1;
    specparam           thold_A15_ADVNeg               =1;
    specparam           thold_A16_ADVNeg               =1;
    specparam           thold_A17_ADVNeg               =1;
    specparam           thold_A18_ADVNeg               =1;
    specparam           thold_A19_ADVNeg               =1;
    specparam           thold_A20_ADVNeg               =1;
    specparam           thold_A21_ADVNeg               =1;
    specparam           thold_A22_ADVNeg               =1;
    specparam           thold_A23_ADVNeg               =1;
    specparam           thold_A24_ADVNeg               =1;

    specparam           thold_A1_CLK                   =1;
    specparam           thold_A2_CLK                   =1;
    specparam           thold_A3_CLK                   =1;
    specparam           thold_A4_CLK                   =1;
    specparam           thold_A5_CLK                   =1;
    specparam           thold_A6_CLK                   =1;
    specparam           thold_A7_CLK                   =1;
    specparam           thold_A8_CLK                   =1;
    specparam           thold_A9_CLK                   =1;
    specparam           thold_A10_CLK                  =1;
    specparam           thold_A11_CLK                  =1;
    specparam           thold_A12_CLK                  =1;
    specparam           thold_A13_CLK                  =1;
    specparam           thold_A14_CLK                  =1;
    specparam           thold_A15_CLK                  =1;
    specparam           thold_A16_CLK                  =1;
    specparam           thold_A17_CLK                  =1;
    specparam           thold_A18_CLK                  =1;
    specparam           thold_A19_CLK                  =1;
    specparam           thold_A20_CLK                  =1;
    specparam           thold_A21_CLK                  =1;
    specparam           thold_A22_CLK                  =1;
    specparam           thold_A23_CLK                  =1;
    specparam           thold_A24_CLK                  =1;

    specparam           thold_CENeg_WENeg              =1;

    specparam           thold_DQ0_WENeg                =1;
    specparam           thold_DQ1_WENeg                =1;
    specparam           thold_DQ2_WENeg                =1;
    specparam           thold_DQ3_WENeg                =1;
    specparam           thold_DQ4_WENeg                =1;
    specparam           thold_DQ5_WENeg                =1;
    specparam           thold_DQ6_WENeg                =1;
    specparam           thold_DQ7_WENeg                =1;
    specparam           thold_DQ8_WENeg                =1;
    specparam           thold_DQ9_WENeg                =1;
    specparam           thold_DQ10_WENeg               =1;
    specparam           thold_DQ11_WENeg               =1;
    specparam           thold_DQ12_WENeg               =1;
    specparam           thold_DQ13_WENeg               =1;
    specparam           thold_DQ14_WENeg               =1;
    specparam           thold_DQ15_WENeg               =1;

    specparam           thold_A1_WENeg                 =1;
    specparam           thold_A2_WENeg                 =1;
    specparam           thold_A3_WENeg                 =1;
    specparam           thold_A4_WENeg                 =1;
    specparam           thold_A5_WENeg                 =1;
    specparam           thold_A6_WENeg                 =1;
    specparam           thold_A7_WENeg                 =1;
    specparam           thold_A8_WENeg                 =1;
    specparam           thold_A9_WENeg                 =1;
    specparam           thold_A10_WENeg                =1;
    specparam           thold_A11_WENeg                =1;
    specparam           thold_A12_WENeg                =1;
    specparam           thold_A13_WENeg                =1;
    specparam           thold_A14_WENeg                =1;
    specparam           thold_A15_WENeg                =1;
    specparam           thold_A16_WENeg                =1;
    specparam           thold_A17_WENeg                =1;
    specparam           thold_A18_WENeg                =1;
    specparam           thold_A19_WENeg                =1;
    specparam           thold_A20_WENeg                =1;
    specparam           thold_A21_WENeg                =1;
    specparam           thold_A22_WENeg                =1;
    specparam           thold_A23_WENeg                =1;
    specparam           thold_A24_WENeg                =1;

    //tpw values
    specparam       tpw_CENeg_posedge    = 1;

    specparam       tpw_ADVNeg_posedge   = 1;
    specparam       tpw_ADVNeg_negedge   = 1;

    specparam       tpw_WENeg_negedge    = 1;
    specparam       tpw_WENeg_posedge    = 1;

    specparam       tpw_RSTNeg_negedge   = 1;

    specparam       tpw_CLK_posedge      = 1;
    specparam       tpw_CLK_negedge      = 1;
    specparam       tperiod_CLK          = 1;

    // tdevice values: values for internal delays
    `ifdef SPEEDSIM
        // Program BUffProgram
        specparam   tdevice_BuffProgram             = 88000;
        // Program BUffProgram
        specparam   tdevice_BuffProgram9V           = 68000;
        // Program BEFP
        specparam   tdevice_BEFP                    = 32000;
        // Program EraseParameter
        specparam   tdevice_EraseParameter_td       = 2500;
        // Program EraseMain
        specparam   tdevice_EraseMain_td            = 4000;
    `else
        // Program BUffProgram
        specparam   tdevice_BuffProgram             = 880000;
        // Program BUffProgram
        specparam   tdevice_BuffProgram9V           = 680000;
        // Program BEFP
        specparam   tdevice_BEFP                    = 320000;
        // Program EraseParameter
        specparam   tdevice_EraseParameter_td       = 2500000;
        // Program EraseMain
        specparam   tdevice_EraseMain_td            = 4000000;
    `endif // SPEEDSIM

    // Program Word
    specparam   tdevice_WordProgram             = 200000;
    // Program Word
    specparam   tdevice_WordProgram9V           = 190000;
    // Program BEFPsetup
    specparam   tdevice_BEFPsetup               = 5000;
    // Program ProgramSuspend
    specparam   tdevice_ProgramSuspend          = 25000;
    // Program ProgramSuspend
    specparam   tdevice_EraseSuspend            = 25000;
    // Reset during Program or Erase
    specparam   tdevice_RstDuringErsPrg         = 25000;

///////////////////////////////////////////////////////////////////////////////
// Input Port  Delays  don't require Verilog description
///////////////////////////////////////////////////////////////////////////////
// Path delays                                                               //
///////////////////////////////////////////////////////////////////////////////
    if (InitialPageAccess) (A1 *> DQ0)  = tpd_A1_DQ0;
    if (InitialPageAccess) (A1 *> DQ1)  = tpd_A1_DQ1;
    if (InitialPageAccess) (A1 *> DQ2)  = tpd_A1_DQ2;
    if (InitialPageAccess) (A1 *> DQ3)  = tpd_A1_DQ3;
    if (InitialPageAccess) (A1 *> DQ4)  = tpd_A1_DQ4;
    if (InitialPageAccess) (A1 *> DQ5)  = tpd_A1_DQ5;
    if (InitialPageAccess) (A1 *> DQ6)  = tpd_A1_DQ6;
    if (InitialPageAccess) (A1 *> DQ7)  = tpd_A1_DQ7;
    if (InitialPageAccess) (A1 *> DQ8)  = tpd_A1_DQ8;
    if (InitialPageAccess) (A1 *> DQ9)  = tpd_A1_DQ9;
    if (InitialPageAccess) (A1 *> DQ10) = tpd_A1_DQ10;
    if (InitialPageAccess) (A1 *> DQ11) = tpd_A1_DQ11;
    if (InitialPageAccess) (A1 *> DQ12) = tpd_A1_DQ12;
    if (InitialPageAccess) (A1 *> DQ13) = tpd_A1_DQ13;
    if (InitialPageAccess) (A1 *> DQ14) = tpd_A1_DQ14;
    if (InitialPageAccess) (A1 *> DQ15) = tpd_A1_DQ15;
    if (InitialPageAccess) (A2 *> DQ0)  = tpd_A2_DQ0;
    if (InitialPageAccess) (A2 *> DQ1)  = tpd_A2_DQ1;
    if (InitialPageAccess) (A2 *> DQ2)  = tpd_A2_DQ2;
    if (InitialPageAccess) (A2 *> DQ3)  = tpd_A2_DQ3;
    if (InitialPageAccess) (A2 *> DQ4)  = tpd_A2_DQ4;
    if (InitialPageAccess) (A2 *> DQ5)  = tpd_A2_DQ5;
    if (InitialPageAccess) (A2 *> DQ6)  = tpd_A2_DQ6;
    if (InitialPageAccess) (A2 *> DQ7)  = tpd_A2_DQ7;
    if (InitialPageAccess) (A2 *> DQ8)  = tpd_A2_DQ8;
    if (InitialPageAccess) (A2 *> DQ9)  = tpd_A2_DQ9;
    if (InitialPageAccess) (A2 *> DQ10) = tpd_A2_DQ10;
    if (InitialPageAccess) (A2 *> DQ11) = tpd_A2_DQ11;
    if (InitialPageAccess) (A2 *> DQ12) = tpd_A2_DQ12;
    if (InitialPageAccess) (A2 *> DQ13) = tpd_A2_DQ13;
    if (InitialPageAccess) (A2 *> DQ14) = tpd_A2_DQ14;
    if (InitialPageAccess) (A2 *> DQ15) = tpd_A2_DQ15;
    if (InitialPageAccess) (A3 *> DQ0)  = tpd_A3_DQ0;
    if (InitialPageAccess) (A3 *> DQ1)  = tpd_A3_DQ1;
    if (InitialPageAccess) (A3 *> DQ2)  = tpd_A3_DQ2;
    if (InitialPageAccess) (A3 *> DQ3)  = tpd_A3_DQ3;
    if (InitialPageAccess) (A3 *> DQ4)  = tpd_A3_DQ4;
    if (InitialPageAccess) (A3 *> DQ5)  = tpd_A3_DQ5;
    if (InitialPageAccess) (A3 *> DQ6)  = tpd_A3_DQ6;
    if (InitialPageAccess) (A3 *> DQ7)  = tpd_A3_DQ7;
    if (InitialPageAccess) (A3 *> DQ8)  = tpd_A3_DQ8;
    if (InitialPageAccess) (A3 *> DQ9)  = tpd_A3_DQ9;
    if (InitialPageAccess) (A3 *> DQ10) = tpd_A3_DQ10;
    if (InitialPageAccess) (A3 *> DQ11) = tpd_A3_DQ11;
    if (InitialPageAccess) (A3 *> DQ12) = tpd_A3_DQ12;
    if (InitialPageAccess) (A3 *> DQ13) = tpd_A3_DQ13;
    if (InitialPageAccess) (A3 *> DQ14) = tpd_A3_DQ14;
    if (InitialPageAccess) (A3 *> DQ15) = tpd_A3_DQ15;
    if (InitialPageAccess) (A4 *> DQ0)  = tpd_A4_DQ0;
    if (InitialPageAccess) (A4 *> DQ1)  = tpd_A4_DQ1;
    if (InitialPageAccess) (A4 *> DQ2)  = tpd_A4_DQ2;
    if (InitialPageAccess) (A4 *> DQ3)  = tpd_A4_DQ3;
    if (InitialPageAccess) (A4 *> DQ4)  = tpd_A4_DQ4;
    if (InitialPageAccess) (A4 *> DQ5)  = tpd_A4_DQ5;
    if (InitialPageAccess) (A4 *> DQ6)  = tpd_A4_DQ6;
    if (InitialPageAccess) (A4 *> DQ7)  = tpd_A4_DQ7;
    if (InitialPageAccess) (A4 *> DQ8)  = tpd_A4_DQ8;
    if (InitialPageAccess) (A4 *> DQ9)  = tpd_A4_DQ9;
    if (InitialPageAccess) (A4 *> DQ10) = tpd_A4_DQ10;
    if (InitialPageAccess) (A4 *> DQ11) = tpd_A4_DQ11;
    if (InitialPageAccess) (A4 *> DQ12) = tpd_A4_DQ12;
    if (InitialPageAccess) (A4 *> DQ13) = tpd_A4_DQ13;
    if (InitialPageAccess) (A4 *> DQ14) = tpd_A4_DQ14;
    if (InitialPageAccess) (A4 *> DQ15) = tpd_A4_DQ15;
    if (InitialPageAccess) (A5 *> DQ0)  = tpd_A5_DQ0;
    if (InitialPageAccess) (A5 *> DQ1)  = tpd_A5_DQ1;
    if (InitialPageAccess) (A5 *> DQ2)  = tpd_A5_DQ2;
    if (InitialPageAccess) (A5 *> DQ3)  = tpd_A5_DQ3;
    if (InitialPageAccess) (A5 *> DQ4)  = tpd_A5_DQ4;
    if (InitialPageAccess) (A5 *> DQ5)  = tpd_A5_DQ5;
    if (InitialPageAccess) (A5 *> DQ6)  = tpd_A5_DQ6;
    if (InitialPageAccess) (A5 *> DQ7)  = tpd_A5_DQ7;
    if (InitialPageAccess) (A5 *> DQ8)  = tpd_A5_DQ8;
    if (InitialPageAccess) (A5 *> DQ9)  = tpd_A5_DQ9;
    if (InitialPageAccess) (A5 *> DQ10) = tpd_A5_DQ10;
    if (InitialPageAccess) (A5 *> DQ11) = tpd_A5_DQ11;
    if (InitialPageAccess) (A5 *> DQ12) = tpd_A5_DQ12;
    if (InitialPageAccess) (A5 *> DQ13) = tpd_A5_DQ13;
    if (InitialPageAccess) (A5 *> DQ14) = tpd_A5_DQ14;
    if (InitialPageAccess) (A5 *> DQ15) = tpd_A5_DQ15;
    if (InitialPageAccess) (A6 *> DQ0)  = tpd_A6_DQ0;
    if (InitialPageAccess) (A6 *> DQ1)  = tpd_A6_DQ1;
    if (InitialPageAccess) (A6 *> DQ2)  = tpd_A6_DQ2;
    if (InitialPageAccess) (A6 *> DQ3)  = tpd_A6_DQ3;
    if (InitialPageAccess) (A6 *> DQ4)  = tpd_A6_DQ4;
    if (InitialPageAccess) (A6 *> DQ5)  = tpd_A6_DQ5;
    if (InitialPageAccess) (A6 *> DQ6)  = tpd_A6_DQ6;
    if (InitialPageAccess) (A6 *> DQ7)  = tpd_A6_DQ7;
    if (InitialPageAccess) (A6 *> DQ8)  = tpd_A6_DQ8;
    if (InitialPageAccess) (A6 *> DQ9)  = tpd_A6_DQ9;
    if (InitialPageAccess) (A6 *> DQ10) = tpd_A6_DQ10;
    if (InitialPageAccess) (A6 *> DQ11) = tpd_A6_DQ11;
    if (InitialPageAccess) (A6 *> DQ12) = tpd_A6_DQ12;
    if (InitialPageAccess) (A6 *> DQ13) = tpd_A6_DQ13;
    if (InitialPageAccess) (A6 *> DQ14) = tpd_A6_DQ14;
    if (InitialPageAccess) (A6 *> DQ15) = tpd_A6_DQ15;
    if (InitialPageAccess) (A7 *> DQ0)  = tpd_A7_DQ0;
    if (InitialPageAccess) (A7 *> DQ1)  = tpd_A7_DQ1;
    if (InitialPageAccess) (A7 *> DQ2)  = tpd_A7_DQ2;
    if (InitialPageAccess) (A7 *> DQ3)  = tpd_A7_DQ3;
    if (InitialPageAccess) (A7 *> DQ4)  = tpd_A7_DQ4;
    if (InitialPageAccess) (A7 *> DQ5)  = tpd_A7_DQ5;
    if (InitialPageAccess) (A7 *> DQ6)  = tpd_A7_DQ6;
    if (InitialPageAccess) (A7 *> DQ7)  = tpd_A7_DQ7;
    if (InitialPageAccess) (A7 *> DQ8)  = tpd_A7_DQ8;
    if (InitialPageAccess) (A7 *> DQ9)  = tpd_A7_DQ9;
    if (InitialPageAccess) (A7 *> DQ10) = tpd_A7_DQ10;
    if (InitialPageAccess) (A7 *> DQ11) = tpd_A7_DQ11;
    if (InitialPageAccess) (A7 *> DQ12) = tpd_A7_DQ12;
    if (InitialPageAccess) (A7 *> DQ13) = tpd_A7_DQ13;
    if (InitialPageAccess) (A7 *> DQ14) = tpd_A7_DQ14;
    if (InitialPageAccess) (A7 *> DQ15) = tpd_A7_DQ15;
    if (InitialPageAccess) (A8 *> DQ0)  = tpd_A8_DQ0;
    if (InitialPageAccess) (A8 *> DQ1)  = tpd_A8_DQ1;
    if (InitialPageAccess) (A8 *> DQ2)  = tpd_A8_DQ2;
    if (InitialPageAccess) (A8 *> DQ3)  = tpd_A8_DQ3;
    if (InitialPageAccess) (A8 *> DQ4)  = tpd_A8_DQ4;
    if (InitialPageAccess) (A8 *> DQ5)  = tpd_A8_DQ5;
    if (InitialPageAccess) (A8 *> DQ6)  = tpd_A8_DQ6;
    if (InitialPageAccess) (A8 *> DQ7)  = tpd_A8_DQ7;
    if (InitialPageAccess) (A8 *> DQ8)  = tpd_A8_DQ8;
    if (InitialPageAccess) (A8 *> DQ9)  = tpd_A8_DQ9;
    if (InitialPageAccess) (A8 *> DQ10) = tpd_A8_DQ10;
    if (InitialPageAccess) (A8 *> DQ11) = tpd_A8_DQ11;
    if (InitialPageAccess) (A8 *> DQ12) = tpd_A8_DQ12;
    if (InitialPageAccess) (A8 *> DQ13) = tpd_A8_DQ13;
    if (InitialPageAccess) (A8 *> DQ14) = tpd_A8_DQ14;
    if (InitialPageAccess) (A8 *> DQ15) = tpd_A8_DQ15;
    if (InitialPageAccess) (A9 *> DQ0)  = tpd_A9_DQ0;
    if (InitialPageAccess) (A9 *> DQ1)  = tpd_A9_DQ1;
    if (InitialPageAccess) (A9 *> DQ2)  = tpd_A9_DQ2;
    if (InitialPageAccess) (A9 *> DQ3)  = tpd_A9_DQ3;
    if (InitialPageAccess) (A9 *> DQ4)  = tpd_A9_DQ4;
    if (InitialPageAccess) (A9 *> DQ5)  = tpd_A9_DQ5;
    if (InitialPageAccess) (A9 *> DQ6)  = tpd_A9_DQ6;
    if (InitialPageAccess) (A9 *> DQ7)  = tpd_A9_DQ7;
    if (InitialPageAccess) (A9 *> DQ8)  = tpd_A9_DQ8;
    if (InitialPageAccess) (A9 *> DQ9)  = tpd_A9_DQ9;
    if (InitialPageAccess) (A9 *> DQ10) = tpd_A9_DQ10;
    if (InitialPageAccess) (A9 *> DQ11) = tpd_A9_DQ11;
    if (InitialPageAccess) (A9 *> DQ12) = tpd_A9_DQ12;
    if (InitialPageAccess) (A9 *> DQ13) = tpd_A9_DQ13;
    if (InitialPageAccess) (A9 *> DQ14) = tpd_A9_DQ14;
    if (InitialPageAccess) (A9 *> DQ15) = tpd_A9_DQ15;
    if (InitialPageAccess) (A10 *> DQ0) = tpd_A10_DQ0;
    if (InitialPageAccess) (A10 *> DQ1) = tpd_A10_DQ1;
    if (InitialPageAccess) (A10 *> DQ2) = tpd_A10_DQ2;
    if (InitialPageAccess) (A10 *> DQ3) = tpd_A10_DQ3;
    if (InitialPageAccess) (A10 *> DQ4) = tpd_A10_DQ4;
    if (InitialPageAccess) (A10 *> DQ5) = tpd_A10_DQ5;
    if (InitialPageAccess) (A10 *> DQ6) = tpd_A10_DQ6;
    if (InitialPageAccess) (A10 *> DQ7) = tpd_A10_DQ7;
    if (InitialPageAccess) (A10 *> DQ8) = tpd_A10_DQ8;
    if (InitialPageAccess) (A10 *> DQ9) = tpd_A10_DQ9;
    if (InitialPageAccess) (A10 *> DQ10) = tpd_A10_DQ10;
    if (InitialPageAccess) (A10 *> DQ11) = tpd_A10_DQ11;
    if (InitialPageAccess) (A10 *> DQ12) = tpd_A10_DQ12;
    if (InitialPageAccess) (A10 *> DQ13) = tpd_A10_DQ13;
    if (InitialPageAccess) (A10 *> DQ14) = tpd_A10_DQ14;
    if (InitialPageAccess) (A10 *> DQ15) = tpd_A10_DQ15;
    if (InitialPageAccess) (A11 *> DQ0)  = tpd_A11_DQ0;
    if (InitialPageAccess) (A11 *> DQ1)  = tpd_A11_DQ1;
    if (InitialPageAccess) (A11 *> DQ2)  = tpd_A11_DQ2;
    if (InitialPageAccess) (A11 *> DQ3)  = tpd_A11_DQ3;
    if (InitialPageAccess) (A11 *> DQ4)  = tpd_A11_DQ4;
    if (InitialPageAccess) (A11 *> DQ5)  = tpd_A11_DQ5;
    if (InitialPageAccess) (A11 *> DQ6)  = tpd_A11_DQ6;
    if (InitialPageAccess) (A11 *> DQ7)  = tpd_A11_DQ7;
    if (InitialPageAccess) (A11 *> DQ8)  = tpd_A11_DQ8;
    if (InitialPageAccess) (A11 *> DQ9)  = tpd_A11_DQ9;
    if (InitialPageAccess) (A11 *> DQ10) = tpd_A11_DQ10;
    if (InitialPageAccess) (A11 *> DQ11) = tpd_A11_DQ11;
    if (InitialPageAccess) (A11 *> DQ12) = tpd_A11_DQ12;
    if (InitialPageAccess) (A11 *> DQ13) = tpd_A11_DQ13;
    if (InitialPageAccess) (A11 *> DQ14) = tpd_A11_DQ14;
    if (InitialPageAccess) (A11 *> DQ15) = tpd_A11_DQ15;
    if (InitialPageAccess) (A12 *> DQ0)  = tpd_A12_DQ0;
    if (InitialPageAccess) (A12 *> DQ1)  = tpd_A12_DQ1;
    if (InitialPageAccess) (A12 *> DQ2)  = tpd_A12_DQ2;
    if (InitialPageAccess) (A12 *> DQ3)  = tpd_A12_DQ3;
    if (InitialPageAccess) (A12 *> DQ4)  = tpd_A12_DQ4;
    if (InitialPageAccess) (A12 *> DQ5)  = tpd_A12_DQ5;
    if (InitialPageAccess) (A12 *> DQ6)  = tpd_A12_DQ6;
    if (InitialPageAccess) (A12 *> DQ7)  = tpd_A12_DQ7;
    if (InitialPageAccess) (A12 *> DQ8)  = tpd_A12_DQ8;
    if (InitialPageAccess) (A12 *> DQ9)  = tpd_A12_DQ9;
    if (InitialPageAccess) (A12 *> DQ10) = tpd_A12_DQ10;
    if (InitialPageAccess) (A12 *> DQ11) = tpd_A12_DQ11;
    if (InitialPageAccess) (A12 *> DQ12) = tpd_A12_DQ12;
    if (InitialPageAccess) (A12 *> DQ13) = tpd_A12_DQ13;
    if (InitialPageAccess) (A12 *> DQ14) = tpd_A12_DQ14;
    if (InitialPageAccess) (A12 *> DQ15) = tpd_A12_DQ15;
    if (InitialPageAccess) (A13 *> DQ0)  = tpd_A13_DQ0;
    if (InitialPageAccess) (A13 *> DQ1)  = tpd_A13_DQ1;
    if (InitialPageAccess) (A13 *> DQ2)  = tpd_A13_DQ2;
    if (InitialPageAccess) (A13 *> DQ3)  = tpd_A13_DQ3;
    if (InitialPageAccess) (A13 *> DQ4)  = tpd_A13_DQ4;
    if (InitialPageAccess) (A13 *> DQ5)  = tpd_A13_DQ5;
    if (InitialPageAccess) (A13 *> DQ6)  = tpd_A13_DQ6;
    if (InitialPageAccess) (A13 *> DQ7)  = tpd_A13_DQ7;
    if (InitialPageAccess) (A13 *> DQ8)  = tpd_A13_DQ8;
    if (InitialPageAccess) (A13 *> DQ9)  = tpd_A13_DQ9;
    if (InitialPageAccess) (A13 *> DQ10) = tpd_A13_DQ10;
    if (InitialPageAccess) (A13 *> DQ11) = tpd_A13_DQ11;
    if (InitialPageAccess) (A13 *> DQ12) = tpd_A13_DQ12;
    if (InitialPageAccess) (A13 *> DQ13) = tpd_A13_DQ13;
    if (InitialPageAccess) (A13 *> DQ14) = tpd_A13_DQ14;
    if (InitialPageAccess) (A13 *> DQ15) = tpd_A13_DQ15;
    if (InitialPageAccess) (A14 *> DQ0)  = tpd_A14_DQ0;
    if (InitialPageAccess) (A14 *> DQ1)  = tpd_A14_DQ1;
    if (InitialPageAccess) (A14 *> DQ2)  = tpd_A14_DQ2;
    if (InitialPageAccess) (A14 *> DQ3)  = tpd_A14_DQ3;
    if (InitialPageAccess) (A14 *> DQ4)  = tpd_A14_DQ4;
    if (InitialPageAccess) (A14 *> DQ5)  = tpd_A14_DQ5;
    if (InitialPageAccess) (A14 *> DQ6)  = tpd_A14_DQ6;
    if (InitialPageAccess) (A14 *> DQ7)  = tpd_A14_DQ7;
    if (InitialPageAccess) (A14 *> DQ8)  = tpd_A14_DQ8;
    if (InitialPageAccess) (A14 *> DQ9)  = tpd_A14_DQ9;
    if (InitialPageAccess) (A14 *> DQ10) = tpd_A14_DQ10;
    if (InitialPageAccess) (A14 *> DQ11) = tpd_A14_DQ11;
    if (InitialPageAccess) (A14 *> DQ12) = tpd_A14_DQ12;
    if (InitialPageAccess) (A14 *> DQ13) = tpd_A14_DQ13;
    if (InitialPageAccess) (A14 *> DQ14) = tpd_A14_DQ14;
    if (InitialPageAccess) (A14 *> DQ15) = tpd_A14_DQ15;
    if (InitialPageAccess) (A15 *> DQ0)  = tpd_A15_DQ0;
    if (InitialPageAccess) (A15 *> DQ1)  = tpd_A15_DQ1;
    if (InitialPageAccess) (A15 *> DQ2)  = tpd_A15_DQ2;
    if (InitialPageAccess) (A15 *> DQ3)  = tpd_A15_DQ3;
    if (InitialPageAccess) (A15 *> DQ4)  = tpd_A15_DQ4;
    if (InitialPageAccess) (A15 *> DQ5)  = tpd_A15_DQ5;
    if (InitialPageAccess) (A15 *> DQ6)  = tpd_A15_DQ6;
    if (InitialPageAccess) (A15 *> DQ7)  = tpd_A15_DQ7;
    if (InitialPageAccess) (A15 *> DQ8)  = tpd_A15_DQ8;
    if (InitialPageAccess) (A15 *> DQ9)  = tpd_A15_DQ9;
    if (InitialPageAccess) (A15 *> DQ10) = tpd_A15_DQ10;
    if (InitialPageAccess) (A15 *> DQ11) = tpd_A15_DQ11;
    if (InitialPageAccess) (A15 *> DQ12) = tpd_A15_DQ12;
    if (InitialPageAccess) (A15 *> DQ13) = tpd_A15_DQ13;
    if (InitialPageAccess) (A15 *> DQ14) = tpd_A15_DQ14;
    if (InitialPageAccess) (A15 *> DQ15) = tpd_A15_DQ15;
    if (InitialPageAccess) (A16 *> DQ0)  = tpd_A16_DQ0;
    if (InitialPageAccess) (A16 *> DQ1)  = tpd_A16_DQ1;
    if (InitialPageAccess) (A16 *> DQ2)  = tpd_A16_DQ2;
    if (InitialPageAccess) (A16 *> DQ3)  = tpd_A16_DQ3;
    if (InitialPageAccess) (A16 *> DQ4)  = tpd_A16_DQ4;
    if (InitialPageAccess) (A16 *> DQ5)  = tpd_A16_DQ5;
    if (InitialPageAccess) (A16 *> DQ6)  = tpd_A16_DQ6;
    if (InitialPageAccess) (A16 *> DQ7)  = tpd_A16_DQ7;
    if (InitialPageAccess) (A16 *> DQ8)  = tpd_A16_DQ8;
    if (InitialPageAccess) (A16 *> DQ9)  = tpd_A16_DQ9;
    if (InitialPageAccess) (A16 *> DQ10) = tpd_A16_DQ10;
    if (InitialPageAccess) (A16 *> DQ11) = tpd_A16_DQ11;
    if (InitialPageAccess) (A16 *> DQ12) = tpd_A16_DQ12;
    if (InitialPageAccess) (A16 *> DQ13) = tpd_A16_DQ13;
    if (InitialPageAccess) (A16 *> DQ14) = tpd_A16_DQ14;
    if (InitialPageAccess) (A16 *> DQ15) = tpd_A16_DQ15;
    if (InitialPageAccess) (A17 *> DQ0)  = tpd_A17_DQ0;
    if (InitialPageAccess) (A17 *> DQ1)  = tpd_A17_DQ1;
    if (InitialPageAccess) (A17 *> DQ2)  = tpd_A17_DQ2;
    if (InitialPageAccess) (A17 *> DQ3)  = tpd_A17_DQ3;
    if (InitialPageAccess) (A17 *> DQ4)  = tpd_A17_DQ4;
    if (InitialPageAccess) (A17 *> DQ5)  = tpd_A17_DQ5;
    if (InitialPageAccess) (A17 *> DQ6)  = tpd_A17_DQ6;
    if (InitialPageAccess) (A17 *> DQ7)  = tpd_A17_DQ7;
    if (InitialPageAccess) (A17 *> DQ8)  = tpd_A17_DQ8;
    if (InitialPageAccess) (A17 *> DQ9)  = tpd_A17_DQ9;
    if (InitialPageAccess) (A17 *> DQ10) = tpd_A17_DQ10;
    if (InitialPageAccess) (A17 *> DQ11) = tpd_A17_DQ11;
    if (InitialPageAccess) (A17 *> DQ12) = tpd_A17_DQ12;
    if (InitialPageAccess) (A17 *> DQ13) = tpd_A17_DQ13;
    if (InitialPageAccess) (A17 *> DQ14) = tpd_A17_DQ14;
    if (InitialPageAccess) (A17 *> DQ15) = tpd_A17_DQ15;
    if (InitialPageAccess) (A18 *> DQ0)  = tpd_A18_DQ0;
    if (InitialPageAccess) (A18 *> DQ1)  = tpd_A18_DQ1;
    if (InitialPageAccess) (A18 *> DQ2)  = tpd_A18_DQ2;
    if (InitialPageAccess) (A18 *> DQ3)  = tpd_A18_DQ3;
    if (InitialPageAccess) (A18 *> DQ4)  = tpd_A18_DQ4;
    if (InitialPageAccess) (A18 *> DQ5)  = tpd_A18_DQ5;
    if (InitialPageAccess) (A18 *> DQ6)  = tpd_A18_DQ6;
    if (InitialPageAccess) (A18 *> DQ7)  = tpd_A18_DQ7;
    if (InitialPageAccess) (A18 *> DQ8)  = tpd_A18_DQ8;
    if (InitialPageAccess) (A18 *> DQ9)  = tpd_A18_DQ9;
    if (InitialPageAccess) (A18 *> DQ10) = tpd_A18_DQ10;
    if (InitialPageAccess) (A18 *> DQ11) = tpd_A18_DQ11;
    if (InitialPageAccess) (A18 *> DQ12) = tpd_A18_DQ12;
    if (InitialPageAccess) (A18 *> DQ13) = tpd_A18_DQ13;
    if (InitialPageAccess) (A18 *> DQ14) = tpd_A18_DQ14;
    if (InitialPageAccess) (A18 *> DQ15) = tpd_A18_DQ15;
    if (InitialPageAccess) (A19 *> DQ0)  = tpd_A19_DQ0;
    if (InitialPageAccess) (A19 *> DQ1)  = tpd_A19_DQ1;
    if (InitialPageAccess) (A19 *> DQ2)  = tpd_A19_DQ2;
    if (InitialPageAccess) (A19 *> DQ3)  = tpd_A19_DQ3;
    if (InitialPageAccess) (A19 *> DQ4)  = tpd_A19_DQ4;
    if (InitialPageAccess) (A19 *> DQ5)  = tpd_A19_DQ5;
    if (InitialPageAccess) (A19 *> DQ6)  = tpd_A19_DQ6;
    if (InitialPageAccess) (A19 *> DQ7)  = tpd_A19_DQ7;
    if (InitialPageAccess) (A19 *> DQ8)  = tpd_A19_DQ8;
    if (InitialPageAccess) (A19 *> DQ9)  = tpd_A19_DQ9;
    if (InitialPageAccess) (A19 *> DQ10) = tpd_A19_DQ10;
    if (InitialPageAccess) (A19 *> DQ11) = tpd_A19_DQ11;
    if (InitialPageAccess) (A19 *> DQ12) = tpd_A19_DQ12;
    if (InitialPageAccess) (A19 *> DQ13) = tpd_A19_DQ13;
    if (InitialPageAccess) (A19 *> DQ14) = tpd_A19_DQ14;
    if (InitialPageAccess) (A19 *> DQ15) = tpd_A19_DQ15;
    if (InitialPageAccess) (A20 *> DQ0)  = tpd_A20_DQ0;
    if (InitialPageAccess) (A20 *> DQ1)  = tpd_A20_DQ1;
    if (InitialPageAccess) (A20 *> DQ2)  = tpd_A20_DQ2;
    if (InitialPageAccess) (A20 *> DQ3)  = tpd_A20_DQ3;
    if (InitialPageAccess) (A20 *> DQ4)  = tpd_A20_DQ4;
    if (InitialPageAccess) (A20 *> DQ5)  = tpd_A20_DQ5;
    if (InitialPageAccess) (A20 *> DQ6)  = tpd_A20_DQ6;
    if (InitialPageAccess) (A20 *> DQ7)  = tpd_A20_DQ7;
    if (InitialPageAccess) (A20 *> DQ8)  = tpd_A20_DQ8;
    if (InitialPageAccess) (A20 *> DQ9)  = tpd_A20_DQ9;
    if (InitialPageAccess) (A20 *> DQ10) = tpd_A20_DQ10;
    if (InitialPageAccess) (A20 *> DQ11) = tpd_A20_DQ11;
    if (InitialPageAccess) (A20 *> DQ12) = tpd_A20_DQ12;
    if (InitialPageAccess) (A20 *> DQ13) = tpd_A20_DQ13;
    if (InitialPageAccess) (A20 *> DQ14) = tpd_A20_DQ14;
    if (InitialPageAccess) (A20 *> DQ15) = tpd_A20_DQ15;
    if (InitialPageAccess) (A21 *> DQ0)  = tpd_A21_DQ0;
    if (InitialPageAccess) (A21 *> DQ1)  = tpd_A21_DQ1;
    if (InitialPageAccess) (A21 *> DQ2)  = tpd_A21_DQ2;
    if (InitialPageAccess) (A21 *> DQ3)  = tpd_A21_DQ3;
    if (InitialPageAccess) (A21 *> DQ4)  = tpd_A21_DQ4;
    if (InitialPageAccess) (A21 *> DQ5)  = tpd_A21_DQ5;
    if (InitialPageAccess) (A21 *> DQ6)  = tpd_A21_DQ6;
    if (InitialPageAccess) (A21 *> DQ7)  = tpd_A21_DQ7;
    if (InitialPageAccess) (A21 *> DQ8)  = tpd_A21_DQ8;
    if (InitialPageAccess) (A21 *> DQ9)  = tpd_A21_DQ9;
    if (InitialPageAccess) (A21 *> DQ10) = tpd_A21_DQ10;
    if (InitialPageAccess) (A21 *> DQ11) = tpd_A21_DQ11;
    if (InitialPageAccess) (A21 *> DQ12) = tpd_A21_DQ12;
    if (InitialPageAccess) (A21 *> DQ13) = tpd_A21_DQ13;
    if (InitialPageAccess) (A21 *> DQ14) = tpd_A21_DQ14;
    if (InitialPageAccess) (A21 *> DQ15) = tpd_A21_DQ15;
    if (InitialPageAccess) (A22 *> DQ0)  = tpd_A22_DQ0;
    if (InitialPageAccess) (A22 *> DQ1)  = tpd_A22_DQ1;
    if (InitialPageAccess) (A22 *> DQ2)  = tpd_A22_DQ2;
    if (InitialPageAccess) (A22 *> DQ3)  = tpd_A22_DQ3;
    if (InitialPageAccess) (A22 *> DQ4)  = tpd_A22_DQ4;
    if (InitialPageAccess) (A22 *> DQ5)  = tpd_A22_DQ5;
    if (InitialPageAccess) (A22 *> DQ6)  = tpd_A22_DQ6;
    if (InitialPageAccess) (A22 *> DQ7)  = tpd_A22_DQ7;
    if (InitialPageAccess) (A22 *> DQ8)  = tpd_A22_DQ8;
    if (InitialPageAccess) (A22 *> DQ9)  = tpd_A22_DQ9;
    if (InitialPageAccess) (A22 *> DQ10) = tpd_A22_DQ10;
    if (InitialPageAccess) (A22 *> DQ11) = tpd_A22_DQ11;
    if (InitialPageAccess) (A22 *> DQ12) = tpd_A22_DQ12;
    if (InitialPageAccess) (A22 *> DQ13) = tpd_A22_DQ13;
    if (InitialPageAccess) (A22 *> DQ14) = tpd_A22_DQ14;
    if (InitialPageAccess) (A22 *> DQ15) = tpd_A22_DQ15;
    if (InitialPageAccess) (A23 *> DQ0)  = tpd_A23_DQ0;
    if (InitialPageAccess) (A23 *> DQ1)  = tpd_A23_DQ1;
    if (InitialPageAccess) (A23 *> DQ2)  = tpd_A23_DQ2;
    if (InitialPageAccess) (A23 *> DQ3)  = tpd_A23_DQ3;
    if (InitialPageAccess) (A23 *> DQ4)  = tpd_A23_DQ4;
    if (InitialPageAccess) (A23 *> DQ5)  = tpd_A23_DQ5;
    if (InitialPageAccess) (A23 *> DQ6)  = tpd_A23_DQ6;
    if (InitialPageAccess) (A23 *> DQ7)  = tpd_A23_DQ7;
    if (InitialPageAccess) (A23 *> DQ8)  = tpd_A23_DQ8;
    if (InitialPageAccess) (A23 *> DQ9)  = tpd_A23_DQ9;
    if (InitialPageAccess) (A23 *> DQ10) = tpd_A23_DQ10;
    if (InitialPageAccess) (A23 *> DQ11) = tpd_A23_DQ11;
    if (InitialPageAccess) (A23 *> DQ12) = tpd_A23_DQ12;
    if (InitialPageAccess) (A23 *> DQ13) = tpd_A23_DQ13;
    if (InitialPageAccess) (A23 *> DQ14) = tpd_A23_DQ14;
    if (InitialPageAccess) (A23 *> DQ15) = tpd_A23_DQ15;
    if (InitialPageAccess) (A24 *> DQ0)  = tpd_A24_DQ0;
    if (InitialPageAccess) (A24 *> DQ1)  = tpd_A24_DQ1;
    if (InitialPageAccess) (A24 *> DQ2)  = tpd_A24_DQ2;
    if (InitialPageAccess) (A24 *> DQ3)  = tpd_A24_DQ3;
    if (InitialPageAccess) (A24 *> DQ4)  = tpd_A24_DQ4;
    if (InitialPageAccess) (A24 *> DQ5)  = tpd_A24_DQ5;
    if (InitialPageAccess) (A24 *> DQ6)  = tpd_A24_DQ6;
    if (InitialPageAccess) (A24 *> DQ7)  = tpd_A24_DQ7;
    if (InitialPageAccess) (A24 *> DQ8)  = tpd_A24_DQ8;
    if (InitialPageAccess) (A24 *> DQ9)  = tpd_A24_DQ9;
    if (InitialPageAccess) (A24 *> DQ10) = tpd_A24_DQ10;
    if (InitialPageAccess) (A24 *> DQ11) = tpd_A24_DQ11;
    if (InitialPageAccess) (A24 *> DQ12) = tpd_A24_DQ12;
    if (InitialPageAccess) (A24 *> DQ13) = tpd_A24_DQ13;
    if (InitialPageAccess) (A24 *> DQ14) = tpd_A24_DQ14;
    if (InitialPageAccess) (A24 *> DQ15) = tpd_A24_DQ15;

    if (SubsequentPageAccess) (A1 *> DQ0)  = tpd_A1_DQ0;
    if (SubsequentPageAccess) (A1 *> DQ1)  = tpd_A1_DQ1;
    if (SubsequentPageAccess) (A1 *> DQ2)  = tpd_A1_DQ2;
    if (SubsequentPageAccess) (A1 *> DQ3)  = tpd_A1_DQ3;
    if (SubsequentPageAccess) (A1 *> DQ4)  = tpd_A1_DQ4;
    if (SubsequentPageAccess) (A1 *> DQ5)  = tpd_A1_DQ5;
    if (SubsequentPageAccess) (A1 *> DQ6)  = tpd_A1_DQ6;
    if (SubsequentPageAccess) (A1 *> DQ7)  = tpd_A1_DQ7;
    if (SubsequentPageAccess) (A1 *> DQ8)  = tpd_A1_DQ8;
    if (SubsequentPageAccess) (A1 *> DQ9)  = tpd_A1_DQ9;
    if (SubsequentPageAccess) (A1 *> DQ10) = tpd_A1_DQ10;
    if (SubsequentPageAccess) (A1 *> DQ11) = tpd_A1_DQ11;
    if (SubsequentPageAccess) (A1 *> DQ12) = tpd_A1_DQ12;
    if (SubsequentPageAccess) (A1 *> DQ13) = tpd_A1_DQ13;
    if (SubsequentPageAccess) (A1 *> DQ14) = tpd_A1_DQ14;
    if (SubsequentPageAccess) (A1 *> DQ15) = tpd_A1_DQ15;
    if (SubsequentPageAccess) (A2 *> DQ0)  = tpd_A2_DQ0;
    if (SubsequentPageAccess) (A2 *> DQ1)  = tpd_A2_DQ1;
    if (SubsequentPageAccess) (A2 *> DQ2)  = tpd_A2_DQ2;
    if (SubsequentPageAccess) (A2 *> DQ3)  = tpd_A2_DQ3;
    if (SubsequentPageAccess) (A2 *> DQ4)  = tpd_A2_DQ4;
    if (SubsequentPageAccess) (A2 *> DQ5)  = tpd_A2_DQ5;
    if (SubsequentPageAccess) (A2 *> DQ6)  = tpd_A2_DQ6;
    if (SubsequentPageAccess) (A2 *> DQ7)  = tpd_A2_DQ7;
    if (SubsequentPageAccess) (A2 *> DQ8)  = tpd_A2_DQ8;
    if (SubsequentPageAccess) (A2 *> DQ9)  = tpd_A2_DQ9;
    if (SubsequentPageAccess) (A2 *> DQ10) = tpd_A2_DQ10;
    if (SubsequentPageAccess) (A2 *> DQ11) = tpd_A2_DQ11;
    if (SubsequentPageAccess) (A2 *> DQ12) = tpd_A2_DQ12;
    if (SubsequentPageAccess) (A2 *> DQ13) = tpd_A2_DQ13;
    if (SubsequentPageAccess) (A2 *> DQ14) = tpd_A2_DQ14;
    if (SubsequentPageAccess) (A2 *> DQ15) = tpd_A2_DQ15;

    if (FROMCE) (CENeg *> DQ0) = tpd_CENeg_DQ0;
    if (FROMCE) (CENeg *> DQ1) = tpd_CENeg_DQ1;
    if (FROMCE) (CENeg *> DQ2) = tpd_CENeg_DQ2;
    if (FROMCE) (CENeg *> DQ3) = tpd_CENeg_DQ3;
    if (FROMCE) (CENeg *> DQ4) = tpd_CENeg_DQ4;
    if (FROMCE) (CENeg *> DQ5) = tpd_CENeg_DQ5;
    if (FROMCE) (CENeg *> DQ6) = tpd_CENeg_DQ6;
    if (FROMCE) (CENeg *> DQ7) = tpd_CENeg_DQ7;
    if (FROMCE) (CENeg *> DQ8) = tpd_CENeg_DQ8;
    if (FROMCE) (CENeg *> DQ9) = tpd_CENeg_DQ9;
    if (FROMCE) (CENeg *> DQ10)= tpd_CENeg_DQ10;
    if (FROMCE) (CENeg *> DQ11)= tpd_CENeg_DQ11;
    if (FROMCE) (CENeg *> DQ12)= tpd_CENeg_DQ12;
    if (FROMCE) (CENeg *> DQ13)= tpd_CENeg_DQ13;
    if (FROMCE) (CENeg *> DQ14)= tpd_CENeg_DQ14;
    if (FROMCE) (CENeg *> DQ15)= tpd_CENeg_DQ15;

    if (FROMOE) (OENeg *> DQ0)  = tpd_OENeg_DQ0;
    if (FROMOE) (OENeg *> DQ1)  = tpd_OENeg_DQ1;
    if (FROMOE) (OENeg *> DQ2)  = tpd_OENeg_DQ2;
    if (FROMOE) (OENeg *> DQ3)  = tpd_OENeg_DQ3;
    if (FROMOE) (OENeg *> DQ4)  = tpd_OENeg_DQ4;
    if (FROMOE) (OENeg *> DQ5)  = tpd_OENeg_DQ5;
    if (FROMOE) (OENeg *> DQ6)  = tpd_OENeg_DQ6;
    if (FROMOE) (OENeg *> DQ7)  = tpd_OENeg_DQ7;
    if (FROMOE) (OENeg *> DQ8)  = tpd_OENeg_DQ8;
    if (FROMOE) (OENeg *> DQ9)  = tpd_OENeg_DQ9;
    if (FROMOE) (OENeg *> DQ10) = tpd_OENeg_DQ10;
    if (FROMOE) (OENeg *> DQ11) = tpd_OENeg_DQ11;
    if (FROMOE) (OENeg *> DQ12) = tpd_OENeg_DQ12;
    if (FROMOE) (OENeg *> DQ13) = tpd_OENeg_DQ13;
    if (FROMOE) (OENeg *> DQ14) = tpd_OENeg_DQ14;
    if (FROMOE) (OENeg *> DQ15) = tpd_OENeg_DQ15;

    if (RCR[15] === 1'b0) ( CLK *> DQ0 )   =  tpd_CLK_DQ0   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ1 )   =  tpd_CLK_DQ1   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ2 )   =  tpd_CLK_DQ2   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ3 )   =  tpd_CLK_DQ3   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ4 )   =  tpd_CLK_DQ4   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ5 )   =  tpd_CLK_DQ5   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ6 )   =  tpd_CLK_DQ6   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ7 )   =  tpd_CLK_DQ7   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ8 )   =  tpd_CLK_DQ8   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ9 )   =  tpd_CLK_DQ9   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ10)   =  tpd_CLK_DQ10  ;
    if (RCR[15] === 1'b0) ( CLK *> DQ11)   =  tpd_CLK_DQ11  ;
    if (RCR[15] === 1'b0) ( CLK *> DQ12)   =  tpd_CLK_DQ12  ;
    if (RCR[15] === 1'b0) ( CLK *> DQ13)   =  tpd_CLK_DQ13  ;
    if (RCR[15] === 1'b0) ( CLK *> DQ14)   =  tpd_CLK_DQ14  ;
    if (RCR[15] === 1'b0) ( CLK *> DQ15)   =  tpd_CLK_DQ15  ;

    ( CENeg *> WAITOut)         =  tpd_CE0Neg_WAITOut ;
    ( OENeg *> WAITOut)         =  tpd_OE0Neg_WAITOut ;
    if (RCR[15] === 1'b0) ( CLK *> WAITOut) = tpd_CLK_WAITOut;

///////////////////////////////////////////////////////////////////////////////
// Timing Violation                                                          //
///////////////////////////////////////////////////////////////////////////////
    $setup ( A1   , posedge ADVNeg, tsetup_A1_ADVNeg, Viol);
    $setup ( A2   , posedge ADVNeg, tsetup_A2_ADVNeg, Viol);
    $setup ( A3   , posedge ADVNeg, tsetup_A3_ADVNeg, Viol);
    $setup ( A4   , posedge ADVNeg, tsetup_A4_ADVNeg, Viol);
    $setup ( A5   , posedge ADVNeg, tsetup_A5_ADVNeg, Viol);
    $setup ( A6   , posedge ADVNeg, tsetup_A6_ADVNeg, Viol);
    $setup ( A7   , posedge ADVNeg, tsetup_A7_ADVNeg, Viol);
    $setup ( A8   , posedge ADVNeg, tsetup_A8_ADVNeg, Viol);
    $setup ( A9   , posedge ADVNeg, tsetup_A9_ADVNeg, Viol);
    $setup ( A10  , posedge ADVNeg, tsetup_A10_ADVNeg, Viol);
    $setup ( A11  , posedge ADVNeg, tsetup_A11_ADVNeg, Viol);
    $setup ( A12  , posedge ADVNeg, tsetup_A12_ADVNeg, Viol);
    $setup ( A13  , posedge ADVNeg, tsetup_A13_ADVNeg, Viol);
    $setup ( A14  , posedge ADVNeg, tsetup_A14_ADVNeg, Viol);
    $setup ( A15  , posedge ADVNeg, tsetup_A15_ADVNeg, Viol);
    $setup ( A16  , posedge ADVNeg, tsetup_A16_ADVNeg, Viol);
    $setup ( A17  , posedge ADVNeg, tsetup_A17_ADVNeg, Viol);
    $setup ( A18  , posedge ADVNeg, tsetup_A18_ADVNeg, Viol);
    $setup ( A19  , posedge ADVNeg, tsetup_A19_ADVNeg, Viol);
    $setup ( A20  , posedge ADVNeg, tsetup_A20_ADVNeg, Viol);
    $setup ( A21  , posedge ADVNeg, tsetup_A21_ADVNeg, Viol);
    $setup ( A22  , posedge ADVNeg, tsetup_A22_ADVNeg, Viol);
    $setup ( A23  , posedge ADVNeg, tsetup_A23_ADVNeg, Viol);
    $setup ( A24  , posedge ADVNeg, tsetup_A24_ADVNeg, Viol);

    $setup ( negedge CENeg  , posedge ADVNeg, tsetup_CENeg_ADVNeg, Viol);
    $setup ( negedge RSTNeg , posedge ADVNeg, tsetup_RSTNeg_ADVNeg,Viol);
    $setup ( posedge WENeg  , posedge ADVNeg, tsetup_WENeg_ADVNeg, Viol);

    $setup ( A1   , posedge CLK &&& CLK_rising, tsetup_A1_CLK, Viol);
    $setup ( A2   , posedge CLK &&& CLK_rising, tsetup_A2_CLK, Viol);
    $setup ( A3   , posedge CLK &&& CLK_rising, tsetup_A3_CLK, Viol);
    $setup ( A4   , posedge CLK &&& CLK_rising, tsetup_A4_CLK, Viol);
    $setup ( A5   , posedge CLK &&& CLK_rising, tsetup_A5_CLK, Viol);
    $setup ( A6   , posedge CLK &&& CLK_rising, tsetup_A6_CLK, Viol);
    $setup ( A7   , posedge CLK &&& CLK_rising, tsetup_A7_CLK, Viol);
    $setup ( A8   , posedge CLK &&& CLK_rising, tsetup_A8_CLK, Viol);
    $setup ( A9   , posedge CLK &&& CLK_rising, tsetup_A9_CLK, Viol);
    $setup ( A10  , posedge CLK &&& CLK_rising, tsetup_A10_CLK, Viol);
    $setup ( A11  , posedge CLK &&& CLK_rising, tsetup_A11_CLK, Viol);
    $setup ( A12  , posedge CLK &&& CLK_rising, tsetup_A12_CLK, Viol);
    $setup ( A13  , posedge CLK &&& CLK_rising, tsetup_A13_CLK, Viol);
    $setup ( A14  , posedge CLK &&& CLK_rising, tsetup_A14_CLK, Viol);
    $setup ( A15  , posedge CLK &&& CLK_rising, tsetup_A15_CLK, Viol);
    $setup ( A16  , posedge CLK &&& CLK_rising, tsetup_A16_CLK, Viol);
    $setup ( A17  , posedge CLK &&& CLK_rising, tsetup_A17_CLK, Viol);
    $setup ( A18  , posedge CLK &&& CLK_rising, tsetup_A18_CLK, Viol);
    $setup ( A19  , posedge CLK &&& CLK_rising, tsetup_A19_CLK, Viol);
    $setup ( A20  , posedge CLK &&& CLK_rising, tsetup_A20_CLK, Viol);
    $setup ( A21  , posedge CLK &&& CLK_rising, tsetup_A21_CLK, Viol);
    $setup ( A22  , posedge CLK &&& CLK_rising, tsetup_A22_CLK, Viol);
    $setup ( A23  , posedge CLK &&& CLK_rising, tsetup_A23_CLK, Viol);
    $setup ( A24  , posedge CLK &&& CLK_rising, tsetup_A24_CLK, Viol);

    $setup ( A1   , negedge CLK &&& CLK_falling, tsetup_A1_CLK, Viol);
    $setup ( A2   , negedge CLK &&& CLK_falling, tsetup_A2_CLK, Viol);
    $setup ( A3   , negedge CLK &&& CLK_falling, tsetup_A3_CLK, Viol);
    $setup ( A4   , negedge CLK &&& CLK_falling, tsetup_A4_CLK, Viol);
    $setup ( A5   , negedge CLK &&& CLK_falling, tsetup_A5_CLK, Viol);
    $setup ( A6   , negedge CLK &&& CLK_falling, tsetup_A6_CLK, Viol);
    $setup ( A7   , negedge CLK &&& CLK_falling, tsetup_A7_CLK, Viol);
    $setup ( A8   , negedge CLK &&& CLK_falling, tsetup_A8_CLK, Viol);
    $setup ( A9   , negedge CLK &&& CLK_falling, tsetup_A9_CLK, Viol);
    $setup ( A10  , negedge CLK &&& CLK_falling, tsetup_A10_CLK, Viol);
    $setup ( A11  , negedge CLK &&& CLK_falling, tsetup_A11_CLK, Viol);
    $setup ( A12  , negedge CLK &&& CLK_falling, tsetup_A12_CLK, Viol);
    $setup ( A13  , negedge CLK &&& CLK_falling, tsetup_A13_CLK, Viol);
    $setup ( A14  , negedge CLK &&& CLK_falling, tsetup_A14_CLK, Viol);
    $setup ( A15  , negedge CLK &&& CLK_falling, tsetup_A15_CLK, Viol);
    $setup ( A16  , negedge CLK &&& CLK_falling, tsetup_A16_CLK, Viol);
    $setup ( A17  , negedge CLK &&& CLK_falling, tsetup_A17_CLK, Viol);
    $setup ( A18  , negedge CLK &&& CLK_falling, tsetup_A18_CLK, Viol);
    $setup ( A19  , negedge CLK &&& CLK_falling, tsetup_A19_CLK, Viol);
    $setup ( A20  , negedge CLK &&& CLK_falling, tsetup_A20_CLK, Viol);
    $setup ( A21  , negedge CLK &&& CLK_falling, tsetup_A21_CLK, Viol);
    $setup ( A22  , negedge CLK &&& CLK_falling, tsetup_A22_CLK, Viol);
    $setup ( A23  , negedge CLK &&& CLK_falling, tsetup_A23_CLK, Viol);
    $setup ( A24  , negedge CLK &&& CLK_falling, tsetup_A24_CLK, Viol);

    $setup ( negedge ADVNeg , posedge CLK &&& CLK_rising ,
             tsetup_ADVNeg_CLK, Viol);
    $setup ( negedge ADVNeg , negedge CLK &&& CLK_falling ,
             tsetup_ADVNeg_CLK, Viol);

    $setup ( negedge CENeg  , posedge CLK &&& CLK_rising ,
             tsetup_CENeg_CLK, Viol);
    $setup ( negedge CENeg  , negedge CLK &&& CLK_falling ,
             tsetup_CENeg_CLK, Viol);

    $setup ( posedge WENeg  , posedge CLK &&& CLK_rising ,
             tsetup_WENeg_CLK, Viol);
    $setup ( posedge WENeg  , negedge CLK &&& CLK_falling ,
             tsetup_WENeg_CLK, Viol);

    $setup ( negedge CENeg  , negedge WENeg , tsetup_CENeg_WENeg, Viol);

    $setup ( DQ0   , posedge WENeg , tsetup_DQ0_WENeg, Viol);
    $setup ( DQ1   , posedge WENeg , tsetup_DQ1_WENeg, Viol);
    $setup ( DQ2   , posedge WENeg , tsetup_DQ2_WENeg, Viol);
    $setup ( DQ3   , posedge WENeg , tsetup_DQ3_WENeg, Viol);
    $setup ( DQ4   , posedge WENeg , tsetup_DQ4_WENeg, Viol);
    $setup ( DQ5   , posedge WENeg , tsetup_DQ5_WENeg, Viol);
    $setup ( DQ6   , posedge WENeg , tsetup_DQ6_WENeg, Viol);
    $setup ( DQ7   , posedge WENeg , tsetup_DQ7_WENeg, Viol);
    $setup ( DQ8   , posedge WENeg , tsetup_DQ8_WENeg, Viol);
    $setup ( DQ9   , posedge WENeg , tsetup_DQ9_WENeg, Viol);
    $setup ( DQ10  , posedge WENeg , tsetup_DQ10_WENeg, Viol);
    $setup ( DQ11  , posedge WENeg , tsetup_DQ11_WENeg, Viol);
    $setup ( DQ12  , posedge WENeg , tsetup_DQ12_WENeg, Viol);
    $setup ( DQ13  , posedge WENeg , tsetup_DQ13_WENeg, Viol);
    $setup ( DQ14  , posedge WENeg , tsetup_DQ14_WENeg, Viol);
    $setup ( DQ15  , posedge WENeg , tsetup_DQ15_WENeg, Viol);

    $setup ( A1   , posedge WENeg , tsetup_A1_WENeg, Viol);
    $setup ( A2   , posedge WENeg , tsetup_A2_WENeg, Viol);
    $setup ( A3   , posedge WENeg , tsetup_A3_WENeg, Viol);
    $setup ( A4   , posedge WENeg , tsetup_A4_WENeg, Viol);
    $setup ( A5   , posedge WENeg , tsetup_A5_WENeg, Viol);
    $setup ( A6   , posedge WENeg , tsetup_A6_WENeg, Viol);
    $setup ( A7   , posedge WENeg , tsetup_A7_WENeg, Viol);
    $setup ( A8   , posedge WENeg , tsetup_A8_WENeg, Viol);
    $setup ( A9   , posedge WENeg , tsetup_A9_WENeg, Viol);
    $setup ( A10  , posedge WENeg , tsetup_A10_WENeg, Viol);
    $setup ( A11  , posedge WENeg , tsetup_A11_WENeg, Viol);
    $setup ( A12  , posedge WENeg , tsetup_A12_WENeg, Viol);
    $setup ( A13  , posedge WENeg , tsetup_A13_WENeg, Viol);
    $setup ( A14  , posedge WENeg , tsetup_A14_WENeg, Viol);
    $setup ( A15  , posedge WENeg , tsetup_A15_WENeg, Viol);
    $setup ( A16  , posedge WENeg , tsetup_A16_WENeg, Viol);
    $setup ( A17  , posedge WENeg , tsetup_A17_WENeg, Viol);
    $setup ( A18  , posedge WENeg , tsetup_A18_WENeg, Viol);
    $setup ( A19  , posedge WENeg , tsetup_A19_WENeg, Viol);
    $setup ( A20  , posedge WENeg , tsetup_A20_WENeg, Viol);
    $setup ( A21  , posedge WENeg , tsetup_A21_WENeg, Viol);
    $setup ( A22  , posedge WENeg , tsetup_A22_WENeg, Viol);
    $setup ( A23  , posedge WENeg , tsetup_A23_WENeg, Viol);
    $setup ( A24  , posedge WENeg , tsetup_A24_WENeg, Viol);

    $setup (posedge ADVNeg, posedge WENeg , tsetup_ADVNeg_WENeg, Viol);
    $setup (posedge WPNeg, posedge WENeg , tsetup_WPNeg_WENeg, Viol);

    $setup (posedge CLK &&& CLK_rising, negedge WENeg ,
            tsetup_CLK_WENeg, Viol);
    $setup (negedge CLK &&& CLK_falling, negedge WENeg ,
            tsetup_CLK_WENeg, Viol);

    $setup (posedge WENeg, negedge OENeg , tsetup_WENeg_OENeg, Viol);

    $hold ( posedge WENeg,  CENeg, thold_CENeg_WENeg, Viol);

    $hold (  posedge WENeg ,DQ0 , thold_DQ0_WENeg, Viol);
    $hold (  posedge WENeg ,DQ1 , thold_DQ1_WENeg, Viol);
    $hold (  posedge WENeg ,DQ2 , thold_DQ2_WENeg, Viol);
    $hold (  posedge WENeg ,DQ3 , thold_DQ3_WENeg, Viol);
    $hold (  posedge WENeg ,DQ4 , thold_DQ4_WENeg, Viol);
    $hold (  posedge WENeg ,DQ5 , thold_DQ5_WENeg, Viol);
    $hold (  posedge WENeg ,DQ6 , thold_DQ6_WENeg, Viol);
    $hold (  posedge WENeg ,DQ7 , thold_DQ7_WENeg, Viol);
    $hold (  posedge WENeg ,DQ8 , thold_DQ8_WENeg, Viol);
    $hold (  posedge WENeg ,DQ9 , thold_DQ9_WENeg, Viol);
    $hold (  posedge WENeg ,DQ10, thold_DQ10_WENeg, Viol);
    $hold (  posedge WENeg ,DQ11, thold_DQ11_WENeg, Viol);
    $hold (  posedge WENeg ,DQ12, thold_DQ12_WENeg, Viol);
    $hold (  posedge WENeg ,DQ13, thold_DQ13_WENeg, Viol);
    $hold (  posedge WENeg ,DQ14, thold_DQ14_WENeg, Viol);
    $hold (  posedge WENeg ,DQ15, thold_DQ15_WENeg, Viol);

    $hold (  posedge WENeg ,A1, thold_A1_WENeg, Viol);
    $hold (  posedge WENeg ,A2, thold_A2_WENeg, Viol);
    $hold (  posedge WENeg ,A3, thold_A3_WENeg, Viol);
    $hold (  posedge WENeg ,A4, thold_A4_WENeg, Viol);
    $hold (  posedge WENeg ,A5, thold_A5_WENeg, Viol);
    $hold (  posedge WENeg ,A6, thold_A6_WENeg, Viol);
    $hold (  posedge WENeg ,A7, thold_A7_WENeg, Viol);
    $hold (  posedge WENeg ,A8, thold_A8_WENeg, Viol);
    $hold (  posedge WENeg ,A9, thold_A9_WENeg, Viol);
    $hold (  posedge WENeg ,A10, thold_A10_WENeg, Viol);
    $hold (  posedge WENeg ,A11, thold_A11_WENeg, Viol);
    $hold (  posedge WENeg ,A12, thold_A12_WENeg, Viol);
    $hold (  posedge WENeg ,A13, thold_A13_WENeg, Viol);
    $hold (  posedge WENeg ,A14, thold_A14_WENeg, Viol);
    $hold (  posedge WENeg ,A15, thold_A15_WENeg, Viol);
    $hold (  posedge WENeg ,A16, thold_A16_WENeg, Viol);
    $hold (  posedge WENeg ,A17, thold_A17_WENeg, Viol);
    $hold (  posedge WENeg ,A18, thold_A18_WENeg, Viol);
    $hold (  posedge WENeg ,A19, thold_A19_WENeg, Viol);
    $hold (  posedge WENeg ,A20, thold_A20_WENeg, Viol);
    $hold (  posedge WENeg ,A21, thold_A21_WENeg, Viol);
    $hold (  posedge WENeg ,A22, thold_A22_WENeg, Viol);
    $hold (  posedge WENeg ,A23, thold_A23_WENeg, Viol);
    $hold (  posedge WENeg ,A24, thold_A24_WENeg, Viol);

    $hold (  posedge ADVNeg ,A1, thold_A1_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A2, thold_A2_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A3, thold_A3_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A4, thold_A4_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A5, thold_A5_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A6, thold_A6_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A7, thold_A7_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A8, thold_A8_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A9, thold_A9_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A10, thold_A10_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A11, thold_A11_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A12, thold_A12_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A13, thold_A13_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A14, thold_A14_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A15, thold_A15_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A16, thold_A16_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A17, thold_A17_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A18, thold_A18_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A19, thold_A19_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A20, thold_A20_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A21, thold_A21_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A22, thold_A22_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A23, thold_A23_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A24, thold_A24_ADVNeg, Viol);

    $hold ( posedge CLK &&& CLK_rising, A1  , thold_A1_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A2  , thold_A2_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A3  , thold_A3_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A4  , thold_A4_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A5  , thold_A5_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A6  , thold_A6_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A7  , thold_A7_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A8  , thold_A8_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A9  , thold_A9_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A10 , thold_A10_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A11 , thold_A11_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A12 , thold_A12_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A13 , thold_A13_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A14 , thold_A14_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A15 , thold_A15_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A16 , thold_A16_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A17 , thold_A17_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A18 , thold_A18_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A19 , thold_A19_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A20 , thold_A20_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A21 , thold_A21_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A22 , thold_A22_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A23 , thold_A23_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A24 , thold_A24_CLK, Viol);

    $hold ( negedge CLK &&& CLK_falling, A1  , thold_A1_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A2  , thold_A2_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A3  , thold_A3_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A4  , thold_A4_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A5  , thold_A5_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A6  , thold_A6_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A7  , thold_A7_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A8  , thold_A8_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A9  , thold_A9_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A10 , thold_A10_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A11 , thold_A11_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A12 , thold_A12_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A13 , thold_A13_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A14 , thold_A14_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A15 , thold_A15_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A16 , thold_A16_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A17 , thold_A17_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A18 , thold_A18_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A19 , thold_A19_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A20 , thold_A20_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A21 , thold_A21_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A22 , thold_A22_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A23 , thold_A23_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A24 , thold_A24_CLK, Viol);

    $width ( posedge CENeg , tpw_CENeg_posedge );
    $width ( posedge ADVNeg, tpw_ADVNeg_posedge );
    $width ( negedge ADVNeg, tpw_ADVNeg_negedge );
    $width ( posedge CLK   , tpw_CLK_posedge );
    $width ( negedge CLK   , tpw_CLK_negedge );
    $width ( posedge WENeg , tpw_WENeg_posedge );
    $width ( negedge WENeg , tpw_WENeg_negedge );
    $width ( negedge RSTNeg, tpw_RSTNeg_negedge );
    $period( posedge CLK   , tperiod_CLK);
    $period( negedge CLK   , tperiod_CLK);

endspecify

    //tdevice parameters aligned to model timescale

    // Program EraseParameter
    time tdevice_EraseParameter
                            = tdevice_EraseParameter_td*1000; //2.5 sec;
    // Parameter Block Erase - 12V
    time tdevice_EraseMain = tdevice_EraseMain_td*1000; //4 sec;

///////////////////////////////////////////////////////////////////////////////
// Main Behavior Block                                                       //
///////////////////////////////////////////////////////////////////////////////

    always @(DQIn, DQOut)
    begin
        if (DQIn==DQOut)
            deq=1'b1;
        else
            deq=1'b0;
    end
    // chech when data is generated from model to avoid setuphold check in
    // those occasion
    assign deg=deq;

    // initialize memory and load preload files if any
    initial
    begin: InitMemory
        integer i;
        for (i=0;i<=MemSize;i=i+1)
        begin
            MemData[i]=MaxData;
        end
        if ((UserPreload) && !(mem_file_name == "none"))
        begin
            // File Read Section
            //#i28f512p33_1 memory file
            //#   /         - comment
            //#   @aaaaa    - <aaaaa> stands for address
            //#   dddd      - <dddd> is word to be written at Mem(aaaaa++)
            //#                 (aaaaa is incremented at every load)
            //#
            //#   only first 1-6 columns are loaded. NO empty lines !
            $readmemh(mem_file_name, MemData);
        end

        for (i=0;i<=BlockNum;i=i+1)
        begin
            OTP[i]=1'b0;
        end
        if ((UserPreload) && !(otp_blocks_file == "none"))
            begin
            // File Read Section
            //#i28f512p33_1 memory file
            //#   /         - comment
            //#   @aaa      - <aaa> stands for address
            //#   dddd      - <dddd> is word to be written at OTP(aaa++)
            //#                 (aaa is incremented at every load)
            //#
            //#   only first 1-6 columns are loaded. NO empty lines !
            $readmemh(otp_blocks_file, OTP);
        end

        PR[9'h80] = 16'hFFFE;
        for (i=9'h81;i<=9'h109;i=i+1)
        begin
            PR[i]=MaxData;
        end
        if ((UserPreload) && !(prot_reg_file == "none"))
        begin
            // File Read Section
            //#i28f512p33_1 memory file
            //#   /         - comment
            //#   @aaa      - <aaa> stands for address
            //#   dddd      - <dddd> is word to be written at PR(aaa++)
            //#                 (aaa is incremented at every load)
            //#
            //#   only first 1-6 columns are loaded. NO empty lines !
            $readmemh(prot_reg_file, PR);
        end

        for (i=0;i<=BlockNum;i=i+1)
        begin
            Block_Lock[i] = LOCKED;
            BlockLockBit[i] = 1'b1;
            BlockLockDownBit[i] = 1'b0;
        end
    end

    initial
    begin
        ///////////////////////////////////////////////////////////////////////
        //CFI array data
        ///////////////////////////////////////////////////////////////////////

        CFI_array[9'h10]=16'h51;
        CFI_array[9'h11]=16'h52;
        CFI_array[9'h12]=16'h59;
        CFI_array[9'h13]=16'h01;
        CFI_array[9'h14]=16'h00;
        CFI_array[9'h15]=16'h0A;
        CFI_array[9'h16]=16'h01;
        CFI_array[9'h17]=16'h00;
        CFI_array[9'h18]=16'h00;
        CFI_array[9'h19]=16'h00;
        CFI_array[9'h1A]=16'h00;
        // System Interface Information
        CFI_array[9'h1B]=16'h23;
        CFI_array[9'h1C]=16'h36;
        CFI_array[9'h1D]=16'h85;
        CFI_array[9'h1E]=16'h95;
        CFI_array[9'h1F]=16'h08;
        CFI_array[9'h20]=16'h09;
        CFI_array[9'h21]=16'h0A;
        CFI_array[9'h22]=16'h00;
        CFI_array[9'h23]=16'h01;
        CFI_array[9'h24]=16'h01;
        CFI_array[9'h25]=16'h02;
        CFI_array[9'h26]=16'h00;
        // Device Geometry definition
        CFI_array[9'h27]=16'h19;
        CFI_array[9'h28]=16'h01;
        CFI_array[9'h29]=16'h00;
        CFI_array[9'h2A]=16'h06;
        CFI_array[9'h2B]=16'h00;
        CFI_array[9'h2C]=16'h02;
        CFI_array[9'h2D]=16'hFE;
        CFI_array[9'h2E]=16'h00;
        CFI_array[9'h2F]=16'h00;
        CFI_array[9'h30]=16'h02;
        CFI_array[9'h31]=16'h03;
        CFI_array[9'h32]=16'h00;
        CFI_array[9'h33]=16'h80;
        CFI_array[9'h34]=16'h00;
        CFI_array[9'h35]=16'h00;
        CFI_array[9'h36]=16'h00;
        CFI_array[9'h37]=16'h00;
        CFI_array[9'h38]=16'h00;
        // Primary-vendor specific extended query
        CFI_array[9'h10A]=16'h50;
        CFI_array[9'h10B]=16'h52;
        CFI_array[9'h10C]=16'h49;
        CFI_array[9'h10D]=16'h31;
        CFI_array[9'h10E]=16'h34;
        CFI_array[9'h10F]=16'hE6;
        CFI_array[9'h110]=16'h01;
        CFI_array[9'h111]=16'h00;
        CFI_array[9'h112]=16'h40; // TOP PARAMETER BLOCK UPPER DIE
        CFI_array[9'h113]=16'h01;
        CFI_array[9'h114]=16'h03;
        CFI_array[9'h115]=16'h00;
        CFI_array[9'h116]=16'h30;
        CFI_array[9'h117]=16'h90;
        // Protection register information
        CFI_array[9'h118]=16'h02;
        CFI_array[9'h119]=16'h80;
        CFI_array[9'h11A]=16'h00;
        CFI_array[9'h11B]=16'h03;
        CFI_array[9'h11C]=16'h03;
        CFI_array[9'h11D]=16'h89;
        CFI_array[9'h11E]=16'h00;
        CFI_array[9'h11F]=16'h00;
        CFI_array[9'h120]=16'h00;
        CFI_array[9'h121]=16'h00;
        CFI_array[9'h122]=16'h00;
        CFI_array[9'h123]=16'h00;
        CFI_array[9'h124]=16'h10;
        CFI_array[9'h125]=16'h00;
        CFI_array[9'h126]=16'h04;
        // Burst read information
        CFI_array[9'h127]=16'h03;
        CFI_array[9'h128]=16'h04;
        CFI_array[9'h129]=16'h01;
        CFI_array[9'h12A]=16'h02;
        CFI_array[9'h12B]=16'h03;
        CFI_array[9'h12C]=16'h07;
        //Partition and Erase Block Region Information
        CFI_array[9'h12D]=16'h01;
        CFI_array[9'h12E]=16'h24;
        CFI_array[9'h12F]=16'h00;
        CFI_array[9'h130]=16'h01;
        CFI_array[9'h131]=16'h00;
        CFI_array[9'h132]=16'h11;
        CFI_array[9'h133]=16'h00;
        CFI_array[9'h134]=16'h00;
        CFI_array[9'h135]=16'h02;
        CFI_array[9'h136]=16'hFE;
        CFI_array[9'h137]=16'h00;
        CFI_array[9'h138]=16'h00;
        CFI_array[9'h139]=16'h02;
        CFI_array[9'h13A]=16'h64;
        CFI_array[9'h13B]=16'h00;
        CFI_array[9'h13C]=16'h02;
        CFI_array[9'h13D]=16'h03;
        CFI_array[9'h13E]=16'h00;
        CFI_array[9'h13F]=16'h80;
        CFI_array[9'h140]=16'h00;
        CFI_array[9'h141]=16'h00;
        CFI_array[9'h142]=16'h00;
        CFI_array[9'h143]=16'h80;
        CFI_array[9'h144]=16'h03;
        CFI_array[9'h145]=16'h00;
        CFI_array[9'h146]=16'h80;
        CFI_array[9'h147]=16'h00;
        CFI_array[9'h148]=16'h64;
        CFI_array[9'h149]=16'h00;
        CFI_array[9'h14A]=16'h02;
        CFI_array[9'h14B]=16'h03;
        CFI_array[9'h14C]=16'h00;
        CFI_array[9'h14D]=16'h80;
        CFI_array[9'h14E]=16'h00;
        CFI_array[9'h14F]=16'h00;
        CFI_array[9'h150]=16'h00;
        CFI_array[9'h151]=16'h80;
        CFI_array[9'h152]=16'h10;
        CFI_array[9'h153]=16'h20;
        CFI_array[9'h154]=16'h00;
        CFI_array[9'h155]=16'h00;
        CFI_array[9'h156]=16'h10;
    end

    initial
    begin
        current_state          = RESET_POWER_DOWN;
        next_state             = RESET_POWER_DOWN;
        read_state             = READ_ARRAY;

        WordProgram_in         = 1'b0;
        BuffProgram_in         = 1'b0;
        BEFP_in                = 1'b0;
        BEFPsetup_in           = 1'b0;
        ParameterErase_in      = 1'b0;
        MainErase_in           = 1'b0;
        ProgramSuspend_in      = 1'b0;
        EraseSuspend_in        = 1'b0;
        RstDuringErsPrg_in     = 1'b0;

        CLOCK           = 1'b0;
        Write           = 1'b0;
        Read            = 1'b0;
        Pmode           = 1'b0;
        abort           = 1'b0;
        ExtendProgTime  = 1'b0;
        AssertWAITOut   = 1'b0;
        DeassertWAITOut = 1'b0;
        read_out        = 1'b0;

        SR      = 8'b10000000;
        RCR     = 16'b1011111111001111;
        LATCHED = 1'b0;
        Viol    = 1'b0;
        word_cntr = 0;

    end

    ///////////////////////////////////////////////////////////////////////////
    //// Internal Delays
    ///////////////////////////////////////////////////////////////////////////
    always @(posedge BEFP_in)
    begin:BEFP
        BEFP_out = 1'b1;
        #tdevice_BEFP BEFP_out = 1'b0;
    end

    always @(posedge BEFPsetup_in)
    begin:BEFPsetup
        BEFPsetup_out = 1'b1;
        #tdevice_BEFPsetup BEFPsetup_out = 1'b0;
    end

    always @(posedge ProgramSuspend_in)
    begin:ProgramSuspend
        ProgramSuspend_out = 1'b1;
        #tdevice_ProgramSuspend ProgramSuspend_out = 1'b0;
    end

    always @(posedge EraseSuspend_in)
    begin:EraseSuspend
        EraseSuspend_out = 1'b1;
        #tdevice_EraseSuspend EraseSuspend_out = 1'b0;
    end

    always @(posedge RstDuringErsPrg_in)
    begin:RstDuringErsPrg
        RstDuringErsPrg_out = 1'b1;
        #tdevice_RstDuringErsPrg RstDuringErsPrg_out = 1'b0;
    end

    //////////////////////////////////////////////////////////////
    // Clock control
    //////////////////////////////////////////////////////////////

    always @ (posedge CLK_ipd)
    begin : CLKControl1
        if ((RSTNeg_ipd) && (~CENeg_ipd) && (WENeg_ipd) &&
        (RCR[15] == 1'b0) && (RCR[6] == 1'b1) &&
        (current_state != RESET_POWER_DOWN))
        begin
            CLOCK = 1'b1;
            #1 CLOCK <= 1'b0;
        end
    end

    always @ (negedge CLK_ipd)
    begin : CLKControl2
        if ((RSTNeg_ipd) && (~CENeg_ipd) && (WENeg_ipd) &&
        (RCR[15] == 1'b0) && (RCR[6] == 1'b0) &&
        (current_state != RESET_POWER_DOWN))
        begin
            CLOCK = 1'b1;
            #1 CLOCK <= 1'b0;
        end
    end

    always @ (negedge RSTNeg_ipd)
    begin : RSTControl
        if (WordProgram_out ||
        BuffProgram_out ||
        ParameterErase_out || MainErase_out || BEFP_out)
        begin
            RstDuringErsPrg_in = 1'b0;
            #1 RstDuringErsPrg_in <= 1'b1;
        end
    end

    //////////////////////////////////////////////////////////////////////////
    //// bus cycle decode
    //////////////////////////////////////////////////////////////////////////
    always @ (falling_edge_ADVNeg or rising_edge_ADVNeg or rising_edge_CLOCK
    or OENeg or RSTNeg or rising_edge_WENeg or rising_edge_CENeg or WENeg
    or CENeg or Alow_event)
    begin : BusCycleDecode
        if (~RSTNeg || CENeg || falling_edge_ADVNeg)
            LATCHED = 0;

        if (RSTNeg && current_state != RESET_POWER_DOWN)
        begin
            if (~CENeg && ~LATCHED && ((rising_edge_ADVNeg && WENeg) ||
            (~ADVNeg && WENeg && ~RCR[15] && rising_edge_CLOCK) ) )
            begin
                LatchedAddr = A;
                ReadAddr = A;
                LATCHED = 1'b1;
                burst_cntr = 0;
                BurstDelay = RCR[13:11];
                case (RCR[2:0])
                    3'b001: BurstLength = 4;
                    3'b010: BurstLength = 8;
                    3'b011: BurstLength = 16;
                    3'b111: BurstLength = 0;
                endcase
                DataHold = 0;
            end

            // Write control
            if (OENeg)
            begin
                if (~WENeg && ~CENeg)
                    Write = 0;
                else if ((~CENeg && rising_edge_WENeg) || (~WENeg &&
                rising_edge_CENeg)||(rising_edge_CENeg && rising_edge_WENeg))
                begin
                    LatchedData = DQIn;
                    LatchedAddr = A;
                    Write = 1;
                end
            end

            // Read control
            if (RCR[15])
            begin
                if (WENeg && ~CENeg && ~OENeg)
                begin
                    if (~ADVNeg)
                        ReadAddr = A;
                    Read = 1;
                end
                else
                begin
                    Read = 0;
                    Pmode = 0;
                end
                if (Read && Alow_event)
                begin
                    Pmode = 1;
                    Pmode <= #2 0;
                end
            end
            else
            begin
                if (rising_edge_CLOCK)
                begin
                    if (BurstDelay > 0)
                    begin
                        #1 BurstDelay = BurstDelay - 1;
                        if (RCR[8] && (BurstDelay == 0 || (BurstDelay == 1
                        && RCR[9] ) ) )
                            DeassertWAITOut = ~(DeassertWAITOut);
                    end
                    else
                    begin
                        if (DataHold == 0)
                        begin
                            burst_cntr = burst_cntr + 1;
                            if (~OENeg)
                                Read = ~(Read);
                            if (RCR[9])
                                DataHold = 1;
                            if ( (burst_cntr > (BurstLength - RCR[8]) ) &&
                            BurstLength > 0)
                                AssertWAITOut = ~(AssertWAITOut);
                            else if (read_state == READ_ARRAY && ~RCR[9] &&
                            RCR[13:11] > 4)
                            begin
                                if (~RCR[8])
                                begin
                                    if (burst_cntr > 4 || burst_cntr <= 0)
                                        AssertWAITOut = ~(AssertWAITOut);
                                    else
                                        DeassertWAITOut = ~(DeassertWAITOut);
                                end
                                else
                                begin
                                    if (burst_cntr >= 4 || burst_cntr < 0)
                                        AssertWAITOut = ~(AssertWAITOut);
                                    else
                                        DeassertWAITOut = ~(DeassertWAITOut);
                                end
                            end
                                DeassertWAITOut = ~(DeassertWAITOut);
                        end
                        else
                            DataHold = DataHold - 1;
                    end
                end
            end
        end
    end

//////////////////////////////////////////////////////////////////////////////
//// sequential process for reset control and FSM state transition
//////////////////////////////////////////////////////////////////////////////
    always @(next_state)
    begin : FSM
        if (ExtendProgTime == 1'b0)
            current_state = next_state;
    end

    ////////////////////////////////////////////////////////////////////////////
    //     obtain 'LAST_EVENT information
    ////////////////////////////////////////////////////////////////////////////
    always @(negedge OENeg_ipd)
    begin
        OENeg_event = $time;
    end
    always @(negedge CENeg_ipd)
    begin
        CENeg_event = $time;
    end
    always @(A)
    begin
        ADDR_event = $time;
    end

    ///////////////////////////////////////////////////////////////////////////
    // FSM - Combinational process for next state generation
    ///////////////////////////////////////////////////////////////////////////
    always @(falling_edge_RSTNeg or rising_edge_RSTNeg or rising_edge_Write or
        RstDuringErsPrg_out_event or WordProgram_out_event or abort or
        ProgramSuspend_out_event or BuffProgram_out_event
        or ExtendProgTime_event or falling_edge_EraseSuspend_out or
        ParameterErase_out_event or falling_edge_MainErase_out
        or falling_edge_BEFPsetup_out or falling_edge_BEFP_out
        )
    begin : StateGen

        if (falling_edge_RSTNeg)
            next_state = RESET_POWER_DOWN;
        else
        begin
            case (current_state)

            RESET_POWER_DOWN :
            begin
                if (((rising_edge_RSTNeg && ~RstDuringErsPrg_out) ||
                (RstDuringErsPrg_out_event && ~RstDuringErsPrg_out)) &&
                $time > 0 )
                begin
                    next_state = READY;
                end
            end

            READY:
            begin
                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'h10, 16'h40 : next_state = PROG_SETUP;
                        16'hE8 : next_state = BP_SETUP;
                        16'h20 : next_state = ERASE_SETUP;
                        16'h80 : next_state = BEFP_SETUP;
                        16'h60 : next_state = LOCK_SETUP;
                        16'hC0 : next_state = OTP_SETUP;
                        default : next_state = current_state;
                    endcase
                end
            end

            LOCK_SETUP  :
            begin
                if (rising_edge_Write)
                    next_state = READY;
            end

            OTP_SETUP  :
            begin
                if (rising_edge_Write)
                    next_state = OTP_BUSY;
            end

            OTP_BUSY :
            begin
                if (abort ||
                (WordProgram_out_event && ~WordProgram_out) )
                    next_state = READY;
            end

            PROG_SETUP :
            begin
                if (rising_edge_Write)
                    next_state = PROG_BUSY;
            end

            PROG_BUSY :
            begin
                if (abort ||
                (WordProgram_out_event && ~WordProgram_out) )
                    next_state = READY;
                else if (ProgramSuspend_out_event && ~ProgramSuspend_out)
                    next_state = PROG_SUSP;
            end

            PROG_SUSP :
            begin
                if (rising_edge_Write && LatchedData == 16'hD0)
                    next_state = PROG_BUSY;
            end

            BP_SETUP :
            begin
                if (rising_edge_Write)
                begin
                    word_cnt = LatchedData + 1;
                    next_state = BP_LOAD;
                end
            end

            BP_LOAD :
            begin
                if (rising_edge_Write)
                begin
                    word_cnt = word_cnt - 1;
                    if (word_cnt == 0)
                        next_state = BP_CONFIRM;
                end
            end

            BP_CONFIRM :
            begin
                if (rising_edge_Write)
                begin
                    if (LatchedData == 16'hD0)
                        next_state = BP_BUSY;
                    else
                        next_state = READY;
                end
            end

            BP_BUSY :
            begin
                if (abort ||
                (BuffProgram_out_event && ~BuffProgram_out && ~ExtendProgTime))
                    next_state = READY;
                else if (ProgramSuspend_out_event && ~ProgramSuspend_out)
                    next_state = BP_SUSP;
                else if (ExtendProgTime_event)
                    next_state = current_state;
            end

            BP_SUSP :
            begin
                if (rising_edge_Write && LatchedData == 16'hD0)
                    next_state = BP_BUSY;
            end

            ERASE_SETUP :
            begin
                if (rising_edge_Write)
                begin
                    if (LatchedData == 16'hD0)
                        next_state = ERASE_BUSY;
                    else
                        next_state = READY;
                end
            end

            ERASE_BUSY :
            begin
                if ((abort ||
                (ParameterErase_out_event && ~ParameterErase_out) ||
                (falling_edge_MainErase_out ) ) && ~suspended_erase)
                    next_state = READY;
                else if (falling_edge_EraseSuspend_out)
                    next_state = ERS_SUSP;
            end

            ERS_SUSP :
            begin
                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'h10, 16'h40: next_state = PROG_SETUP_ERS_SUSP;
                        16'hE8 : next_state = BP_SETUP_ERS_SUSP;
                        16'hD0: next_state = ERASE_BUSY;
                        16'h60: next_state = LOCK_SETUP_ERS_SUSP;
                        default: next_state = current_state;
                    endcase
                end
            end

            PROG_SETUP_ERS_SUSP :
            begin
                if (rising_edge_Write)
                    next_state = PROG_BUSY_ERS_SUSP;
            end

            PROG_BUSY_ERS_SUSP :
            begin
                if (abort ||
                (WordProgram_out_event && ~WordProgram_out) )
                    next_state = ERS_SUSP;
                else if (ProgramSuspend_out_event && ~ProgramSuspend_out)
                    next_state = PROG_SUSP_ERS_SUSP;
            end

            PROG_SUSP_ERS_SUSP :
            begin
                if (rising_edge_Write && LatchedData == 16'hD0)
                    next_state = PROG_BUSY_ERS_SUSP;
            end

            BP_SETUP_ERS_SUSP :
            begin
                if (rising_edge_Write)
                begin
                    word_cnt = LatchedData + 1;
                    next_state = BP_LOAD_ERS_SUSP;
                end
            end

            BP_LOAD_ERS_SUSP :
            begin
                if (rising_edge_Write)
                begin
                    word_cnt = word_cnt - 1;
                    if (word_cnt == 0)
                        next_state = BP_CONFIRM_ERS_SUSP;
                end
            end

            BP_CONFIRM_ERS_SUSP :
            begin
                if (rising_edge_Write)
                begin
                    if (LatchedData == 16'hD0)
                        next_state = BP_BUSY_ERS_SUSP;
                    else
                        next_state = ERS_SUSP;
                end
            end

            BP_BUSY_ERS_SUSP :
            begin
                if (abort ||
                (BuffProgram_out_event && ~BuffProgram_out && ~ExtendProgTime))
                    next_state = ERS_SUSP;
                else if (ProgramSuspend_out_event && ~ProgramSuspend_out)
                    next_state = BP_SUSP_ERS_SUSP;
                else if (ExtendProgTime_event)
                    next_state = current_state;
            end

            BP_SUSP_ERS_SUSP :
            begin
                if (rising_edge_Write && LatchedData == 16'hD0)
                    next_state = BP_BUSY_ERS_SUSP;
            end

            LOCK_SETUP_ERS_SUSP :
            begin
                if (rising_edge_Write)
                    next_state = ERS_SUSP;
            end

            BEFP_SETUP :
            begin
                if (rising_edge_Write)
                begin
                    if (LatchedData != 16'hD0)
                        next_state = READY;
                    else
                    begin
                        BEFP_block2 = BlockNumber(LatchedAddr);
                        word_cnt = 32;
                    end
                end
                else if (falling_edge_BEFPsetup_out)
                begin
                    if (SR[4] == 1'b0)
                        next_state = BEFP_LOAD;
                    else
                        next_state = READY;
                end
            end

            BEFP_LOAD :
            begin
                if (rising_edge_Write)
                begin
                    if ((BlockNumber(LatchedAddr) != BEFP_block2) &&
                    LatchedData == 16'hFFFF)
                        next_state = READY;
                    else
                    begin
                        word_cnt = word_cnt - 1;
                        if (word_cnt == 0)
                            next_state = BEFP_BUSY;
                    end
                end
            end

            BEFP_BUSY :
            begin
                if (falling_edge_BEFP_out)
                begin
                    word_cnt = 32;
                    next_state = BEFP_LOAD;
                end
            end
            endcase
        end
    end

    ////////////////////////////////////////////////////////////////////////////
    // Functional
    ////////////////////////////////////////////////////////////////////////////
    always @(rising_edge_Write or WordProgram_out_event or
             BuffProgram_out_event or falling_edge_RSTNeg or
             ParameterErase_out_event or falling_edge_MainErase_out or
             falling_edge_BEFPsetup_out or falling_edge_BEFP_out or
             abort or falling_edge_EraseSuspend_out or ProgramSuspend_out_event)
    begin

        if (rising_edge_Write)
        begin
            if ((current_state != RESET_POWER_DOWN) &&
            (current_state != OTP_BUSY) &&
            (current_state != PROG_BUSY) &&
            (current_state != BP_BUSY) &&
            (current_state != ERASE_BUSY) &&
            (current_state != PROG_BUSY_ERS_SUSP) &&
            (current_state != BP_BUSY_ERS_SUSP) &&
            (current_state != BEFP_SETUP) &&
            (current_state != BEFP_LOAD) &&
            (LatchedData == 8'h50))
                SR = 8'b10000000;
        end

        case (current_state)

            RESET_POWER_DOWN :
            begin
                SR = 8'b10000000;
                for (i=0;i<=BlockNum;i=i+1)
                begin
                    Block_Lock[i] = LOCKED;
                    BlockLockBit[i] = 1'b1;
                    BlockLockDownBit[i] = 1'b0;
                end
                read_state = READ_ARRAY;
                RCR = 16'b1011111111001111;
            end

            READY :
            begin
                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70 : read_state = READ_STATUS;
                        16'h90 : read_state = READ_ID;
                        16'h98 : read_state = READ_QUERY;
                    endcase
                end
            end

            LOCK_SETUP, LOCK_SETUP_ERS_SUSP :
            begin
                if (rising_edge_Write)
                begin
                    block_number = BlockNumber(LatchedAddr);
                    if (LatchedData == 16'h03)
                    begin
                        RCR = A[15:0];
                        read_state = READ_ARRAY;
                    end
                    else if (LatchedData == 16'h01)
                    begin
                        read_state = READ_STATUS;
                        if (Block_Lock[block_number] == UNLOCKED)
                            Block_Lock[block_number] = LOCKED;
                        BlockLockBit[block_number] = 1'b1;
                    end
                    else if (LatchedData == 16'hD0)
                    begin
                        read_state = READ_STATUS;
                        if (!( (Block_Lock[block_number] == LOCKED_DOWN) &&
                        WPNeg == 1'b0) )
                        begin
                            Block_Lock[block_number] = UNLOCKED;
                            BlockLockBit[block_number] = 0;
                        end
                    end
                    else if (LatchedData == 16'h2F)
                    begin
                        read_state = READ_STATUS;
                        Block_Lock[block_number] = LOCKED_DOWN;
                        BlockLockBit[block_number] = 1'b1;
                        BlockLockDownBit[block_number] = 1'b1;
                    end
                    else
                    begin
                        read_state = READ_STATUS;
                        SR[4] = 1'b1;
                        SR[5] = 1'b1;
                    end
                end
                else
                    read_state = READ_STATUS;
            end

            OTP_SETUP :
            begin
                read_state = READ_STATUS;
                if (rising_edge_Write)
                begin
                    DataBuff[0] = LatchedData;
                    AddrBuff[0] = LatchedAddr;
                    WordProgram_in = 1'b1;
                    WordProgram_in <= #1 1'b0;
                end
            end

            OTP_BUSY :
            begin
                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70, 16'h90, 16'h98 : read_state = READ_STATUS;
                    endcase
                end

                mem_bits = PR[9'h80];
                prog_bits = PR[9'h89];

                if (VPP != 1'b1)
                begin
                    SR[3] = 1'b1;
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if ((AddrBuff[0] < 9'h80) || (AddrBuff[0] > 9'h109))
                begin
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if ((AddrBuff[0] > 9'h80) && (AddrBuff[0] < 9'h85))
                begin
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if ((AddrBuff[0] > 9'h84) && (AddrBuff[0] < 9'h89) &&
                (mem_bits[1] != 1'b1))
                begin
                    SR[1] = 1'b1;
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if ((AddrBuff[0] > 9'h89) && (AddrBuff[0] < 9'h10A) &&
                (prog_bits[(AddrBuff[0]-9'h8A)/8] != 1'b1))
                begin
                    SR[1] = 1'b1;
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else
                    SR[7] = 1'b0;

                if (falling_edge_RSTNeg)
                    PR[AddrBuff[0]] = -1;

                if (WordProgram_out_event && ~WordProgram_out && ~abort)
                begin
                    if (PR[AddrBuff[0]] > -1)
                    begin
                        prog_bits = DataBuff[0];
                        mem_bits = PR[AddrBuff[0]];
                        for (i=0; i<= 15; i=i+1)
                        begin
                            if (prog_bits[i] == 0)
                                mem_bits[i] = 0;
                        end
                        PR[AddrBuff[0]] = mem_bits;
                    end
                    SR[7] = 1;
                end
            end

            PROG_SETUP, PROG_SETUP_ERS_SUSP :
            begin
                read_state = READ_STATUS;
                if (rising_edge_Write)
                begin
                    DataBuff[0] = LatchedData;
                    AddrBuff[0] = LatchedAddr;
                    WordProgram_in = 1;
                    WordProgram_in <= #1 0;
                end
            end

            PROG_BUSY, PROG_BUSY_ERS_SUSP :
            begin
                SR[2] = 0;
                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70 : read_state = READ_STATUS;
                        16'h90 : read_state = READ_ID;
                        16'h98 : read_state = READ_QUERY;
                        16'hB0 :
                        begin
                            ProgramSuspend_in = 1'b1;
                            ProgramSuspend_in <= #1 1'b0;
                        end
                    endcase
                end

                block_number = BlockNumber(AddrBuff[0]);

                if (VPP == 1'b0)
                begin
                    SR[3] = 1'b1;
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if (OTP[block_number] == 1'b1)
                begin
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if (Block_Lock[block_number] != UNLOCKED)
                begin
                    SR[1] = 1'b1;
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else
                    SR[7] = 1'b0;

                if (falling_edge_RSTNeg )
                    MemData[AddrBuff[0]] = -1;

                if (WordProgram_out_event && ~WordProgram_out && ~abort)
                begin
                    if (MemData[AddrBuff[0]] > -1 )
                    begin
                        prog_bits = DataBuff[0];
                        mem_bits = MemData[AddrBuff[0]];
                        for (i= 0; i<= 15; i=i+1)
                            if (prog_bits[i] == 0)
                                mem_bits[i] = 0;
                        MemData[AddrBuff[0]] = mem_bits;
                    end
                    SR[7] = 1;
                end
            end

            PROG_SUSP, PROG_SUSP_ERS_SUSP :
            begin
                SR[2] = 1'b1;
                SR[7] = 1'b1;

                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70 : read_state = READ_STATUS;
                        16'h90 : read_state = READ_ID;
                        16'h98 : read_state = READ_QUERY;
                        16'hD0 :
                        begin
                            WordProgramResume = 1'b1;
                            WordProgramResume <= #1 1'b0;
                        end
                    endcase
                end
            end

            BP_SETUP, BP_SETUP_ERS_SUSP :
            begin
                read_state = READ_STATUS;

                if (rising_edge_Write)
                begin
                    word_number = LatchedData;
                    word_cntr   = 0;
                end
            end

            BP_LOAD, BP_LOAD_ERS_SUSP :
            begin
                read_state = READ_STATUS;

                if (rising_edge_Write)
                begin
                    DataBuff[word_cntr] = LatchedData;
                    AddrBuff[word_cntr] = LatchedAddr;
                    if (word_cntr == 0)
                    begin
                        lowest_addr = LatchedAddr;
                        highest_addr = LatchedAddr;
                    end
                    else
                    begin
                        if (LatchedAddr < lowest_addr)
                            lowest_addr = LatchedAddr;
                        if (LatchedAddr > highest_addr)
                            highest_addr = LatchedAddr;
                    end
                    word_cntr = word_cntr + 1;
                end
            end

            BP_CONFIRM, BP_CONFIRM_ERS_SUSP :
            begin
                read_state = READ_STATUS;

                if (rising_edge_Write)
                begin
                    if (LatchedData != 16'hD0)
                    begin
                        SR[7] = 1'b1;
                        SR[5] = 1'b1;
                        SR[4] = 1'b1;
                    end
                    else if (LatchedData == 16'hD0)
                    begin
                        BuffProgram_in = 1;
                        BuffProgram_in <= #1 0;
                    end
                end
            end

            BP_BUSY, BP_BUSY_ERS_SUSP :
            begin
                SR[2] = 0;
                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70 : read_state = READ_STATUS;
                        16'h90 : read_state = READ_ID;
                        16'h98 : read_state = READ_QUERY;
                        16'hB0 :
                        begin
                            suspended_bp = 1'b1;
                            ProgramSuspend_in = 1'b1;
                            ProgramSuspend_in <= #1 1'b0;
                        end
                    endcase
                end

                block_number = BlockNumber(AddrBuff[0]);

                if (VPP == 0)
                begin
                    SR[3] = 1;
                    SR[4] = 1;
                    SR[7] = 1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if (OTP[block_number] == 1)
                begin
                    SR[4] = 1;
                    SR[7] = 1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if (Block_Lock[block_number] != UNLOCKED)
                begin
                    SR[1] = 1;
                    SR[4] = 1;
                    SR[7] = 1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if ((lowest_addr < AddrBuff[0]) ||
                (highest_addr > (AddrBuff[0]+word_number)) &&
                (word_number != -1))
                begin
                    SR[4] = 1;
                    SR[7] = 1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if (BlockNumber(highest_addr) != block_number)
                begin
                    SR[4] = 1;
                    SR[5] = 1;
                    SR[7] = 1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else
                    SR[7] = 0;

                if (falling_edge_RSTNeg)
                begin
                    for (j=0;j<=word_number; j=j+1)
                        MemData[AddrBuff[j]] = -1;
                end

                if ( BuffProgram_out_event && ~BuffProgram_out
                && ~suspended_bp && ~abort )
                begin
                    for (j=0; j<= word_number; j=j+1)
                    begin
                        if (MemData[AddrBuff[j]] > -1 )
                        begin
                            prog_bits = DataBuff[j];
                            mem_bits = MemData[AddrBuff[j]];
                            for (i=0; i<=15; i=i+1)
                            begin
                                if (prog_bits[i] == 1'b0)
                                    mem_bits[i] = 1'b0;
                            end
                            MemData[AddrBuff[j]] = mem_bits;
                        end
                    end
                    for (j=0; j<= word_number; j=j+1)
                    begin
                        if ((AddrBuff[j] / 32) != (AddrBuff[0]/32))
                        begin
                            ExtendProgTime = 1;
                            ExtendProgTime <= #1 0;
                            word_number = -1;
                            BuffProgram_in = 1'b1;
                            BuffProgram_in <= #1 1'b0;
                        end
                    end
                    SR[7] = 1;
                end
            end

            BP_SUSP, BP_SUSP_ERS_SUSP :
            begin
                SR[2] = 1'b1;
                SR[7] = 1'b1;

                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70 : read_state = READ_STATUS;
                        16'h90 : read_state = READ_ID;
                        16'h98 : read_state = READ_QUERY;
                        16'hD0 :
                        begin
                            suspended_bp = 1'b0;
                            BP_ProgramResume = 1'b1;
                            BP_ProgramResume <= #1 1'b0;
                        end
                    endcase
                end
            end

            ERASE_SETUP :
            begin
                read_state = READ_STATUS;

                if (rising_edge_Write)
                begin
                    if (LatchedData == 16'hD0)
                    begin
                        erasing_block = BlockNumber(LatchedAddr);
                        if (BlockSize(erasing_block) == ParameterBlockSize)
                        begin
                            ParameterErase_in = 1;
                            ParameterErase_in <= #1 0;
                        end
                        else
                        begin
                            MainErase_in = 1;
                            MainErase_in <= #1 0;
                        end
                    end
                    else
                    begin
                        SR[7] = 1'b1;
                        SR[5] = 1'b1;
                        SR[4] = 1'b1;
                    end
                end
            end

            ERASE_BUSY :
            begin
                SR[6] = 0;

                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70 : read_state = READ_STATUS;
                        16'h90 : read_state = READ_ID;
                        16'h98 : read_state = READ_QUERY;
                        16'hB0 :
                        begin
                            suspended_erase = 1'b1;
                            EraseSuspend_in = 1'b1;
                            EraseSuspend_in <= #1 1'b0;
                        end
                    endcase
                end

                aborted = 1'b0;

                if (VPP == 1'b0)
                begin
                    SR[3] = 1'b1;
                    SR[5] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                    aborted = 1'b1;
                end
                else if (OTP[erasing_block] == 1'b1)
                begin
                    SR[5] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                    aborted = 1'b1;
                end
                else if (Block_Lock[erasing_block] != UNLOCKED)
                begin
                    SR[1] = 1'b1;
                    SR[5] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                    aborted = 1'b1;
                end
                else
                    SR[7] = 1'b0;

                block_size = BlockSize(erasing_block);
                start_addr = StartBlockAddr(erasing_block);

                if (~aborted)
                begin
                    for (i = 0; i< block_size; i=i+1 )
                        MemData[start_addr + i] = -1;
                end

                if ( ( (ParameterErase_out_event && ~ParameterErase_out)
                || (falling_edge_MainErase_out)) && ~abort && ~suspended_erase)
                begin
                    SR[7] = 1'b1;
                    for (i=0;i<=block_size;i=i+1)
                        MemData[start_addr + i] = MaxData;
                end
            end

            ERS_SUSP :
            begin
                SR[6] = 1'b1;
                SR[7] = 1'b1;

                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70 : read_state = READ_STATUS;
                        16'h90 : read_state = READ_ID;
                        16'h98 : read_state = READ_QUERY;
                        16'hD0 :
                        begin
                            suspended_erase = 1'b0;
                            if (BlockSize(erasing_block) == ParameterBlockSize)
                            begin
                                ParameterEraseResume = 1'b1;
                                ParameterEraseResume <= #1 1'b0;
                            end
                            else
                            begin
                                MainEraseResume = 1'b1;
                                MainEraseResume <= #1 1'b0;
                            end
                        end
                    endcase
                end
            end

            BEFP_SETUP :
            begin
                read_state = READ_STATUS;

                if (rising_edge_Write && (LatchedData == 16'hD0))
                begin
                    BEFP_addr  = LatchedAddr;
                    BEFP_block = BlockNumber(LatchedAddr);
                    word_cntr = 0;
                    if ((VPP != 1'b1) || (VPP_voltage != 9))
                    begin
                        SR[3] = 1'b1;
                        SR[4] = 1'b1;
                    end
                    if (Block_Lock[BEFP_block] != UNLOCKED)
                    begin
                        SR[1] = 1'b1;
                        SR[4] = 1'b1;
                    end
                    else if (((BEFP_addr % 32) != 0) ||
                    (OTP[BEFP_block] == 1'b1))
                        SR[4] = 1'b1;
                    BEFPsetup_in = 1'b1;
                    BEFPsetup_in <= #1 1'b0;
                end
                else if (falling_edge_BEFPsetup_out)
                begin
                    if (SR[4] == 0)
                    begin
                        SR[7] = 0;
                        SR[0] = 0;
                    end
                end
            end

            BEFP_LOAD :
            begin
                if (rising_edge_Write)
                begin
                    if ((BlockNumber(LatchedAddr) != BEFP_block) &&
                    (LatchedData == 16'hFFFF))
                    begin
                        SR[7] = 1'b1;
                        SR[0] = 1'b0;
                    end
                    else
                    begin
                        DataBuff[word_cntr] = LatchedData;
                        word_cntr = word_cntr + 1;
                        if (word_cntr == 31)
                        begin
                            BEFP_in = 1'b1;
                            BEFP_in <= #1 1'b0;
                        end
                    end
                end
            end

            BEFP_BUSY :
            begin

                if (falling_edge_RSTNeg)
                begin
                    for (j = 0 ; j<= 31; j=j+1)
                        MemData[BEFP_addr+j] = -1;
                end

                if (falling_edge_BEFP_out)
                begin
                    for (j=0;j<=31;j=j+1)
                    begin
                        if (MemData[BEFP_addr+j] > -1)
                        begin
                            prog_bits = DataBuff[j];
                            mem_bits  = MemData[BEFP_addr + j];
                            for (i=0;i<=15;i=i+1)
                            begin
                                if (prog_bits[i] == 1'b0)
                                    mem_bits[i] = 1'b0;
                            end
                            MemData[BEFP_addr + j] = mem_bits;
                        end
                    end
                    BEFP_addr = BEFP_addr + 32;
                    if ((BEFP_addr > MemSize) ||
                    (BlockNumber(BEFP_addr) > BEFP_block))
                        BEFP_addr = BEFP_addr - BlockSize(BEFP_block);
                    SR[0] = 1'b0;
                    word_cntr = 0;
                end
                else
                    SR[0] = 1'b1;
            end

        endcase
    end

    ///////////////////////////////////////////////////////////
    // Combinatorial output generation
    ///////////////////////////////////////////////////////////
    always @(Ahigh_event or Alow_event or rising_edge_Read or
        A_event or OENeg or falling_edge_Read or CENeg
        )
    begin : Output
        case (read_state)
            READ_ARRAY :
            begin
                if (RCR[15] == 1'b1)
                begin
                    if (Ahigh_event && ~ADVNeg)
                        ReadAddr = A;
                    else if (Alow_event)
                        ReadAddr = ReadAddr - (ReadAddr % 4) + A[1:0];
                end

                if (current_state == PROG_BUSY ||
                current_state == PROG_BUSY_ERS_SUSP ||
                current_state == BP_BUSY ||
                current_state == BP_BUSY_ERS_SUSP ||
                current_state == ERASE_BUSY)
                    DQOut_tmp = 16'bx;
                else
                begin
                    if (MemData[ReadAddr] > -1)
                        DQOut_tmp = MemData[ReadAddr];
                    else
                        DQOut_tmp = 16'bx;
                end
            end

            READ_ID :
            begin
                if ( ( ( (ReadAddr-2) % MainBlockSize) == 0) ||
                ((ReadAddr > (MemSize - MainBlockSize)) &&
                (((ReadAddr-2) % ParameterBlockSize) == 0)))
                begin
                    DQOut_tmp[0] = BlockLockBit[BlockNumber(ReadAddr)];
                    DQOut_tmp[1] = BlockLockDownBit[BlockNumber(ReadAddr)];
                    DQOut_tmp[15:2] = 14'b0;
                end
                else if (ReadAddr == 0)
                    DQOut_tmp = 16'h0089;
                else if (ReadAddr == 1)
                begin
                    DQOut_tmp = DeviceID_T;
                end
                else if (ReadAddr == 5)
                    DQOut_tmp = RCR;
                else if ((ReadAddr >= 9'h80) && (ReadAddr <= 9'h109))
                begin
                    if (PR[ReadAddr] > -1)
                        DQOut_tmp = PR[ReadAddr];
                    else
                        DQOut_tmp = 16'bx;
                end
            end

            READ_QUERY :
            begin
                if (((ReadAddr >= 9'h10) && (ReadAddr <= 9'h38)) ||
                ((ReadAddr >= 9'h10A) && (ReadAddr <= 9'h156)))
                    DQOut_tmp = CFI_array[ReadAddr];
                else
                    DQOut_tmp = 16'b0;
            end

            READ_STATUS :
            begin
                DQOut_tmp[15:8] = 8'b0;
                DQOut_tmp[7:0] = SR;
            end
        endcase

        if (RCR[15] == 1'b1) // Asynchronous read
        begin
            if (rising_edge_Read || (Read && ((A_event && ~ADVNeg) ||
            Alow_event)))
                DQOut_zd = DQOut_tmp;
            else if (falling_edge_Read)
                DQOut_zd = 16'bz;
        end
        else // Burst read
        begin
            if (rising_edge_Read || falling_edge_Read)
            begin
                if ((burst_cntr > BurstLength) && (BurstLength != 0))
                    read_out = 1'b0;
                else if (read_state == READ_ARRAY)
                begin
                    if ((RCR[9] == 1'b0) && (RCR[13:11] > 4) &&
                    ((burst_cntr >= 5) || (burst_cntr < 1)))
                    begin
                        read_out = 1'b0;
                        if (burst_cntr >= 5)
                            burst_cntr = 5 - RCR[13:11];
                    end
                    else
                    begin
                        read_out = 1'b1;
                        if (ReadAddr < MemSize)
                            ReadAddr = ReadAddr + 1;
                        if ((RCR[3] == 1'b0) && (BurstLength != 0) &&
                        ((ReadAddr % BurstLength) == 0))
                            ReadAddr = ReadAddr - BurstLength;
                    end
                end
                else
                    read_out = 1'b1;

                if (read_out)
                begin
                    DQOut_zd = DQOut_tmp;
                end
            end
        end
    end

    always @(CENeg, OENeg)
    begin : OutputDisable
        if ((CENeg) || (OENeg))
            DQOut_zd = 16'bz;
        else if ((~CENeg) && (~OENeg) && (RCR[15] == 1'b0))
            DQOut_zd = 16'bx;
    end

    ////////////////////////////////////////////////////////////////
    // WAIT output control process
    ////////////////////////////////////////////////////////////////
    always @(AssertWAITOut_event or DeassertWAITOut_event or falling_edge_OENeg
    or OENeg or CENeg or falling_edge_CENeg)
    begin : WAITOut_control

        if (OENeg || CENeg || ~RSTNeg || (current_state == RESET_POWER_DOWN))
            WAITOut_zd = 1'bz;
        else if ((falling_edge_OENeg && ~CENeg) ||
        (falling_edge_CENeg && ~OENeg))
        begin
            if (RCR[15] == 1'b1)
            begin
                if (~RCR[10])
                    WAITOut_zd = 1'b1;
                else
                    WAITOut_zd = 1'b0;
            end
            else
            begin
                if (~RCR[10])
                    WAITOut_zd = 1'b0;
                else
                    WAITOut_zd = 1'b1;
            end
        end
        else if (AssertWAITOut_event)
        begin
            if (~RCR[10])
                WAITOut_zd = 1'b0;
            else
                WAITOut_zd = 1'b1;
        end
        else if (DeassertWAITOut_event)
        begin
            if (~RCR[10])
                WAITOut_zd = 1'b1;
            else
                WAITOut_zd = 1'b0;
        end
    end

    ///////////////////////////////////////////////////////////////////
    // Timing control for erase start, suspend and resume
    ///////////////////////////////////////////////////////////////////
    always @(rising_edge_MainErase_in or rising_edge_ParameterErase_in or
             RstDuringErsPrg_out_event or
             abort_event or
             rising_edge_ParameterEraseResume or EraseSuspend_event or
             rising_edge_MainEraseResume )
    begin : erase_time
        merase_duration = tdevice_EraseMain;
        perase_duration = tdevice_EraseParameter;

        if (rising_edge_MainErase_in)
        begin
            melapsed = 0;
            MainErase_out <= #1 1'b1;
            ->merase_event;
            mstart = $time;
        end
        if (rising_edge_ParameterErase_in)
        begin
            pelapsed = 0;
            ParameterErase_out <= #1 1'b1;
            ->perase_event;
            pstart = $time;
        end
        if ((RstDuringErsPrg_out_event && ~RstDuringErsPrg_out) ||
        abort_event)
        begin
            disable merase_process;
            disable perase_process;
            MainErase_out = 1'b0;
            ParameterErase_out = 1'b0;
        end

        if (EraseSuspend_event && ~EraseSuspend_out)
        begin
            disable merase_process;
            melapsed = $time - mstart;
            merase_duration = merase_duration - melapsed;
            disable perase_process;
            pelapsed = $time - pstart;
            perase_duration = perase_duration - pelapsed;
        end
        if (rising_edge_MainEraseResume)
        begin
            mstart = $time;
            MainErase_out = 1'b1;
            -> merase_event;
        end
        if (rising_edge_ParameterEraseResume)
        begin
            pstart = $time;
            ParameterErase_out = 1'b1;
            ->perase_event;
        end
    end

    always @(merase_event)
    begin : merase_process
        #merase_duration MainErase_out = 1'b0;
    end
    always @(perase_event)
    begin : perase_process
        #perase_duration ParameterErase_out = 1'b0;
    end

    /////////////////////////////////////////////////////////////////
    // Timing control for programming start, suspend and resume
    /////////////////////////////////////////////////////////////////
    time buffp_duration;
    time wordp_duration;
    time welapsed;
    time elapsed;
    event prog_event;
    event buffp_event;
    time wstart;
    time start;
    reg rising_edge_WordProgram_in = 1'b0;
    reg rising_edge_BuffProgram_in = 1'b0;
    reg rising_edge_WordProgramResume = 1'b0;
    reg rising_edge_BP_ProgramResume = 1'b0;

    always @(rising_edge_WordProgram_in or rising_edge_BuffProgram_in or
             RstDuringErsPrg_out_event or
             abort_event or
             ProgramSuspend_out_event or rising_edge_WordProgramResume or
             rising_edge_BP_ProgramResume)
    begin
        if (VPP_voltage != 9)
        begin
            buffp_duration = tdevice_BuffProgram;
            wordp_duration = tdevice_WordProgram;
        end
        else
        begin
            buffp_duration = tdevice_BuffProgram9V;
            wordp_duration = tdevice_WordProgram9V;
        end

        if (rising_edge_WordProgram_in)
        begin
            welapsed = 0;
            WordProgram_out <= #1 1'b1;
            -> prog_event;
            wstart = $time;
        end
        if (rising_edge_BuffProgram_in)
        begin
            elapsed = 0;
            BuffProgram_out = 1'b1;
            -> buffp_event;
            start = $time;
        end
        if ((RstDuringErsPrg_out_event && ~RstDuringErsPrg_out) ||
        abort_event)
        begin
            disable prog_process;
            disable buffp_process;
            WordProgram_out = 1'b0;
            BuffProgram_out = 1'b0;
        end

        if (ProgramSuspend_out_event && ~ProgramSuspend_out)
        begin
            disable prog_process;
            disable buffp_process;
            elapsed = $time - start;
            welapsed = $time - wstart;
            buffp_duration = buffp_duration - elapsed;
            wordp_duration = wordp_duration - welapsed;
        end
        if (rising_edge_WordProgramResume)
        begin
            wstart = $time;
            WordProgram_out = 1'b1;
            -> prog_event;
        end
        if (rising_edge_BP_ProgramResume)
        begin
            start = $time;
            BuffProgram_out = 1'b1;
            -> buffp_event;
        end
    end

    always @(prog_event)
    begin : prog_process
        #wordp_duration WordProgram_out = 1'b0;
    end
    always @(buffp_event)
    begin : buffp_process
        #buffp_duration BuffProgram_out = 1'b0;
    end

    ////////////////////////////////////////////////////////////////////
    //Output timing control
    ////////////////////////////////////////////////////////////////////
    always @(DQOut_zd)
    begin : OutputGen
        if (DQOut_zd[0] !== 1'bz)
        begin
            CEDQ_t = CENeg_event  + CEDQ_01;
            OEDQ_t = OENeg_event  + OEDQ_01;
            ADDRDQ_t = ADDR_event + ADDRDQIN_01;
            if (Pmode)
                ADDRDQ_t = ADDR_event + ADDRDQPAGE_01;

            FROMCE = ((CEDQ_t >= OEDQ_t) && (CEDQ_t >= $time));
            FROMOE = ((OEDQ_t >= CEDQ_t) && (OEDQ_t >= $time));
            FROMADDR = 1'b1;

            DQOut_Pass = DQOut_zd;
        end
    end

    always @(DQOut_zd)
    begin
        if (DQOut_zd[0] === 1'bz)
        begin
            disable OutputGen;
            FROMCE = 1'b1;
            FROMOE = 1'b1;
            FROMADDR = 1'b0;
            DQOut_Pass = DQOut_zd;
        end
    end

    reg  BuffInOE, BuffInCE, BuffInADDRIN, BuffInADDRPAGE;
    wire BuffOutOE, BuffOutCE, BuffOutADDRIN, BuffOutADDRPAGE;

    BUFFER    BUFOE   (BuffOutOE, BuffInOE);
    BUFFER    BUFCE   (BuffOutCE, BuffInCE);
    BUFFER    BUFADDRIN (BuffOutADDRIN, BuffInADDRIN);
    BUFFER    BUFADDRPAGE (BuffOutADDRPAGE, BuffInADDRPAGE);

    initial
    begin
        BuffInOE   = 1'b1;
        BuffInCE   = 1'b1;
        BuffInADDRIN = 1'b1;
        BuffInADDRPAGE = 1'b1;
    end

    always @(posedge BuffOutOE)
    begin
        OEDQ_01 = $time;
    end
    always @(posedge BuffOutCE)
    begin
        CEDQ_01 = $time;
    end
    always @(posedge BuffOutADDRIN)
    begin
        ADDRDQIN_01 = $time;
    end
    always @(posedge BuffOutADDRPAGE)
    begin
        ADDRDQPAGE_01 = $time;
    end

/////////////////////////////////////////////////////////////////////////////
// functions & tasks
/////////////////////////////////////////////////////////////////////////////
    function integer BlockNumber;
        input [HiAddrBit:0] ADDR;
        integer block_number;
    begin
        block_number = ADDR / MainBlockSize;
        if (block_number == (MemSize/MainBlockSize))
            block_number = block_number +
                (ADDR % MainBlockSize) / ParameterBlockSize;
        BlockNumber = block_number;
    end
    endfunction

    function integer StartBlockAddr;
        input [16:0] block_number;
        integer start_block_addr;
    begin
        start_block_addr = block_number * MainBlockSize;
        if (block_number > (BlockNum - 3))
            start_block_addr = start_block_addr
                - (block_number + 3 - BlockNum) * MainBlockSize
                + (block_number + 3 - BlockNum) * ParameterBlockSize;
        StartBlockAddr = start_block_addr;
    end
    endfunction

    function integer BlockSize;
        input [16:0] block_number;
        integer block_number;
        integer block_size;
    begin
        if ((block_number < 4)  ||
        (block_number > (BlockNum - 4)) )
            block_size = ParameterBlockSize;
        else
            block_size = MainBlockSize;
        BlockSize = block_size;
    end
    endfunction

    ////////////////////////////////////////////////////////////////
    // edge controll processes
    ////////////////////////////////////////////////////////////////
    always @(negedge ADVNeg)
    begin
        falling_edge_ADVNeg = 1;
        #1 falling_edge_ADVNeg = 0;
    end

    always @(posedge ADVNeg)
    begin
        rising_edge_ADVNeg  = 1;
        #1 rising_edge_ADVNeg = 0;
    end

    always @(posedge CLOCK)
    begin
        rising_edge_CLOCK = 1;
        #1 rising_edge_CLOCK = 0;
    end

    always @(negedge RSTNeg)
    begin
        falling_edge_RSTNeg = 1;
        #1 falling_edge_RSTNeg = 0;
    end

    always @(posedge RSTNeg)
    begin
        rising_edge_RSTNeg = 1;
        #1 rising_edge_RSTNeg = 0;
    end

    always @(posedge Write)
    begin
        rising_edge_Write = 1;
        #1 rising_edge_Write = 0;
    end

    always @(RstDuringErsPrg_out)
    begin
        RstDuringErsPrg_out_event = 1;
        #1 RstDuringErsPrg_out_event = 0;
    end

    always @(WordProgram_out)
    begin
        WordProgram_out_event = 1;
        #1 WordProgram_out_event = 0;
    end

    always @(ProgramSuspend_out)
    begin
        ProgramSuspend_out_event = 1;
        #1 ProgramSuspend_out_event = 0;
    end

    always @(BuffProgram_out)
    begin
        if (~suspended_bp)
        begin
            BuffProgram_out_event = 1;
            #1 BuffProgram_out_event = 0;
        end
    end

    always @(posedge ExtendProgTime)
    begin
        ExtendProgTime_event = 1;
        #1 ExtendProgTime_event = 0;
    end

    always @(ParameterErase_out)
    begin
        ParameterErase_out_event = 1;
        #1 ParameterErase_out_event = 0;
    end

    always @(negedge MainErase_out)
    begin
        falling_edge_MainErase_out = 1;
        #1 falling_edge_MainErase_out = 0;
    end

    always @(negedge EraseSuspend_out)
    begin
        falling_edge_EraseSuspend_out = 1;
        #1 falling_edge_EraseSuspend_out = 0;
    end

    always @(negedge BEFPsetup_out)
    begin
        falling_edge_BEFPsetup_out = 1;
        #1 falling_edge_BEFPsetup_out = 0;
    end

    always @(negedge BEFP_out)
    begin
        falling_edge_BEFP_out = 1;
        #1 falling_edge_BEFP_out = 0;
    end

    always @(A[HiAddrBit:2])
    begin
        Ahigh_event = 1;
        #1 Ahigh_event = 0;
    end

    always @(A[1:0])
    begin
        Alow_event = 1;
        #1 Alow_event = 0;
    end

    always @(A)
    begin
        A_event = 1;
        #1 A_event = 0;
    end

    always @(posedge Read)
    begin
        rising_edge_Read = 1;
        #1 rising_edge_Read = 0;
    end

    always @(negedge Read)
    begin
        falling_edge_Read = 1;
        #1 falling_edge_Read = 0;
    end

    always @(posedge CENeg)
    begin
        rising_edge_CENeg = 1;
        #1 rising_edge_CENeg = 0;
    end

    always @(posedge OENeg)
    begin
        rising_edge_OENeg = 1;
        #1 rising_edge_OENeg = 0;
    end

    always @(AssertWAITOut)
    begin
        AssertWAITOut_event = 1;
        #1 AssertWAITOut_event = 0;
    end

    always @(DeassertWAITOut)
    begin
        DeassertWAITOut_event = 1;
        #1 DeassertWAITOut_event = 0;
    end

    always @(negedge OENeg)
    begin
        falling_edge_OENeg = 1;
        #1 falling_edge_OENeg = 0;
    end

    always @(negedge CENeg)
    begin
        falling_edge_CENeg = 1;
        #1 falling_edge_CENeg = 0;
    end

    always @(posedge WENeg)
    begin
        rising_edge_WENeg = 1;
        #1 rising_edge_WENeg = 0;
    end

    always @(posedge WordProgram_in)
    begin
        rising_edge_WordProgram_in = 1'b1;
        #1 rising_edge_WordProgram_in = 1'b0;
    end

    always @(posedge BuffProgram_in)
    begin
        rising_edge_BuffProgram_in = 1'b1;
        #1 rising_edge_BuffProgram_in = 1'b0;
    end

    always @(posedge BP_ProgramResume)
    begin
        rising_edge_BP_ProgramResume = 1'b1;
        #1 rising_edge_BP_ProgramResume = 1'b0;
    end
    always @(posedge WordProgramResume)
    begin
        rising_edge_WordProgramResume = 1'b1;
        #1 rising_edge_WordProgramResume = 1'b0;
    end

    always @(posedge MainErase_in)
    begin
        rising_edge_MainErase_in = 1'b1;
        #1 rising_edge_MainErase_in = 1'b0;
    end

    always @(posedge ParameterErase_in)
    begin
        rising_edge_ParameterErase_in = 1'b1;
        #1 rising_edge_ParameterErase_in = 1'b0;
    end

    always @(posedge MainEraseResume)
    begin
        rising_edge_MainEraseResume = 1'b1;
        #1 rising_edge_MainEraseResume = 1'b0;
    end

    always @(posedge ParameterEraseResume)
    begin
        rising_edge_ParameterEraseResume = 1'b1;
        #1 rising_edge_ParameterEraseResume = 1'b0;
    end

    always @(EraseSuspend_out)
    begin
        EraseSuspend_event = 1'b1;
        #1 EraseSuspend_event = 1'b0;
    end

endmodule

//////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION, Bottom Parameter Block Configuration                 //
//////////////////////////////////////////////////////////////////////////////
module i28f256p33_2
    (
        A24             ,
        A23             ,
        A22             ,
        A21             ,
        A20             ,
        A19             ,
        A18             ,
        A17             ,
        A16             ,
        A15             ,
        A14             ,
        A13             ,
        A12             ,
        A11             ,
        A10             ,
        A9              ,
        A8              ,
        A7              ,
        A6              ,
        A5              ,
        A4              ,
        A3              ,
        A2              ,
        A1              ,

        DQ15            ,
        DQ14            ,
        DQ13            ,
        DQ12            ,
        DQ11            ,
        DQ10            ,
        DQ9             ,
        DQ8             ,
        DQ7             ,
        DQ6             ,
        DQ5             ,
        DQ4             ,
        DQ3             ,
        DQ2             ,
        DQ1             ,
        DQ0             ,

        ADVNeg          ,
        CENeg           ,
        CLK             ,
        OENeg           ,
        RSTNeg          ,
        WENeg           ,
        WPNeg           ,
        VPP             ,

        WAITOut
     );

////////////////////////////////////////////////////////////////////////
// Port / Part Pin Declarations
////////////////////////////////////////////////////////////////////////
    input  A24             ;
    input  A23             ;
    input  A22             ;
    input  A21             ;
    input  A20             ;
    input  A19             ;
    input  A18             ;
    input  A17             ;
    input  A16             ;
    input  A15             ;
    input  A14             ;
    input  A13             ;
    input  A12             ;
    input  A11             ;
    input  A10             ;
    input  A9              ;
    input  A8              ;
    input  A7              ;
    input  A6              ;
    input  A5              ;
    input  A4              ;
    input  A3              ;
    input  A2              ;
    input  A1              ;

    inout  DQ15            ;
    inout  DQ14            ;
    inout  DQ13            ;
    inout  DQ12            ;
    inout  DQ11            ;
    inout  DQ10            ;
    inout  DQ9             ;
    inout  DQ8             ;
    inout  DQ7             ;
    inout  DQ6             ;
    inout  DQ5             ;
    inout  DQ4             ;
    inout  DQ3             ;
    inout  DQ2             ;
    inout  DQ1             ;
    inout  DQ0             ;

    input  ADVNeg          ;
    input  CENeg           ;
    input  CLK             ;
    input  OENeg           ;
    input  RSTNeg          ;
    input  WENeg           ;
    input  WPNeg           ;
    input  VPP             ;

    output WAITOut         ;

    // interconnect path delay signals
    wire  A24_ipd  ;
    wire  A23_ipd  ;
    wire  A22_ipd  ;
    wire  A21_ipd  ;
    wire  A20_ipd  ;
    wire  A19_ipd  ;
    wire  A18_ipd  ;
    wire  A17_ipd  ;
    wire  A16_ipd  ;
    wire  A15_ipd  ;
    wire  A14_ipd  ;
    wire  A13_ipd  ;
    wire  A12_ipd  ;
    wire  A11_ipd  ;
    wire  A10_ipd  ;
    wire  A9_ipd   ;
    wire  A8_ipd   ;
    wire  A7_ipd   ;
    wire  A6_ipd   ;
    wire  A5_ipd   ;
    wire  A4_ipd   ;
    wire  A3_ipd   ;
    wire  A2_ipd   ;
    wire  A1_ipd   ;

    wire [23 : 0] A;
    assign A = {
                A24_ipd,
                A23_ipd,
                A22_ipd,
                A21_ipd,
                A20_ipd,
                A19_ipd,
                A18_ipd,
                A17_ipd,
                A16_ipd,
                A15_ipd,
                A14_ipd,
                A13_ipd,
                A12_ipd,
                A11_ipd,
                A10_ipd,
                A9_ipd,
                A8_ipd,
                A7_ipd,
                A6_ipd,
                A5_ipd,
                A4_ipd,
                A3_ipd,
                A2_ipd,
                A1_ipd };

    wire  DQ15_ipd  ;
    wire  DQ14_ipd  ;
    wire  DQ13_ipd  ;
    wire  DQ12_ipd  ;
    wire  DQ11_ipd  ;
    wire  DQ10_ipd  ;
    wire  DQ9_ipd   ;
    wire  DQ8_ipd   ;
    wire  DQ7_ipd   ;
    wire  DQ6_ipd   ;
    wire  DQ5_ipd   ;
    wire  DQ4_ipd   ;
    wire  DQ3_ipd   ;
    wire  DQ2_ipd   ;
    wire  DQ1_ipd   ;
    wire  DQ0_ipd   ;

    wire [15 : 0 ] DQIn;
    assign DQIn = {DQ15_ipd,
                   DQ14_ipd,
                   DQ13_ipd,
                   DQ12_ipd,
                   DQ11_ipd,
                   DQ10_ipd,
                   DQ9_ipd,
                   DQ8_ipd,
                   DQ7_ipd,
                   DQ6_ipd,
                   DQ5_ipd,
                   DQ4_ipd,
                   DQ3_ipd,
                   DQ2_ipd,
                   DQ1_ipd,
                   DQ0_ipd };

    wire [15 : 0 ] DQOut;
    assign DQOut = {DQ15,
                    DQ14,
                    DQ13,
                    DQ12,
                    DQ11,
                    DQ10,
                    DQ9,
                    DQ8,
                    DQ7,
                    DQ6,
                    DQ5,
                    DQ4,
                    DQ3,
                    DQ2,
                    DQ1,
                    DQ0 };

    wire  ADVNeg_ipd      ;
    wire  CENeg_ipd       ;
    wire  CLK_ipd         ;
    wire  OENeg_ipd       ;
    wire  RSTNeg_ipd      ;
    wire  WENeg_ipd       ;
    wire  WPNeg_ipd       ;

    wire  DQ15_zd  ;
    wire  DQ14_zd  ;
    wire  DQ13_zd  ;
    wire  DQ12_zd  ;
    wire  DQ11_zd  ;
    wire  DQ10_zd  ;
    wire  DQ9_zd   ;
    wire  DQ8_zd   ;
    wire  DQ7_zd   ;
    wire  DQ6_zd   ;
    wire  DQ5_zd   ;
    wire  DQ4_zd   ;
    wire  DQ3_zd   ;
    wire  DQ2_zd   ;
    wire  DQ1_zd   ;
    wire  DQ0_zd   ;

    wire  DQ15_Pass  ;
    wire  DQ14_Pass  ;
    wire  DQ13_Pass  ;
    wire  DQ12_Pass  ;
    wire  DQ11_Pass  ;
    wire  DQ10_Pass  ;
    wire  DQ9_Pass   ;
    wire  DQ8_Pass   ;
    wire  DQ7_Pass   ;
    wire  DQ6_Pass   ;
    wire  DQ5_Pass   ;
    wire  DQ4_Pass   ;
    wire  DQ3_Pass   ;
    wire  DQ2_Pass   ;
    wire  DQ1_Pass   ;
    wire  DQ0_Pass   ;

    reg [15 : 0] DQOut_zd = 16'bz;
    reg [15 : 0] DQOut_Pass = 16'bz;

    assign {DQ15_zd,
            DQ14_zd,
            DQ13_zd,
            DQ12_zd,
            DQ11_zd,
            DQ10_zd,
            DQ9_zd,
            DQ8_zd,
            DQ7_zd,
            DQ6_zd,
            DQ5_zd,
            DQ4_zd,
            DQ3_zd,
            DQ2_zd,
            DQ1_zd,
            DQ0_zd  } = DQOut_zd;

    assign {DQ15_Pass,
            DQ14_Pass,
            DQ13_Pass,
            DQ12_Pass,
            DQ11_Pass,
            DQ10_Pass,
            DQ9_Pass,
            DQ8_Pass,
            DQ7_Pass,
            DQ6_Pass,
            DQ5_Pass,
            DQ4_Pass,
            DQ3_Pass,
            DQ2_Pass,
            DQ1_Pass,
            DQ0_Pass  } = DQOut_Pass;

    reg WAITOut_zd = 1'bz;

    parameter mem_file_name   = "none";
    parameter otp_blocks_file = "none";
    parameter prot_reg_file   = "none";
    parameter UserPreload     = 1'b0;
    parameter TimingModel     = "DefaultTimingModel";
    parameter VPP_voltage = 9;    // this parameter specifies if
                                  // 9V or 2V is applied to Vpp pin
                                  // (when VPP pin is 1'b1)

    parameter MaxData            = 16'hFFFF;
    parameter HiAddrBit          = 23;
    parameter MemSize            = 32'hFFFFFF;
    parameter BlockNum           = 258;
    parameter DeviceID_B         = 16'h8922;
    parameter DeviceID_T         = 16'h891F;
    parameter MainBlockSize      = 32'h10000;
    parameter ParameterBlockSize = 32'h04000;

    // If speedsimulation is needed uncomment following line

//       `define SPEEDSIM;

    // FSM states
    parameter        RESET_POWER_DOWN    = 5'd0;
    parameter        READY               = 5'd1;
    parameter        LOCK_SETUP          = 5'd2;
    parameter        OTP_SETUP           = 5'd3;
    parameter        OTP_BUSY            = 5'd4;
    parameter        PROG_SETUP          = 5'd5;
    parameter        PROG_BUSY           = 5'd6;
    parameter        PROG_SUSP           = 5'd7;
    parameter        BP_SETUP            = 5'd8;
    parameter        BP_LOAD             = 5'd9;
    parameter        BP_CONFIRM          = 5'd10;
    parameter        BP_BUSY             = 5'd11;
    parameter        BP_SUSP             = 5'd12;
    parameter        ERASE_SETUP         = 5'd13;
    parameter        ERASE_BUSY          = 5'd14;
    parameter        ERS_SUSP            = 5'd15;
    parameter        PROG_SETUP_ERS_SUSP = 5'd16;
    parameter        PROG_BUSY_ERS_SUSP  = 5'd17;
    parameter        PROG_SUSP_ERS_SUSP  = 5'd18;
    parameter        BP_SETUP_ERS_SUSP   = 5'd19;
    parameter        BP_LOAD_ERS_SUSP    = 5'd20;
    parameter        BP_CONFIRM_ERS_SUSP = 5'd21;
    parameter        BP_BUSY_ERS_SUSP    = 5'd22;
    parameter        BP_SUSP_ERS_SUSP    = 5'd23;
    parameter        LOCK_SETUP_ERS_SUSP = 5'd24;
    parameter        BEFP_SETUP          = 5'd25;
    parameter        BEFP_LOAD           = 5'd26;
    parameter        BEFP_BUSY           = 5'd27;

    // read mode
    parameter        READ_ARRAY   = 2'd0;
    parameter        READ_ID      = 2'd1;
    parameter        READ_QUERY   = 2'd2;
    parameter        READ_STATUS  = 2'd3;

    reg [5:0]      current_state;
    reg [5:0]      next_state;

    reg [1:0]      read_state;

    reg            deq;

    // Memory declaration
    integer MemData[0:MemSize];

    // internal delays
    reg WordProgram_in         = 1'b0;
    reg WordProgram_out        = 1'b0;
    reg BuffProgram_in         = 1'b0;
    reg BuffProgram_out        = 1'b0;
    reg BEFP_in                = 1'b0;
    reg BEFP_out               = 1'b0;
    reg BEFPsetup_in           = 1'b0;
    reg BEFPsetup_out          = 1'b0;
    reg ParameterErase_in      = 1'b0;
    reg MainErase_in           = 1'b0;
    reg ParameterErase_out     = 1'b0;
    reg MainErase_out          = 1'b0;
    reg ProgramSuspend_in      = 1'b0;
    reg ProgramSuspend_out     = 1'b0;
    reg EraseSuspend_in        = 1'b0;
    reg EraseSuspend_out       = 1'b0;
    reg RstDuringErsPrg_in     = 1'b0;
    reg RstDuringErsPrg_out    = 1'b0;

    // event control registers
    reg falling_edge_ADVNeg = 1'b0;
    reg falling_edge_RSTNeg = 1'b0;
    reg falling_edge_BEFPsetup_out = 1'b0;
    reg falling_edge_BEFP_out = 1'b0;
    reg falling_edge_Read  = 1'b0;
    reg falling_edge_OENeg = 1'b0;
    reg falling_edge_CENeg = 1'b0;
    reg rising_edge_ADVNeg = 1'b0;
    reg rising_edge_CLOCK  = 1'b0;
    reg rising_edge_WENeg  = 1'b0;
    reg rising_edge_CENeg  = 1'b0;
    reg rising_edge_RSTNeg = 1'b0;
    reg rising_edge_Write  = 1'b0;
    reg rising_edge_Read   = 1'b0;
    reg RstDuringErsPrg_out_event = 1'b0;
    reg WordProgram_out_event    = 1'b0;
    reg abort_event              = 1'b0;
    reg ProgramSuspend_out_event = 1'b0;
    reg BuffProgram_out_event    = 1'b0;
    reg ExtendProgTime_event     = 1'b0;
    reg ParameterErase_out_event = 1'b0;
    reg falling_edge_MainErase_out    = 1'b0;
    reg falling_edge_EraseSuspend_out = 1'b0;
    reg Ahigh_event           = 1'b0;
    reg Alow_event            = 1'b0;
    reg A_event               = 1'b0;
    reg rising_edge_OENeg     = 1'b0;
    reg AssertWAITOut_event   = 1'b0;
    reg DeassertWAITOut_event = 1'b0;
    reg rising_edge_MainErase_in      = 1'b0;
    reg rising_edge_ParameterErase_in = 1'b0;
    reg EraseSuspend_event            = 1'b0;
    reg rising_edge_MainEraseResume   = 1'b0;
    reg rising_edge_ParameterEraseResume = 1'b0;

    integer i,j;

    // Bus cycle decode
    reg CLOCK = 1'b0;

    reg Write = 1'b0;
    reg Read  = 1'b0;

    reg Pmode = 1'b0;

    // Functional
    reg abort           = 1'b0;

    reg ExtendProgTime  = 1'b0;

    reg AssertWAITOut   = 1'b0;
    reg DeassertWAITOut = 1'b0;

    //Block Lock Status
    parameter UNLOCKED    = 2'd0;
    parameter LOCKED      = 2'd1;
    parameter LOCKED_DOWN = 2'd2;
    integer Block_Lock[BlockNum:0];
    reg [BlockNum:0] BlockLockBit;
    reg [BlockNum:0] BlockLockDownBit;
    reg OTP[0:BlockNum];

    // Status Register
    reg[7:0]    SR   = 8'b10000000;

    // Read Configuration Register
    reg[15:0]   RCR   = 16'b1011111111001111;

    // Protection registers
    integer PR[9'h80:9'h109];

    // CFI array
    integer CFI_array[9'h10:9'h156];

    reg LATCHED = 1'b0;
    reg [15:0] LatchedData;
    reg [HiAddrBit:0] LatchedAddr;
    integer ReadAddr;

    integer DataBuff[0:31];
    integer AddrBuff[0:31];

    integer burst_cntr;
    integer BurstLength;
    integer BurstDelay;
    integer DataHold;

    integer WCount;
    integer word_cntr;
    integer word_cnt;
    integer word_number;
    integer block_number;
    integer erasing_block;

    integer lowest_addr;
    integer highest_addr;
    integer start_addr;

    integer BEFP_addr;
    integer BEFP_block;
    integer BEFP_block2;

    reg [15:0] mem_bits;
    reg [15:0] prog_bits;

    reg [15:0] DQOut_tmp;
    reg read_out = 1'b0;

    reg suspended_bp = 1'b0;
    reg suspended_erase = 1'b0;

    reg aborted ;
    integer block_size;

    reg ParameterEraseResume;
    reg MainEraseResume;
    reg WordProgramResume;
    reg BP_ProgramResume;
    time merase_duration;
    time perase_duration;
    time melapsed;
    time pelapsed;
    time mstart;
    time pstart;
    event merase_event;
    event perase_event;

    // timing check violation
    reg Viol = 1'b0;

    //TPD_XX_DATA
    time           OEDQ_t;
    time           CEDQ_t;
    time           ADDRDQ_t;
    time           OENeg_event;
    time           CENeg_event;
    time           ADDR_event;
    reg            FROMOE;
    reg            FROMCE;
    reg            FROMADDR;
    reg            OPENLATCH;
    integer        OEDQ_01;
    integer        CEDQ_01;
    integer        ADDRDQIN_01;
    integer        ADDRDQPAGE_01;
    reg [15:0]     TempData;

    wire InitialPageAccess;
    assign InitialPageAccess = FROMADDR && ~Pmode;

    wire SubsequentPageAccess;
    assign SubsequentPageAccess = FROMADDR && Pmode;

    wire CLK_rising;
    assign CLK_rising = RCR[6] && ~CENeg_ipd;

    wire CLK_falling;
    assign CLK_falling = ~(RCR[6]) && ~CENeg_ipd;

///////////////////////////////////////////////////////////////////////////////
//Interconnect Path Delay Section
///////////////////////////////////////////////////////////////////////////////
    buf   (A24_ipd, A24);
    buf   (A23_ipd, A23);
    buf   (A22_ipd, A22);
    buf   (A21_ipd, A21);
    buf   (A20_ipd, A20);
    buf   (A19_ipd, A19);
    buf   (A18_ipd, A18);
    buf   (A17_ipd, A17);
    buf   (A16_ipd, A16);
    buf   (A15_ipd, A15);
    buf   (A14_ipd, A14);
    buf   (A13_ipd, A13);
    buf   (A12_ipd, A12);
    buf   (A11_ipd, A11);
    buf   (A10_ipd, A10);
    buf   (A9_ipd , A9 );
    buf   (A8_ipd , A8 );
    buf   (A7_ipd , A7 );
    buf   (A6_ipd , A6 );
    buf   (A5_ipd , A5 );
    buf   (A4_ipd , A4 );
    buf   (A3_ipd , A3 );
    buf   (A2_ipd , A2 );
    buf   (A1_ipd , A1 );

    buf   (DQ15_ipd, DQ15);
    buf   (DQ14_ipd, DQ14);
    buf   (DQ13_ipd, DQ13);
    buf   (DQ12_ipd, DQ12);
    buf   (DQ11_ipd, DQ11);
    buf   (DQ10_ipd, DQ10);
    buf   (DQ9_ipd , DQ9 );
    buf   (DQ8_ipd , DQ8 );
    buf   (DQ7_ipd , DQ7 );
    buf   (DQ6_ipd , DQ6 );
    buf   (DQ5_ipd , DQ5 );
    buf   (DQ4_ipd , DQ4 );
    buf   (DQ3_ipd , DQ3 );
    buf   (DQ2_ipd , DQ2 );
    buf   (DQ1_ipd , DQ1 );
    buf   (DQ0_ipd , DQ0 );

    buf   (RSTNeg_ipd , RSTNeg );
    buf   (ADVNeg_ipd , ADVNeg );
    buf   (CLK_ipd    , CLK );
    buf   (CENeg_ipd  , CENeg );
    buf   (OENeg_ipd  , OENeg );
    buf   (WENeg_ipd  , WENeg );
    buf   (WPNeg_ipd  , WPNeg );

///////////////////////////////////////////////////////////////////////////////
// Propagation  delay Section
///////////////////////////////////////////////////////////////////////////////
    nmos   (DQ15,   DQ15_Pass , 1);
    nmos   (DQ14,   DQ14_Pass , 1);
    nmos   (DQ13,   DQ13_Pass , 1);
    nmos   (DQ12,   DQ12_Pass , 1);
    nmos   (DQ11,   DQ11_Pass , 1);
    nmos   (DQ10,   DQ10_Pass , 1);
    nmos   (DQ9 ,   DQ9_Pass  , 1);
    nmos   (DQ8 ,   DQ8_Pass  , 1);
    nmos   (DQ7 ,   DQ7_Pass  , 1);
    nmos   (DQ6 ,   DQ6_Pass  , 1);
    nmos   (DQ5 ,   DQ5_Pass  , 1);
    nmos   (DQ4 ,   DQ4_Pass  , 1);
    nmos   (DQ3 ,   DQ3_Pass  , 1);
    nmos   (DQ2 ,   DQ2_Pass  , 1);
    nmos   (DQ1 ,   DQ1_Pass  , 1);
    nmos   (DQ0 ,   DQ0_Pass  , 1);

    nmos   (WAITOut, WAITOut_zd, 1);

    wire deg;

specify
    // tipd delays: interconnect path delays , mapped to input port delays.
    // In Verilog is not necessary to declare any tipd_ delay variables,
    // they can be taken from SDF file
    // With all the other delays real delays would be taken from SDF file

    // tpd delays
    specparam           tpd_A1_DQ0             =1;
    specparam           tpd_A1_DQ1             =1;
    specparam           tpd_A1_DQ2             =1;
    specparam           tpd_A1_DQ3             =1;
    specparam           tpd_A1_DQ4             =1;
    specparam           tpd_A1_DQ5             =1;
    specparam           tpd_A1_DQ6             =1;
    specparam           tpd_A1_DQ7             =1;
    specparam           tpd_A1_DQ8             =1;
    specparam           tpd_A1_DQ9             =1;
    specparam           tpd_A1_DQ10            =1;
    specparam           tpd_A1_DQ11            =1;
    specparam           tpd_A1_DQ12            =1;
    specparam           tpd_A1_DQ13            =1;
    specparam           tpd_A1_DQ14            =1;
    specparam           tpd_A1_DQ15            =1;
    specparam           tpd_A2_DQ0             =1;
    specparam           tpd_A2_DQ1             =1;
    specparam           tpd_A2_DQ2             =1;
    specparam           tpd_A2_DQ3             =1;
    specparam           tpd_A2_DQ4             =1;
    specparam           tpd_A2_DQ5             =1;
    specparam           tpd_A2_DQ6             =1;
    specparam           tpd_A2_DQ7             =1;
    specparam           tpd_A2_DQ8             =1;
    specparam           tpd_A2_DQ9             =1;
    specparam           tpd_A2_DQ10            =1;
    specparam           tpd_A2_DQ11            =1;
    specparam           tpd_A2_DQ12            =1;
    specparam           tpd_A2_DQ13            =1;
    specparam           tpd_A2_DQ14            =1;
    specparam           tpd_A2_DQ15            =1;
    specparam           tpd_A3_DQ0             =1;
    specparam           tpd_A3_DQ1             =1;
    specparam           tpd_A3_DQ2             =1;
    specparam           tpd_A3_DQ3             =1;
    specparam           tpd_A3_DQ4             =1;
    specparam           tpd_A3_DQ5             =1;
    specparam           tpd_A3_DQ6             =1;
    specparam           tpd_A3_DQ7             =1;
    specparam           tpd_A3_DQ8             =1;
    specparam           tpd_A3_DQ9             =1;
    specparam           tpd_A3_DQ10            =1;
    specparam           tpd_A3_DQ11            =1;
    specparam           tpd_A3_DQ12            =1;
    specparam           tpd_A3_DQ13            =1;
    specparam           tpd_A3_DQ14            =1;
    specparam           tpd_A3_DQ15            =1;
    specparam           tpd_A4_DQ0             =1;
    specparam           tpd_A4_DQ1             =1;
    specparam           tpd_A4_DQ2             =1;
    specparam           tpd_A4_DQ3             =1;
    specparam           tpd_A4_DQ4             =1;
    specparam           tpd_A4_DQ5             =1;
    specparam           tpd_A4_DQ6             =1;
    specparam           tpd_A4_DQ7             =1;
    specparam           tpd_A4_DQ8             =1;
    specparam           tpd_A4_DQ9             =1;
    specparam           tpd_A4_DQ10            =1;
    specparam           tpd_A4_DQ11            =1;
    specparam           tpd_A4_DQ12            =1;
    specparam           tpd_A4_DQ13            =1;
    specparam           tpd_A4_DQ14            =1;
    specparam           tpd_A4_DQ15            =1;
    specparam           tpd_A5_DQ0             =1;
    specparam           tpd_A5_DQ1             =1;
    specparam           tpd_A5_DQ2             =1;
    specparam           tpd_A5_DQ3             =1;
    specparam           tpd_A5_DQ4             =1;
    specparam           tpd_A5_DQ5             =1;
    specparam           tpd_A5_DQ6             =1;
    specparam           tpd_A5_DQ7             =1;
    specparam           tpd_A5_DQ8             =1;
    specparam           tpd_A5_DQ9             =1;
    specparam           tpd_A5_DQ10            =1;
    specparam           tpd_A5_DQ11            =1;
    specparam           tpd_A5_DQ12            =1;
    specparam           tpd_A5_DQ13            =1;
    specparam           tpd_A5_DQ14            =1;
    specparam           tpd_A5_DQ15            =1;
    specparam           tpd_A6_DQ0             =1;
    specparam           tpd_A6_DQ1             =1;
    specparam           tpd_A6_DQ2             =1;
    specparam           tpd_A6_DQ3             =1;
    specparam           tpd_A6_DQ4             =1;
    specparam           tpd_A6_DQ5             =1;
    specparam           tpd_A6_DQ6             =1;
    specparam           tpd_A6_DQ7             =1;
    specparam           tpd_A6_DQ8             =1;
    specparam           tpd_A6_DQ9             =1;
    specparam           tpd_A6_DQ10            =1;
    specparam           tpd_A6_DQ11            =1;
    specparam           tpd_A6_DQ12            =1;
    specparam           tpd_A6_DQ13            =1;
    specparam           tpd_A6_DQ14            =1;
    specparam           tpd_A6_DQ15            =1;
    specparam           tpd_A7_DQ0             =1;
    specparam           tpd_A7_DQ1             =1;
    specparam           tpd_A7_DQ2             =1;
    specparam           tpd_A7_DQ3             =1;
    specparam           tpd_A7_DQ4             =1;
    specparam           tpd_A7_DQ5             =1;
    specparam           tpd_A7_DQ6             =1;
    specparam           tpd_A7_DQ7             =1;
    specparam           tpd_A7_DQ8             =1;
    specparam           tpd_A7_DQ9             =1;
    specparam           tpd_A7_DQ10            =1;
    specparam           tpd_A7_DQ11            =1;
    specparam           tpd_A7_DQ12            =1;
    specparam           tpd_A7_DQ13            =1;
    specparam           tpd_A7_DQ14            =1;
    specparam           tpd_A7_DQ15            =1;
    specparam           tpd_A8_DQ0             =1;
    specparam           tpd_A8_DQ1             =1;
    specparam           tpd_A8_DQ2             =1;
    specparam           tpd_A8_DQ3             =1;
    specparam           tpd_A8_DQ4             =1;
    specparam           tpd_A8_DQ5             =1;
    specparam           tpd_A8_DQ6             =1;
    specparam           tpd_A8_DQ7             =1;
    specparam           tpd_A8_DQ8             =1;
    specparam           tpd_A8_DQ9             =1;
    specparam           tpd_A8_DQ10            =1;
    specparam           tpd_A8_DQ11            =1;
    specparam           tpd_A8_DQ12            =1;
    specparam           tpd_A8_DQ13            =1;
    specparam           tpd_A8_DQ14            =1;
    specparam           tpd_A8_DQ15            =1;
    specparam           tpd_A9_DQ0             =1;
    specparam           tpd_A9_DQ1             =1;
    specparam           tpd_A9_DQ2             =1;
    specparam           tpd_A9_DQ3             =1;
    specparam           tpd_A9_DQ4             =1;
    specparam           tpd_A9_DQ5             =1;
    specparam           tpd_A9_DQ6             =1;
    specparam           tpd_A9_DQ7             =1;
    specparam           tpd_A9_DQ8             =1;
    specparam           tpd_A9_DQ9             =1;
    specparam           tpd_A9_DQ10            =1;
    specparam           tpd_A9_DQ11            =1;
    specparam           tpd_A9_DQ12            =1;
    specparam           tpd_A9_DQ13            =1;
    specparam           tpd_A9_DQ14            =1;
    specparam           tpd_A9_DQ15            =1;
    specparam           tpd_A10_DQ0            =1;
    specparam           tpd_A10_DQ1            =1;
    specparam           tpd_A10_DQ2            =1;
    specparam           tpd_A10_DQ3            =1;
    specparam           tpd_A10_DQ4            =1;
    specparam           tpd_A10_DQ5            =1;
    specparam           tpd_A10_DQ6            =1;
    specparam           tpd_A10_DQ7            =1;
    specparam           tpd_A10_DQ8            =1;
    specparam           tpd_A10_DQ9            =1;
    specparam           tpd_A10_DQ10           =1;
    specparam           tpd_A10_DQ11           =1;
    specparam           tpd_A10_DQ12           =1;
    specparam           tpd_A10_DQ13           =1;
    specparam           tpd_A10_DQ14           =1;
    specparam           tpd_A10_DQ15           =1;
    specparam           tpd_A11_DQ0            =1;
    specparam           tpd_A11_DQ1            =1;
    specparam           tpd_A11_DQ2            =1;
    specparam           tpd_A11_DQ3            =1;
    specparam           tpd_A11_DQ4            =1;
    specparam           tpd_A11_DQ5            =1;
    specparam           tpd_A11_DQ6            =1;
    specparam           tpd_A11_DQ7            =1;
    specparam           tpd_A11_DQ8            =1;
    specparam           tpd_A11_DQ9            =1;
    specparam           tpd_A11_DQ10           =1;
    specparam           tpd_A11_DQ11           =1;
    specparam           tpd_A11_DQ12           =1;
    specparam           tpd_A11_DQ13           =1;
    specparam           tpd_A11_DQ14           =1;
    specparam           tpd_A11_DQ15           =1;
    specparam           tpd_A12_DQ0            =1;
    specparam           tpd_A12_DQ1            =1;
    specparam           tpd_A12_DQ2            =1;
    specparam           tpd_A12_DQ3            =1;
    specparam           tpd_A12_DQ4            =1;
    specparam           tpd_A12_DQ5            =1;
    specparam           tpd_A12_DQ6            =1;
    specparam           tpd_A12_DQ7            =1;
    specparam           tpd_A12_DQ8            =1;
    specparam           tpd_A12_DQ9            =1;
    specparam           tpd_A12_DQ10           =1;
    specparam           tpd_A12_DQ11           =1;
    specparam           tpd_A12_DQ12           =1;
    specparam           tpd_A12_DQ13           =1;
    specparam           tpd_A12_DQ14           =1;
    specparam           tpd_A12_DQ15           =1;
    specparam           tpd_A13_DQ0            =1;
    specparam           tpd_A13_DQ1            =1;
    specparam           tpd_A13_DQ2            =1;
    specparam           tpd_A13_DQ3            =1;
    specparam           tpd_A13_DQ4            =1;
    specparam           tpd_A13_DQ5            =1;
    specparam           tpd_A13_DQ6            =1;
    specparam           tpd_A13_DQ7            =1;
    specparam           tpd_A13_DQ8            =1;
    specparam           tpd_A13_DQ9            =1;
    specparam           tpd_A13_DQ10           =1;
    specparam           tpd_A13_DQ11           =1;
    specparam           tpd_A13_DQ12           =1;
    specparam           tpd_A13_DQ13           =1;
    specparam           tpd_A13_DQ14           =1;
    specparam           tpd_A13_DQ15           =1;
    specparam           tpd_A14_DQ0            =1;
    specparam           tpd_A14_DQ1            =1;
    specparam           tpd_A14_DQ2            =1;
    specparam           tpd_A14_DQ3            =1;
    specparam           tpd_A14_DQ4            =1;
    specparam           tpd_A14_DQ5            =1;
    specparam           tpd_A14_DQ6            =1;
    specparam           tpd_A14_DQ7            =1;
    specparam           tpd_A14_DQ8            =1;
    specparam           tpd_A14_DQ9            =1;
    specparam           tpd_A14_DQ10           =1;
    specparam           tpd_A14_DQ11           =1;
    specparam           tpd_A14_DQ12           =1;
    specparam           tpd_A14_DQ13           =1;
    specparam           tpd_A14_DQ14           =1;
    specparam           tpd_A14_DQ15           =1;
    specparam           tpd_A15_DQ0            =1;
    specparam           tpd_A15_DQ1            =1;
    specparam           tpd_A15_DQ2            =1;
    specparam           tpd_A15_DQ3            =1;
    specparam           tpd_A15_DQ4            =1;
    specparam           tpd_A15_DQ5            =1;
    specparam           tpd_A15_DQ6            =1;
    specparam           tpd_A15_DQ7            =1;
    specparam           tpd_A15_DQ8            =1;
    specparam           tpd_A15_DQ9            =1;
    specparam           tpd_A15_DQ10           =1;
    specparam           tpd_A15_DQ11           =1;
    specparam           tpd_A15_DQ12           =1;
    specparam           tpd_A15_DQ13           =1;
    specparam           tpd_A15_DQ14           =1;
    specparam           tpd_A15_DQ15           =1;
    specparam           tpd_A16_DQ0            =1;
    specparam           tpd_A16_DQ1            =1;
    specparam           tpd_A16_DQ2            =1;
    specparam           tpd_A16_DQ3            =1;
    specparam           tpd_A16_DQ4            =1;
    specparam           tpd_A16_DQ5            =1;
    specparam           tpd_A16_DQ6            =1;
    specparam           tpd_A16_DQ7            =1;
    specparam           tpd_A16_DQ8            =1;
    specparam           tpd_A16_DQ9            =1;
    specparam           tpd_A16_DQ10           =1;
    specparam           tpd_A16_DQ11           =1;
    specparam           tpd_A16_DQ12           =1;
    specparam           tpd_A16_DQ13           =1;
    specparam           tpd_A16_DQ14           =1;
    specparam           tpd_A16_DQ15           =1;
    specparam           tpd_A17_DQ0            =1;
    specparam           tpd_A17_DQ1            =1;
    specparam           tpd_A17_DQ2            =1;
    specparam           tpd_A17_DQ3            =1;
    specparam           tpd_A17_DQ4            =1;
    specparam           tpd_A17_DQ5            =1;
    specparam           tpd_A17_DQ6            =1;
    specparam           tpd_A17_DQ7            =1;
    specparam           tpd_A17_DQ8            =1;
    specparam           tpd_A17_DQ9            =1;
    specparam           tpd_A17_DQ10           =1;
    specparam           tpd_A17_DQ11           =1;
    specparam           tpd_A17_DQ12           =1;
    specparam           tpd_A17_DQ13           =1;
    specparam           tpd_A17_DQ14           =1;
    specparam           tpd_A17_DQ15           =1;
    specparam           tpd_A18_DQ0            =1;
    specparam           tpd_A18_DQ1            =1;
    specparam           tpd_A18_DQ2            =1;
    specparam           tpd_A18_DQ3            =1;
    specparam           tpd_A18_DQ4            =1;
    specparam           tpd_A18_DQ5            =1;
    specparam           tpd_A18_DQ6            =1;
    specparam           tpd_A18_DQ7            =1;
    specparam           tpd_A18_DQ8            =1;
    specparam           tpd_A18_DQ9            =1;
    specparam           tpd_A18_DQ10           =1;
    specparam           tpd_A18_DQ11           =1;
    specparam           tpd_A18_DQ12           =1;
    specparam           tpd_A18_DQ13           =1;
    specparam           tpd_A18_DQ14           =1;
    specparam           tpd_A18_DQ15           =1;
    specparam           tpd_A19_DQ0            =1;
    specparam           tpd_A19_DQ1            =1;
    specparam           tpd_A19_DQ2            =1;
    specparam           tpd_A19_DQ3            =1;
    specparam           tpd_A19_DQ4            =1;
    specparam           tpd_A19_DQ5            =1;
    specparam           tpd_A19_DQ6            =1;
    specparam           tpd_A19_DQ7            =1;
    specparam           tpd_A19_DQ8            =1;
    specparam           tpd_A19_DQ9            =1;
    specparam           tpd_A19_DQ10           =1;
    specparam           tpd_A19_DQ11           =1;
    specparam           tpd_A19_DQ12           =1;
    specparam           tpd_A19_DQ13           =1;
    specparam           tpd_A19_DQ14           =1;
    specparam           tpd_A19_DQ15           =1;
    specparam           tpd_A20_DQ0            =1;
    specparam           tpd_A20_DQ1            =1;
    specparam           tpd_A20_DQ2            =1;
    specparam           tpd_A20_DQ3            =1;
    specparam           tpd_A20_DQ4            =1;
    specparam           tpd_A20_DQ5            =1;
    specparam           tpd_A20_DQ6            =1;
    specparam           tpd_A20_DQ7            =1;
    specparam           tpd_A20_DQ8            =1;
    specparam           tpd_A20_DQ9            =1;
    specparam           tpd_A20_DQ10           =1;
    specparam           tpd_A20_DQ11           =1;
    specparam           tpd_A20_DQ12           =1;
    specparam           tpd_A20_DQ13           =1;
    specparam           tpd_A20_DQ14           =1;
    specparam           tpd_A20_DQ15           =1;
    specparam           tpd_A21_DQ0            =1;
    specparam           tpd_A21_DQ1            =1;
    specparam           tpd_A21_DQ2            =1;
    specparam           tpd_A21_DQ3            =1;
    specparam           tpd_A21_DQ4            =1;
    specparam           tpd_A21_DQ5            =1;
    specparam           tpd_A21_DQ6            =1;
    specparam           tpd_A21_DQ7            =1;
    specparam           tpd_A21_DQ8            =1;
    specparam           tpd_A21_DQ9            =1;
    specparam           tpd_A21_DQ10           =1;
    specparam           tpd_A21_DQ11           =1;
    specparam           tpd_A21_DQ12           =1;
    specparam           tpd_A21_DQ13           =1;
    specparam           tpd_A21_DQ14           =1;
    specparam           tpd_A21_DQ15           =1;
    specparam           tpd_A22_DQ0            =1;
    specparam           tpd_A22_DQ1            =1;
    specparam           tpd_A22_DQ2            =1;
    specparam           tpd_A22_DQ3            =1;
    specparam           tpd_A22_DQ4            =1;
    specparam           tpd_A22_DQ5            =1;
    specparam           tpd_A22_DQ6            =1;
    specparam           tpd_A22_DQ7            =1;
    specparam           tpd_A22_DQ8            =1;
    specparam           tpd_A22_DQ9            =1;
    specparam           tpd_A22_DQ10           =1;
    specparam           tpd_A22_DQ11           =1;
    specparam           tpd_A22_DQ12           =1;
    specparam           tpd_A22_DQ13           =1;
    specparam           tpd_A22_DQ14           =1;
    specparam           tpd_A22_DQ15           =1;
    specparam           tpd_A23_DQ0            =1;
    specparam           tpd_A23_DQ1            =1;
    specparam           tpd_A23_DQ2            =1;
    specparam           tpd_A23_DQ3            =1;
    specparam           tpd_A23_DQ4            =1;
    specparam           tpd_A23_DQ5            =1;
    specparam           tpd_A23_DQ6            =1;
    specparam           tpd_A23_DQ7            =1;
    specparam           tpd_A23_DQ8            =1;
    specparam           tpd_A23_DQ9            =1;
    specparam           tpd_A23_DQ10           =1;
    specparam           tpd_A23_DQ11           =1;
    specparam           tpd_A23_DQ12           =1;
    specparam           tpd_A23_DQ13           =1;
    specparam           tpd_A23_DQ14           =1;
    specparam           tpd_A23_DQ15           =1;
    specparam           tpd_A24_DQ0            =1;
    specparam           tpd_A24_DQ1            =1;
    specparam           tpd_A24_DQ2            =1;
    specparam           tpd_A24_DQ3            =1;
    specparam           tpd_A24_DQ4            =1;
    specparam           tpd_A24_DQ5            =1;
    specparam           tpd_A24_DQ6            =1;
    specparam           tpd_A24_DQ7            =1;
    specparam           tpd_A24_DQ8            =1;
    specparam           tpd_A24_DQ9            =1;
    specparam           tpd_A24_DQ10           =1;
    specparam           tpd_A24_DQ11           =1;
    specparam           tpd_A24_DQ12           =1;
    specparam           tpd_A24_DQ13           =1;
    specparam           tpd_A24_DQ14           =1;
    specparam           tpd_A24_DQ15           =1;

    specparam           tpd_CENeg_DQ0           =1;
    specparam           tpd_CENeg_DQ1           =1;
    specparam           tpd_CENeg_DQ2           =1;
    specparam           tpd_CENeg_DQ3           =1;
    specparam           tpd_CENeg_DQ4           =1;
    specparam           tpd_CENeg_DQ5           =1;
    specparam           tpd_CENeg_DQ6           =1;
    specparam           tpd_CENeg_DQ7           =1;
    specparam           tpd_CENeg_DQ8           =1;
    specparam           tpd_CENeg_DQ9           =1;
    specparam           tpd_CENeg_DQ10          =1;
    specparam           tpd_CENeg_DQ11          =1;
    specparam           tpd_CENeg_DQ12          =1;
    specparam           tpd_CENeg_DQ13          =1;
    specparam           tpd_CENeg_DQ14          =1;
    specparam           tpd_CENeg_DQ15          =1;

    specparam           tpd_OENeg_DQ0           =1;
    specparam           tpd_OENeg_DQ1           =1;
    specparam           tpd_OENeg_DQ2           =1;
    specparam           tpd_OENeg_DQ3           =1;
    specparam           tpd_OENeg_DQ4           =1;
    specparam           tpd_OENeg_DQ5           =1;
    specparam           tpd_OENeg_DQ6           =1;
    specparam           tpd_OENeg_DQ7           =1;
    specparam           tpd_OENeg_DQ8           =1;
    specparam           tpd_OENeg_DQ9           =1;
    specparam           tpd_OENeg_DQ10          =1;
    specparam           tpd_OENeg_DQ11          =1;
    specparam           tpd_OENeg_DQ12          =1;
    specparam           tpd_OENeg_DQ13          =1;
    specparam           tpd_OENeg_DQ14          =1;
    specparam           tpd_OENeg_DQ15          =1;

    specparam           tpd_CLK_DQ0              =1;
    specparam           tpd_CLK_DQ1              =1;
    specparam           tpd_CLK_DQ2              =1;
    specparam           tpd_CLK_DQ3              =1;
    specparam           tpd_CLK_DQ4              =1;
    specparam           tpd_CLK_DQ5              =1;
    specparam           tpd_CLK_DQ6              =1;
    specparam           tpd_CLK_DQ7              =1;
    specparam           tpd_CLK_DQ8              =1;
    specparam           tpd_CLK_DQ9              =1;
    specparam           tpd_CLK_DQ10             =1;
    specparam           tpd_CLK_DQ11             =1;
    specparam           tpd_CLK_DQ12             =1;
    specparam           tpd_CLK_DQ13             =1;
    specparam           tpd_CLK_DQ14             =1;
    specparam           tpd_CLK_DQ15             =1;

    specparam           tpd_CE0Neg_WAITOut       =1;
    specparam           tpd_OE0Neg_WAITOut       =1;
    specparam           tpd_CLK_WAITOut          =1;

    //tsetup values
    specparam           tsetup_A1_ADVNeg               =1;
    specparam           tsetup_A2_ADVNeg               =1;
    specparam           tsetup_A3_ADVNeg               =1;
    specparam           tsetup_A4_ADVNeg               =1;
    specparam           tsetup_A5_ADVNeg               =1;
    specparam           tsetup_A6_ADVNeg               =1;
    specparam           tsetup_A7_ADVNeg               =1;
    specparam           tsetup_A8_ADVNeg               =1;
    specparam           tsetup_A9_ADVNeg               =1;
    specparam           tsetup_A10_ADVNeg              =1;
    specparam           tsetup_A11_ADVNeg              =1;
    specparam           tsetup_A12_ADVNeg              =1;
    specparam           tsetup_A13_ADVNeg              =1;
    specparam           tsetup_A14_ADVNeg              =1;
    specparam           tsetup_A15_ADVNeg              =1;
    specparam           tsetup_A16_ADVNeg              =1;
    specparam           tsetup_A17_ADVNeg              =1;
    specparam           tsetup_A18_ADVNeg              =1;
    specparam           tsetup_A19_ADVNeg              =1;
    specparam           tsetup_A20_ADVNeg              =1;
    specparam           tsetup_A21_ADVNeg              =1;
    specparam           tsetup_A22_ADVNeg              =1;
    specparam           tsetup_A23_ADVNeg              =1;
    specparam           tsetup_A24_ADVNeg              =1;

    specparam           tsetup_CENeg_ADVNeg            =1;
    specparam           tsetup_RSTNeg_ADVNeg           =1;
    specparam           tsetup_CLK_ADVNeg              =1;
    specparam           tsetup_WENeg_ADVNeg            =1;

    specparam           tsetup_A1_CLK                  =1;
    specparam           tsetup_A2_CLK                  =1;
    specparam           tsetup_A3_CLK                  =1;
    specparam           tsetup_A4_CLK                  =1;
    specparam           tsetup_A5_CLK                  =1;
    specparam           tsetup_A6_CLK                  =1;
    specparam           tsetup_A7_CLK                  =1;
    specparam           tsetup_A8_CLK                  =1;
    specparam           tsetup_A9_CLK                  =1;
    specparam           tsetup_A10_CLK                 =1;
    specparam           tsetup_A11_CLK                 =1;
    specparam           tsetup_A12_CLK                 =1;
    specparam           tsetup_A13_CLK                 =1;
    specparam           tsetup_A14_CLK                 =1;
    specparam           tsetup_A15_CLK                 =1;
    specparam           tsetup_A16_CLK                 =1;
    specparam           tsetup_A17_CLK                 =1;
    specparam           tsetup_A18_CLK                 =1;
    specparam           tsetup_A19_CLK                 =1;
    specparam           tsetup_A20_CLK                 =1;
    specparam           tsetup_A21_CLK                 =1;
    specparam           tsetup_A22_CLK                 =1;
    specparam           tsetup_A23_CLK                 =1;
    specparam           tsetup_A24_CLK                 =1;

    specparam           tsetup_ADVNeg_CLK              =1;
    specparam           tsetup_CENeg_CLK               =1;
    specparam           tsetup_WENeg_CLK               =1;

    specparam           tsetup_CENeg_WENeg             =1;

    specparam           tsetup_DQ0_WENeg               =1;
    specparam           tsetup_DQ1_WENeg               =1;
    specparam           tsetup_DQ2_WENeg               =1;
    specparam           tsetup_DQ3_WENeg               =1;
    specparam           tsetup_DQ4_WENeg               =1;
    specparam           tsetup_DQ5_WENeg               =1;
    specparam           tsetup_DQ6_WENeg               =1;
    specparam           tsetup_DQ7_WENeg               =1;
    specparam           tsetup_DQ8_WENeg               =1;
    specparam           tsetup_DQ9_WENeg               =1;
    specparam           tsetup_DQ10_WENeg              =1;
    specparam           tsetup_DQ11_WENeg              =1;
    specparam           tsetup_DQ12_WENeg              =1;
    specparam           tsetup_DQ13_WENeg              =1;
    specparam           tsetup_DQ14_WENeg              =1;
    specparam           tsetup_DQ15_WENeg              =1;

    specparam           tsetup_A1_WENeg                =1;
    specparam           tsetup_A2_WENeg                =1;
    specparam           tsetup_A3_WENeg                =1;
    specparam           tsetup_A4_WENeg                =1;
    specparam           tsetup_A5_WENeg                =1;
    specparam           tsetup_A6_WENeg                =1;
    specparam           tsetup_A7_WENeg                =1;
    specparam           tsetup_A8_WENeg                =1;
    specparam           tsetup_A9_WENeg                =1;
    specparam           tsetup_A10_WENeg               =1;
    specparam           tsetup_A11_WENeg               =1;
    specparam           tsetup_A12_WENeg               =1;
    specparam           tsetup_A13_WENeg               =1;
    specparam           tsetup_A14_WENeg               =1;
    specparam           tsetup_A15_WENeg               =1;
    specparam           tsetup_A16_WENeg               =1;
    specparam           tsetup_A17_WENeg               =1;
    specparam           tsetup_A18_WENeg               =1;
    specparam           tsetup_A19_WENeg               =1;
    specparam           tsetup_A20_WENeg               =1;
    specparam           tsetup_A21_WENeg               =1;
    specparam           tsetup_A22_WENeg               =1;
    specparam           tsetup_A23_WENeg               =1;
    specparam           tsetup_A24_WENeg               =1;

    specparam           tsetup_WPNeg_WENeg             =1;
    specparam           tsetup_ADVNeg_WENeg            =1;
    specparam           tsetup_CLK_WENeg               =1;

    specparam           tsetup_WENeg_OENeg             =1;

    // thold values: hold times
    specparam           thold_A1_ADVNeg                =1;
    specparam           thold_A2_ADVNeg                =1;
    specparam           thold_A3_ADVNeg                =1;
    specparam           thold_A4_ADVNeg                =1;
    specparam           thold_A5_ADVNeg                =1;
    specparam           thold_A6_ADVNeg                =1;
    specparam           thold_A7_ADVNeg                =1;
    specparam           thold_A8_ADVNeg                =1;
    specparam           thold_A9_ADVNeg                =1;
    specparam           thold_A10_ADVNeg               =1;
    specparam           thold_A11_ADVNeg               =1;
    specparam           thold_A12_ADVNeg               =1;
    specparam           thold_A13_ADVNeg               =1;
    specparam           thold_A14_ADVNeg               =1;
    specparam           thold_A15_ADVNeg               =1;
    specparam           thold_A16_ADVNeg               =1;
    specparam           thold_A17_ADVNeg               =1;
    specparam           thold_A18_ADVNeg               =1;
    specparam           thold_A19_ADVNeg               =1;
    specparam           thold_A20_ADVNeg               =1;
    specparam           thold_A21_ADVNeg               =1;
    specparam           thold_A22_ADVNeg               =1;
    specparam           thold_A23_ADVNeg               =1;
    specparam           thold_A24_ADVNeg               =1;

    specparam           thold_A1_CLK                   =1;
    specparam           thold_A2_CLK                   =1;
    specparam           thold_A3_CLK                   =1;
    specparam           thold_A4_CLK                   =1;
    specparam           thold_A5_CLK                   =1;
    specparam           thold_A6_CLK                   =1;
    specparam           thold_A7_CLK                   =1;
    specparam           thold_A8_CLK                   =1;
    specparam           thold_A9_CLK                   =1;
    specparam           thold_A10_CLK                  =1;
    specparam           thold_A11_CLK                  =1;
    specparam           thold_A12_CLK                  =1;
    specparam           thold_A13_CLK                  =1;
    specparam           thold_A14_CLK                  =1;
    specparam           thold_A15_CLK                  =1;
    specparam           thold_A16_CLK                  =1;
    specparam           thold_A17_CLK                  =1;
    specparam           thold_A18_CLK                  =1;
    specparam           thold_A19_CLK                  =1;
    specparam           thold_A20_CLK                  =1;
    specparam           thold_A21_CLK                  =1;
    specparam           thold_A22_CLK                  =1;
    specparam           thold_A23_CLK                  =1;
    specparam           thold_A24_CLK                  =1;

    specparam           thold_CENeg_WENeg              =1;

    specparam           thold_DQ0_WENeg                =1;
    specparam           thold_DQ1_WENeg                =1;
    specparam           thold_DQ2_WENeg                =1;
    specparam           thold_DQ3_WENeg                =1;
    specparam           thold_DQ4_WENeg                =1;
    specparam           thold_DQ5_WENeg                =1;
    specparam           thold_DQ6_WENeg                =1;
    specparam           thold_DQ7_WENeg                =1;
    specparam           thold_DQ8_WENeg                =1;
    specparam           thold_DQ9_WENeg                =1;
    specparam           thold_DQ10_WENeg               =1;
    specparam           thold_DQ11_WENeg               =1;
    specparam           thold_DQ12_WENeg               =1;
    specparam           thold_DQ13_WENeg               =1;
    specparam           thold_DQ14_WENeg               =1;
    specparam           thold_DQ15_WENeg               =1;

    specparam           thold_A1_WENeg                 =1;
    specparam           thold_A2_WENeg                 =1;
    specparam           thold_A3_WENeg                 =1;
    specparam           thold_A4_WENeg                 =1;
    specparam           thold_A5_WENeg                 =1;
    specparam           thold_A6_WENeg                 =1;
    specparam           thold_A7_WENeg                 =1;
    specparam           thold_A8_WENeg                 =1;
    specparam           thold_A9_WENeg                 =1;
    specparam           thold_A10_WENeg                =1;
    specparam           thold_A11_WENeg                =1;
    specparam           thold_A12_WENeg                =1;
    specparam           thold_A13_WENeg                =1;
    specparam           thold_A14_WENeg                =1;
    specparam           thold_A15_WENeg                =1;
    specparam           thold_A16_WENeg                =1;
    specparam           thold_A17_WENeg                =1;
    specparam           thold_A18_WENeg                =1;
    specparam           thold_A19_WENeg                =1;
    specparam           thold_A20_WENeg                =1;
    specparam           thold_A21_WENeg                =1;
    specparam           thold_A22_WENeg                =1;
    specparam           thold_A23_WENeg                =1;
    specparam           thold_A24_WENeg                =1;

    //tpw values
    specparam       tpw_CENeg_posedge    = 1;

    specparam       tpw_ADVNeg_posedge   = 1;
    specparam       tpw_ADVNeg_negedge   = 1;

    specparam       tpw_WENeg_negedge    = 1;
    specparam       tpw_WENeg_posedge    = 1;

    specparam       tpw_RSTNeg_negedge   = 1;

    specparam       tpw_CLK_posedge      = 1;
    specparam       tpw_CLK_negedge      = 1;
    specparam       tperiod_CLK          = 1;

    // tdevice values: values for internal delays
    `ifdef SPEEDSIM
        // Program BUffProgram
        specparam   tdevice_BuffProgram             = 88000;
        // Program BUffProgram
        specparam   tdevice_BuffProgram9V           = 68000;
        // Program BEFP
        specparam   tdevice_BEFP                    = 32000;
        // Program EraseParameter
        specparam   tdevice_EraseParameter_td       = 2500;
        // Program EraseMain
        specparam   tdevice_EraseMain_td            = 4000;
    `else
        // Program BUffProgram
        specparam   tdevice_BuffProgram             = 880000;
        // Program BUffProgram
        specparam   tdevice_BuffProgram9V           = 680000;
        // Program BEFP
        specparam   tdevice_BEFP                    = 320000;
        // Program EraseParameter
        specparam   tdevice_EraseParameter_td       = 2500000;
        // Program EraseMain
        specparam   tdevice_EraseMain_td            = 4000000;
    `endif // SPEEDSIM

    // Program Word
    specparam   tdevice_WordProgram             = 200000;
    // Program Word
    specparam   tdevice_WordProgram9V           = 190000;
    // Program BEFPsetup
    specparam   tdevice_BEFPsetup               = 5000;
    // Program ProgramSuspend
    specparam   tdevice_ProgramSuspend          = 25000;
    // Program ProgramSuspend
    specparam   tdevice_EraseSuspend            = 25000;
    // Reset during Program or Erase
    specparam   tdevice_RstDuringErsPrg         = 25000;

///////////////////////////////////////////////////////////////////////////////
// Input Port  Delays  don't require Verilog description
///////////////////////////////////////////////////////////////////////////////
// Path delays                                                               //
///////////////////////////////////////////////////////////////////////////////
    if (InitialPageAccess) (A1 *> DQ0)  = tpd_A1_DQ0;
    if (InitialPageAccess) (A1 *> DQ1)  = tpd_A1_DQ1;
    if (InitialPageAccess) (A1 *> DQ2)  = tpd_A1_DQ2;
    if (InitialPageAccess) (A1 *> DQ3)  = tpd_A1_DQ3;
    if (InitialPageAccess) (A1 *> DQ4)  = tpd_A1_DQ4;
    if (InitialPageAccess) (A1 *> DQ5)  = tpd_A1_DQ5;
    if (InitialPageAccess) (A1 *> DQ6)  = tpd_A1_DQ6;
    if (InitialPageAccess) (A1 *> DQ7)  = tpd_A1_DQ7;
    if (InitialPageAccess) (A1 *> DQ8)  = tpd_A1_DQ8;
    if (InitialPageAccess) (A1 *> DQ9)  = tpd_A1_DQ9;
    if (InitialPageAccess) (A1 *> DQ10) = tpd_A1_DQ10;
    if (InitialPageAccess) (A1 *> DQ11) = tpd_A1_DQ11;
    if (InitialPageAccess) (A1 *> DQ12) = tpd_A1_DQ12;
    if (InitialPageAccess) (A1 *> DQ13) = tpd_A1_DQ13;
    if (InitialPageAccess) (A1 *> DQ14) = tpd_A1_DQ14;
    if (InitialPageAccess) (A1 *> DQ15) = tpd_A1_DQ15;
    if (InitialPageAccess) (A2 *> DQ0)  = tpd_A2_DQ0;
    if (InitialPageAccess) (A2 *> DQ1)  = tpd_A2_DQ1;
    if (InitialPageAccess) (A2 *> DQ2)  = tpd_A2_DQ2;
    if (InitialPageAccess) (A2 *> DQ3)  = tpd_A2_DQ3;
    if (InitialPageAccess) (A2 *> DQ4)  = tpd_A2_DQ4;
    if (InitialPageAccess) (A2 *> DQ5)  = tpd_A2_DQ5;
    if (InitialPageAccess) (A2 *> DQ6)  = tpd_A2_DQ6;
    if (InitialPageAccess) (A2 *> DQ7)  = tpd_A2_DQ7;
    if (InitialPageAccess) (A2 *> DQ8)  = tpd_A2_DQ8;
    if (InitialPageAccess) (A2 *> DQ9)  = tpd_A2_DQ9;
    if (InitialPageAccess) (A2 *> DQ10) = tpd_A2_DQ10;
    if (InitialPageAccess) (A2 *> DQ11) = tpd_A2_DQ11;
    if (InitialPageAccess) (A2 *> DQ12) = tpd_A2_DQ12;
    if (InitialPageAccess) (A2 *> DQ13) = tpd_A2_DQ13;
    if (InitialPageAccess) (A2 *> DQ14) = tpd_A2_DQ14;
    if (InitialPageAccess) (A2 *> DQ15) = tpd_A2_DQ15;
    if (InitialPageAccess) (A3 *> DQ0)  = tpd_A3_DQ0;
    if (InitialPageAccess) (A3 *> DQ1)  = tpd_A3_DQ1;
    if (InitialPageAccess) (A3 *> DQ2)  = tpd_A3_DQ2;
    if (InitialPageAccess) (A3 *> DQ3)  = tpd_A3_DQ3;
    if (InitialPageAccess) (A3 *> DQ4)  = tpd_A3_DQ4;
    if (InitialPageAccess) (A3 *> DQ5)  = tpd_A3_DQ5;
    if (InitialPageAccess) (A3 *> DQ6)  = tpd_A3_DQ6;
    if (InitialPageAccess) (A3 *> DQ7)  = tpd_A3_DQ7;
    if (InitialPageAccess) (A3 *> DQ8)  = tpd_A3_DQ8;
    if (InitialPageAccess) (A3 *> DQ9)  = tpd_A3_DQ9;
    if (InitialPageAccess) (A3 *> DQ10) = tpd_A3_DQ10;
    if (InitialPageAccess) (A3 *> DQ11) = tpd_A3_DQ11;
    if (InitialPageAccess) (A3 *> DQ12) = tpd_A3_DQ12;
    if (InitialPageAccess) (A3 *> DQ13) = tpd_A3_DQ13;
    if (InitialPageAccess) (A3 *> DQ14) = tpd_A3_DQ14;
    if (InitialPageAccess) (A3 *> DQ15) = tpd_A3_DQ15;
    if (InitialPageAccess) (A4 *> DQ0)  = tpd_A4_DQ0;
    if (InitialPageAccess) (A4 *> DQ1)  = tpd_A4_DQ1;
    if (InitialPageAccess) (A4 *> DQ2)  = tpd_A4_DQ2;
    if (InitialPageAccess) (A4 *> DQ3)  = tpd_A4_DQ3;
    if (InitialPageAccess) (A4 *> DQ4)  = tpd_A4_DQ4;
    if (InitialPageAccess) (A4 *> DQ5)  = tpd_A4_DQ5;
    if (InitialPageAccess) (A4 *> DQ6)  = tpd_A4_DQ6;
    if (InitialPageAccess) (A4 *> DQ7)  = tpd_A4_DQ7;
    if (InitialPageAccess) (A4 *> DQ8)  = tpd_A4_DQ8;
    if (InitialPageAccess) (A4 *> DQ9)  = tpd_A4_DQ9;
    if (InitialPageAccess) (A4 *> DQ10) = tpd_A4_DQ10;
    if (InitialPageAccess) (A4 *> DQ11) = tpd_A4_DQ11;
    if (InitialPageAccess) (A4 *> DQ12) = tpd_A4_DQ12;
    if (InitialPageAccess) (A4 *> DQ13) = tpd_A4_DQ13;
    if (InitialPageAccess) (A4 *> DQ14) = tpd_A4_DQ14;
    if (InitialPageAccess) (A4 *> DQ15) = tpd_A4_DQ15;
    if (InitialPageAccess) (A5 *> DQ0)  = tpd_A5_DQ0;
    if (InitialPageAccess) (A5 *> DQ1)  = tpd_A5_DQ1;
    if (InitialPageAccess) (A5 *> DQ2)  = tpd_A5_DQ2;
    if (InitialPageAccess) (A5 *> DQ3)  = tpd_A5_DQ3;
    if (InitialPageAccess) (A5 *> DQ4)  = tpd_A5_DQ4;
    if (InitialPageAccess) (A5 *> DQ5)  = tpd_A5_DQ5;
    if (InitialPageAccess) (A5 *> DQ6)  = tpd_A5_DQ6;
    if (InitialPageAccess) (A5 *> DQ7)  = tpd_A5_DQ7;
    if (InitialPageAccess) (A5 *> DQ8)  = tpd_A5_DQ8;
    if (InitialPageAccess) (A5 *> DQ9)  = tpd_A5_DQ9;
    if (InitialPageAccess) (A5 *> DQ10) = tpd_A5_DQ10;
    if (InitialPageAccess) (A5 *> DQ11) = tpd_A5_DQ11;
    if (InitialPageAccess) (A5 *> DQ12) = tpd_A5_DQ12;
    if (InitialPageAccess) (A5 *> DQ13) = tpd_A5_DQ13;
    if (InitialPageAccess) (A5 *> DQ14) = tpd_A5_DQ14;
    if (InitialPageAccess) (A5 *> DQ15) = tpd_A5_DQ15;
    if (InitialPageAccess) (A6 *> DQ0)  = tpd_A6_DQ0;
    if (InitialPageAccess) (A6 *> DQ1)  = tpd_A6_DQ1;
    if (InitialPageAccess) (A6 *> DQ2)  = tpd_A6_DQ2;
    if (InitialPageAccess) (A6 *> DQ3)  = tpd_A6_DQ3;
    if (InitialPageAccess) (A6 *> DQ4)  = tpd_A6_DQ4;
    if (InitialPageAccess) (A6 *> DQ5)  = tpd_A6_DQ5;
    if (InitialPageAccess) (A6 *> DQ6)  = tpd_A6_DQ6;
    if (InitialPageAccess) (A6 *> DQ7)  = tpd_A6_DQ7;
    if (InitialPageAccess) (A6 *> DQ8)  = tpd_A6_DQ8;
    if (InitialPageAccess) (A6 *> DQ9)  = tpd_A6_DQ9;
    if (InitialPageAccess) (A6 *> DQ10) = tpd_A6_DQ10;
    if (InitialPageAccess) (A6 *> DQ11) = tpd_A6_DQ11;
    if (InitialPageAccess) (A6 *> DQ12) = tpd_A6_DQ12;
    if (InitialPageAccess) (A6 *> DQ13) = tpd_A6_DQ13;
    if (InitialPageAccess) (A6 *> DQ14) = tpd_A6_DQ14;
    if (InitialPageAccess) (A6 *> DQ15) = tpd_A6_DQ15;
    if (InitialPageAccess) (A7 *> DQ0)  = tpd_A7_DQ0;
    if (InitialPageAccess) (A7 *> DQ1)  = tpd_A7_DQ1;
    if (InitialPageAccess) (A7 *> DQ2)  = tpd_A7_DQ2;
    if (InitialPageAccess) (A7 *> DQ3)  = tpd_A7_DQ3;
    if (InitialPageAccess) (A7 *> DQ4)  = tpd_A7_DQ4;
    if (InitialPageAccess) (A7 *> DQ5)  = tpd_A7_DQ5;
    if (InitialPageAccess) (A7 *> DQ6)  = tpd_A7_DQ6;
    if (InitialPageAccess) (A7 *> DQ7)  = tpd_A7_DQ7;
    if (InitialPageAccess) (A7 *> DQ8)  = tpd_A7_DQ8;
    if (InitialPageAccess) (A7 *> DQ9)  = tpd_A7_DQ9;
    if (InitialPageAccess) (A7 *> DQ10) = tpd_A7_DQ10;
    if (InitialPageAccess) (A7 *> DQ11) = tpd_A7_DQ11;
    if (InitialPageAccess) (A7 *> DQ12) = tpd_A7_DQ12;
    if (InitialPageAccess) (A7 *> DQ13) = tpd_A7_DQ13;
    if (InitialPageAccess) (A7 *> DQ14) = tpd_A7_DQ14;
    if (InitialPageAccess) (A7 *> DQ15) = tpd_A7_DQ15;
    if (InitialPageAccess) (A8 *> DQ0)  = tpd_A8_DQ0;
    if (InitialPageAccess) (A8 *> DQ1)  = tpd_A8_DQ1;
    if (InitialPageAccess) (A8 *> DQ2)  = tpd_A8_DQ2;
    if (InitialPageAccess) (A8 *> DQ3)  = tpd_A8_DQ3;
    if (InitialPageAccess) (A8 *> DQ4)  = tpd_A8_DQ4;
    if (InitialPageAccess) (A8 *> DQ5)  = tpd_A8_DQ5;
    if (InitialPageAccess) (A8 *> DQ6)  = tpd_A8_DQ6;
    if (InitialPageAccess) (A8 *> DQ7)  = tpd_A8_DQ7;
    if (InitialPageAccess) (A8 *> DQ8)  = tpd_A8_DQ8;
    if (InitialPageAccess) (A8 *> DQ9)  = tpd_A8_DQ9;
    if (InitialPageAccess) (A8 *> DQ10) = tpd_A8_DQ10;
    if (InitialPageAccess) (A8 *> DQ11) = tpd_A8_DQ11;
    if (InitialPageAccess) (A8 *> DQ12) = tpd_A8_DQ12;
    if (InitialPageAccess) (A8 *> DQ13) = tpd_A8_DQ13;
    if (InitialPageAccess) (A8 *> DQ14) = tpd_A8_DQ14;
    if (InitialPageAccess) (A8 *> DQ15) = tpd_A8_DQ15;
    if (InitialPageAccess) (A9 *> DQ0)  = tpd_A9_DQ0;
    if (InitialPageAccess) (A9 *> DQ1)  = tpd_A9_DQ1;
    if (InitialPageAccess) (A9 *> DQ2)  = tpd_A9_DQ2;
    if (InitialPageAccess) (A9 *> DQ3)  = tpd_A9_DQ3;
    if (InitialPageAccess) (A9 *> DQ4)  = tpd_A9_DQ4;
    if (InitialPageAccess) (A9 *> DQ5)  = tpd_A9_DQ5;
    if (InitialPageAccess) (A9 *> DQ6)  = tpd_A9_DQ6;
    if (InitialPageAccess) (A9 *> DQ7)  = tpd_A9_DQ7;
    if (InitialPageAccess) (A9 *> DQ8)  = tpd_A9_DQ8;
    if (InitialPageAccess) (A9 *> DQ9)  = tpd_A9_DQ9;
    if (InitialPageAccess) (A9 *> DQ10) = tpd_A9_DQ10;
    if (InitialPageAccess) (A9 *> DQ11) = tpd_A9_DQ11;
    if (InitialPageAccess) (A9 *> DQ12) = tpd_A9_DQ12;
    if (InitialPageAccess) (A9 *> DQ13) = tpd_A9_DQ13;
    if (InitialPageAccess) (A9 *> DQ14) = tpd_A9_DQ14;
    if (InitialPageAccess) (A9 *> DQ15) = tpd_A9_DQ15;
    if (InitialPageAccess) (A10 *> DQ0) = tpd_A10_DQ0;
    if (InitialPageAccess) (A10 *> DQ1) = tpd_A10_DQ1;
    if (InitialPageAccess) (A10 *> DQ2) = tpd_A10_DQ2;
    if (InitialPageAccess) (A10 *> DQ3) = tpd_A10_DQ3;
    if (InitialPageAccess) (A10 *> DQ4) = tpd_A10_DQ4;
    if (InitialPageAccess) (A10 *> DQ5) = tpd_A10_DQ5;
    if (InitialPageAccess) (A10 *> DQ6) = tpd_A10_DQ6;
    if (InitialPageAccess) (A10 *> DQ7) = tpd_A10_DQ7;
    if (InitialPageAccess) (A10 *> DQ8) = tpd_A10_DQ8;
    if (InitialPageAccess) (A10 *> DQ9) = tpd_A10_DQ9;
    if (InitialPageAccess) (A10 *> DQ10) = tpd_A10_DQ10;
    if (InitialPageAccess) (A10 *> DQ11) = tpd_A10_DQ11;
    if (InitialPageAccess) (A10 *> DQ12) = tpd_A10_DQ12;
    if (InitialPageAccess) (A10 *> DQ13) = tpd_A10_DQ13;
    if (InitialPageAccess) (A10 *> DQ14) = tpd_A10_DQ14;
    if (InitialPageAccess) (A10 *> DQ15) = tpd_A10_DQ15;
    if (InitialPageAccess) (A11 *> DQ0)  = tpd_A11_DQ0;
    if (InitialPageAccess) (A11 *> DQ1)  = tpd_A11_DQ1;
    if (InitialPageAccess) (A11 *> DQ2)  = tpd_A11_DQ2;
    if (InitialPageAccess) (A11 *> DQ3)  = tpd_A11_DQ3;
    if (InitialPageAccess) (A11 *> DQ4)  = tpd_A11_DQ4;
    if (InitialPageAccess) (A11 *> DQ5)  = tpd_A11_DQ5;
    if (InitialPageAccess) (A11 *> DQ6)  = tpd_A11_DQ6;
    if (InitialPageAccess) (A11 *> DQ7)  = tpd_A11_DQ7;
    if (InitialPageAccess) (A11 *> DQ8)  = tpd_A11_DQ8;
    if (InitialPageAccess) (A11 *> DQ9)  = tpd_A11_DQ9;
    if (InitialPageAccess) (A11 *> DQ10) = tpd_A11_DQ10;
    if (InitialPageAccess) (A11 *> DQ11) = tpd_A11_DQ11;
    if (InitialPageAccess) (A11 *> DQ12) = tpd_A11_DQ12;
    if (InitialPageAccess) (A11 *> DQ13) = tpd_A11_DQ13;
    if (InitialPageAccess) (A11 *> DQ14) = tpd_A11_DQ14;
    if (InitialPageAccess) (A11 *> DQ15) = tpd_A11_DQ15;
    if (InitialPageAccess) (A12 *> DQ0)  = tpd_A12_DQ0;
    if (InitialPageAccess) (A12 *> DQ1)  = tpd_A12_DQ1;
    if (InitialPageAccess) (A12 *> DQ2)  = tpd_A12_DQ2;
    if (InitialPageAccess) (A12 *> DQ3)  = tpd_A12_DQ3;
    if (InitialPageAccess) (A12 *> DQ4)  = tpd_A12_DQ4;
    if (InitialPageAccess) (A12 *> DQ5)  = tpd_A12_DQ5;
    if (InitialPageAccess) (A12 *> DQ6)  = tpd_A12_DQ6;
    if (InitialPageAccess) (A12 *> DQ7)  = tpd_A12_DQ7;
    if (InitialPageAccess) (A12 *> DQ8)  = tpd_A12_DQ8;
    if (InitialPageAccess) (A12 *> DQ9)  = tpd_A12_DQ9;
    if (InitialPageAccess) (A12 *> DQ10) = tpd_A12_DQ10;
    if (InitialPageAccess) (A12 *> DQ11) = tpd_A12_DQ11;
    if (InitialPageAccess) (A12 *> DQ12) = tpd_A12_DQ12;
    if (InitialPageAccess) (A12 *> DQ13) = tpd_A12_DQ13;
    if (InitialPageAccess) (A12 *> DQ14) = tpd_A12_DQ14;
    if (InitialPageAccess) (A12 *> DQ15) = tpd_A12_DQ15;
    if (InitialPageAccess) (A13 *> DQ0)  = tpd_A13_DQ0;
    if (InitialPageAccess) (A13 *> DQ1)  = tpd_A13_DQ1;
    if (InitialPageAccess) (A13 *> DQ2)  = tpd_A13_DQ2;
    if (InitialPageAccess) (A13 *> DQ3)  = tpd_A13_DQ3;
    if (InitialPageAccess) (A13 *> DQ4)  = tpd_A13_DQ4;
    if (InitialPageAccess) (A13 *> DQ5)  = tpd_A13_DQ5;
    if (InitialPageAccess) (A13 *> DQ6)  = tpd_A13_DQ6;
    if (InitialPageAccess) (A13 *> DQ7)  = tpd_A13_DQ7;
    if (InitialPageAccess) (A13 *> DQ8)  = tpd_A13_DQ8;
    if (InitialPageAccess) (A13 *> DQ9)  = tpd_A13_DQ9;
    if (InitialPageAccess) (A13 *> DQ10) = tpd_A13_DQ10;
    if (InitialPageAccess) (A13 *> DQ11) = tpd_A13_DQ11;
    if (InitialPageAccess) (A13 *> DQ12) = tpd_A13_DQ12;
    if (InitialPageAccess) (A13 *> DQ13) = tpd_A13_DQ13;
    if (InitialPageAccess) (A13 *> DQ14) = tpd_A13_DQ14;
    if (InitialPageAccess) (A13 *> DQ15) = tpd_A13_DQ15;
    if (InitialPageAccess) (A14 *> DQ0)  = tpd_A14_DQ0;
    if (InitialPageAccess) (A14 *> DQ1)  = tpd_A14_DQ1;
    if (InitialPageAccess) (A14 *> DQ2)  = tpd_A14_DQ2;
    if (InitialPageAccess) (A14 *> DQ3)  = tpd_A14_DQ3;
    if (InitialPageAccess) (A14 *> DQ4)  = tpd_A14_DQ4;
    if (InitialPageAccess) (A14 *> DQ5)  = tpd_A14_DQ5;
    if (InitialPageAccess) (A14 *> DQ6)  = tpd_A14_DQ6;
    if (InitialPageAccess) (A14 *> DQ7)  = tpd_A14_DQ7;
    if (InitialPageAccess) (A14 *> DQ8)  = tpd_A14_DQ8;
    if (InitialPageAccess) (A14 *> DQ9)  = tpd_A14_DQ9;
    if (InitialPageAccess) (A14 *> DQ10) = tpd_A14_DQ10;
    if (InitialPageAccess) (A14 *> DQ11) = tpd_A14_DQ11;
    if (InitialPageAccess) (A14 *> DQ12) = tpd_A14_DQ12;
    if (InitialPageAccess) (A14 *> DQ13) = tpd_A14_DQ13;
    if (InitialPageAccess) (A14 *> DQ14) = tpd_A14_DQ14;
    if (InitialPageAccess) (A14 *> DQ15) = tpd_A14_DQ15;
    if (InitialPageAccess) (A15 *> DQ0)  = tpd_A15_DQ0;
    if (InitialPageAccess) (A15 *> DQ1)  = tpd_A15_DQ1;
    if (InitialPageAccess) (A15 *> DQ2)  = tpd_A15_DQ2;
    if (InitialPageAccess) (A15 *> DQ3)  = tpd_A15_DQ3;
    if (InitialPageAccess) (A15 *> DQ4)  = tpd_A15_DQ4;
    if (InitialPageAccess) (A15 *> DQ5)  = tpd_A15_DQ5;
    if (InitialPageAccess) (A15 *> DQ6)  = tpd_A15_DQ6;
    if (InitialPageAccess) (A15 *> DQ7)  = tpd_A15_DQ7;
    if (InitialPageAccess) (A15 *> DQ8)  = tpd_A15_DQ8;
    if (InitialPageAccess) (A15 *> DQ9)  = tpd_A15_DQ9;
    if (InitialPageAccess) (A15 *> DQ10) = tpd_A15_DQ10;
    if (InitialPageAccess) (A15 *> DQ11) = tpd_A15_DQ11;
    if (InitialPageAccess) (A15 *> DQ12) = tpd_A15_DQ12;
    if (InitialPageAccess) (A15 *> DQ13) = tpd_A15_DQ13;
    if (InitialPageAccess) (A15 *> DQ14) = tpd_A15_DQ14;
    if (InitialPageAccess) (A15 *> DQ15) = tpd_A15_DQ15;
    if (InitialPageAccess) (A16 *> DQ0)  = tpd_A16_DQ0;
    if (InitialPageAccess) (A16 *> DQ1)  = tpd_A16_DQ1;
    if (InitialPageAccess) (A16 *> DQ2)  = tpd_A16_DQ2;
    if (InitialPageAccess) (A16 *> DQ3)  = tpd_A16_DQ3;
    if (InitialPageAccess) (A16 *> DQ4)  = tpd_A16_DQ4;
    if (InitialPageAccess) (A16 *> DQ5)  = tpd_A16_DQ5;
    if (InitialPageAccess) (A16 *> DQ6)  = tpd_A16_DQ6;
    if (InitialPageAccess) (A16 *> DQ7)  = tpd_A16_DQ7;
    if (InitialPageAccess) (A16 *> DQ8)  = tpd_A16_DQ8;
    if (InitialPageAccess) (A16 *> DQ9)  = tpd_A16_DQ9;
    if (InitialPageAccess) (A16 *> DQ10) = tpd_A16_DQ10;
    if (InitialPageAccess) (A16 *> DQ11) = tpd_A16_DQ11;
    if (InitialPageAccess) (A16 *> DQ12) = tpd_A16_DQ12;
    if (InitialPageAccess) (A16 *> DQ13) = tpd_A16_DQ13;
    if (InitialPageAccess) (A16 *> DQ14) = tpd_A16_DQ14;
    if (InitialPageAccess) (A16 *> DQ15) = tpd_A16_DQ15;
    if (InitialPageAccess) (A17 *> DQ0)  = tpd_A17_DQ0;
    if (InitialPageAccess) (A17 *> DQ1)  = tpd_A17_DQ1;
    if (InitialPageAccess) (A17 *> DQ2)  = tpd_A17_DQ2;
    if (InitialPageAccess) (A17 *> DQ3)  = tpd_A17_DQ3;
    if (InitialPageAccess) (A17 *> DQ4)  = tpd_A17_DQ4;
    if (InitialPageAccess) (A17 *> DQ5)  = tpd_A17_DQ5;
    if (InitialPageAccess) (A17 *> DQ6)  = tpd_A17_DQ6;
    if (InitialPageAccess) (A17 *> DQ7)  = tpd_A17_DQ7;
    if (InitialPageAccess) (A17 *> DQ8)  = tpd_A17_DQ8;
    if (InitialPageAccess) (A17 *> DQ9)  = tpd_A17_DQ9;
    if (InitialPageAccess) (A17 *> DQ10) = tpd_A17_DQ10;
    if (InitialPageAccess) (A17 *> DQ11) = tpd_A17_DQ11;
    if (InitialPageAccess) (A17 *> DQ12) = tpd_A17_DQ12;
    if (InitialPageAccess) (A17 *> DQ13) = tpd_A17_DQ13;
    if (InitialPageAccess) (A17 *> DQ14) = tpd_A17_DQ14;
    if (InitialPageAccess) (A17 *> DQ15) = tpd_A17_DQ15;
    if (InitialPageAccess) (A18 *> DQ0)  = tpd_A18_DQ0;
    if (InitialPageAccess) (A18 *> DQ1)  = tpd_A18_DQ1;
    if (InitialPageAccess) (A18 *> DQ2)  = tpd_A18_DQ2;
    if (InitialPageAccess) (A18 *> DQ3)  = tpd_A18_DQ3;
    if (InitialPageAccess) (A18 *> DQ4)  = tpd_A18_DQ4;
    if (InitialPageAccess) (A18 *> DQ5)  = tpd_A18_DQ5;
    if (InitialPageAccess) (A18 *> DQ6)  = tpd_A18_DQ6;
    if (InitialPageAccess) (A18 *> DQ7)  = tpd_A18_DQ7;
    if (InitialPageAccess) (A18 *> DQ8)  = tpd_A18_DQ8;
    if (InitialPageAccess) (A18 *> DQ9)  = tpd_A18_DQ9;
    if (InitialPageAccess) (A18 *> DQ10) = tpd_A18_DQ10;
    if (InitialPageAccess) (A18 *> DQ11) = tpd_A18_DQ11;
    if (InitialPageAccess) (A18 *> DQ12) = tpd_A18_DQ12;
    if (InitialPageAccess) (A18 *> DQ13) = tpd_A18_DQ13;
    if (InitialPageAccess) (A18 *> DQ14) = tpd_A18_DQ14;
    if (InitialPageAccess) (A18 *> DQ15) = tpd_A18_DQ15;
    if (InitialPageAccess) (A19 *> DQ0)  = tpd_A19_DQ0;
    if (InitialPageAccess) (A19 *> DQ1)  = tpd_A19_DQ1;
    if (InitialPageAccess) (A19 *> DQ2)  = tpd_A19_DQ2;
    if (InitialPageAccess) (A19 *> DQ3)  = tpd_A19_DQ3;
    if (InitialPageAccess) (A19 *> DQ4)  = tpd_A19_DQ4;
    if (InitialPageAccess) (A19 *> DQ5)  = tpd_A19_DQ5;
    if (InitialPageAccess) (A19 *> DQ6)  = tpd_A19_DQ6;
    if (InitialPageAccess) (A19 *> DQ7)  = tpd_A19_DQ7;
    if (InitialPageAccess) (A19 *> DQ8)  = tpd_A19_DQ8;
    if (InitialPageAccess) (A19 *> DQ9)  = tpd_A19_DQ9;
    if (InitialPageAccess) (A19 *> DQ10) = tpd_A19_DQ10;
    if (InitialPageAccess) (A19 *> DQ11) = tpd_A19_DQ11;
    if (InitialPageAccess) (A19 *> DQ12) = tpd_A19_DQ12;
    if (InitialPageAccess) (A19 *> DQ13) = tpd_A19_DQ13;
    if (InitialPageAccess) (A19 *> DQ14) = tpd_A19_DQ14;
    if (InitialPageAccess) (A19 *> DQ15) = tpd_A19_DQ15;
    if (InitialPageAccess) (A20 *> DQ0)  = tpd_A20_DQ0;
    if (InitialPageAccess) (A20 *> DQ1)  = tpd_A20_DQ1;
    if (InitialPageAccess) (A20 *> DQ2)  = tpd_A20_DQ2;
    if (InitialPageAccess) (A20 *> DQ3)  = tpd_A20_DQ3;
    if (InitialPageAccess) (A20 *> DQ4)  = tpd_A20_DQ4;
    if (InitialPageAccess) (A20 *> DQ5)  = tpd_A20_DQ5;
    if (InitialPageAccess) (A20 *> DQ6)  = tpd_A20_DQ6;
    if (InitialPageAccess) (A20 *> DQ7)  = tpd_A20_DQ7;
    if (InitialPageAccess) (A20 *> DQ8)  = tpd_A20_DQ8;
    if (InitialPageAccess) (A20 *> DQ9)  = tpd_A20_DQ9;
    if (InitialPageAccess) (A20 *> DQ10) = tpd_A20_DQ10;
    if (InitialPageAccess) (A20 *> DQ11) = tpd_A20_DQ11;
    if (InitialPageAccess) (A20 *> DQ12) = tpd_A20_DQ12;
    if (InitialPageAccess) (A20 *> DQ13) = tpd_A20_DQ13;
    if (InitialPageAccess) (A20 *> DQ14) = tpd_A20_DQ14;
    if (InitialPageAccess) (A20 *> DQ15) = tpd_A20_DQ15;
    if (InitialPageAccess) (A21 *> DQ0)  = tpd_A21_DQ0;
    if (InitialPageAccess) (A21 *> DQ1)  = tpd_A21_DQ1;
    if (InitialPageAccess) (A21 *> DQ2)  = tpd_A21_DQ2;
    if (InitialPageAccess) (A21 *> DQ3)  = tpd_A21_DQ3;
    if (InitialPageAccess) (A21 *> DQ4)  = tpd_A21_DQ4;
    if (InitialPageAccess) (A21 *> DQ5)  = tpd_A21_DQ5;
    if (InitialPageAccess) (A21 *> DQ6)  = tpd_A21_DQ6;
    if (InitialPageAccess) (A21 *> DQ7)  = tpd_A21_DQ7;
    if (InitialPageAccess) (A21 *> DQ8)  = tpd_A21_DQ8;
    if (InitialPageAccess) (A21 *> DQ9)  = tpd_A21_DQ9;
    if (InitialPageAccess) (A21 *> DQ10) = tpd_A21_DQ10;
    if (InitialPageAccess) (A21 *> DQ11) = tpd_A21_DQ11;
    if (InitialPageAccess) (A21 *> DQ12) = tpd_A21_DQ12;
    if (InitialPageAccess) (A21 *> DQ13) = tpd_A21_DQ13;
    if (InitialPageAccess) (A21 *> DQ14) = tpd_A21_DQ14;
    if (InitialPageAccess) (A21 *> DQ15) = tpd_A21_DQ15;
    if (InitialPageAccess) (A22 *> DQ0)  = tpd_A22_DQ0;
    if (InitialPageAccess) (A22 *> DQ1)  = tpd_A22_DQ1;
    if (InitialPageAccess) (A22 *> DQ2)  = tpd_A22_DQ2;
    if (InitialPageAccess) (A22 *> DQ3)  = tpd_A22_DQ3;
    if (InitialPageAccess) (A22 *> DQ4)  = tpd_A22_DQ4;
    if (InitialPageAccess) (A22 *> DQ5)  = tpd_A22_DQ5;
    if (InitialPageAccess) (A22 *> DQ6)  = tpd_A22_DQ6;
    if (InitialPageAccess) (A22 *> DQ7)  = tpd_A22_DQ7;
    if (InitialPageAccess) (A22 *> DQ8)  = tpd_A22_DQ8;
    if (InitialPageAccess) (A22 *> DQ9)  = tpd_A22_DQ9;
    if (InitialPageAccess) (A22 *> DQ10) = tpd_A22_DQ10;
    if (InitialPageAccess) (A22 *> DQ11) = tpd_A22_DQ11;
    if (InitialPageAccess) (A22 *> DQ12) = tpd_A22_DQ12;
    if (InitialPageAccess) (A22 *> DQ13) = tpd_A22_DQ13;
    if (InitialPageAccess) (A22 *> DQ14) = tpd_A22_DQ14;
    if (InitialPageAccess) (A22 *> DQ15) = tpd_A22_DQ15;
    if (InitialPageAccess) (A23 *> DQ0)  = tpd_A23_DQ0;
    if (InitialPageAccess) (A23 *> DQ1)  = tpd_A23_DQ1;
    if (InitialPageAccess) (A23 *> DQ2)  = tpd_A23_DQ2;
    if (InitialPageAccess) (A23 *> DQ3)  = tpd_A23_DQ3;
    if (InitialPageAccess) (A23 *> DQ4)  = tpd_A23_DQ4;
    if (InitialPageAccess) (A23 *> DQ5)  = tpd_A23_DQ5;
    if (InitialPageAccess) (A23 *> DQ6)  = tpd_A23_DQ6;
    if (InitialPageAccess) (A23 *> DQ7)  = tpd_A23_DQ7;
    if (InitialPageAccess) (A23 *> DQ8)  = tpd_A23_DQ8;
    if (InitialPageAccess) (A23 *> DQ9)  = tpd_A23_DQ9;
    if (InitialPageAccess) (A23 *> DQ10) = tpd_A23_DQ10;
    if (InitialPageAccess) (A23 *> DQ11) = tpd_A23_DQ11;
    if (InitialPageAccess) (A23 *> DQ12) = tpd_A23_DQ12;
    if (InitialPageAccess) (A23 *> DQ13) = tpd_A23_DQ13;
    if (InitialPageAccess) (A23 *> DQ14) = tpd_A23_DQ14;
    if (InitialPageAccess) (A23 *> DQ15) = tpd_A23_DQ15;
    if (InitialPageAccess) (A24 *> DQ0)  = tpd_A24_DQ0;
    if (InitialPageAccess) (A24 *> DQ1)  = tpd_A24_DQ1;
    if (InitialPageAccess) (A24 *> DQ2)  = tpd_A24_DQ2;
    if (InitialPageAccess) (A24 *> DQ3)  = tpd_A24_DQ3;
    if (InitialPageAccess) (A24 *> DQ4)  = tpd_A24_DQ4;
    if (InitialPageAccess) (A24 *> DQ5)  = tpd_A24_DQ5;
    if (InitialPageAccess) (A24 *> DQ6)  = tpd_A24_DQ6;
    if (InitialPageAccess) (A24 *> DQ7)  = tpd_A24_DQ7;
    if (InitialPageAccess) (A24 *> DQ8)  = tpd_A24_DQ8;
    if (InitialPageAccess) (A24 *> DQ9)  = tpd_A24_DQ9;
    if (InitialPageAccess) (A24 *> DQ10) = tpd_A24_DQ10;
    if (InitialPageAccess) (A24 *> DQ11) = tpd_A24_DQ11;
    if (InitialPageAccess) (A24 *> DQ12) = tpd_A24_DQ12;
    if (InitialPageAccess) (A24 *> DQ13) = tpd_A24_DQ13;
    if (InitialPageAccess) (A24 *> DQ14) = tpd_A24_DQ14;
    if (InitialPageAccess) (A24 *> DQ15) = tpd_A24_DQ15;

    if (SubsequentPageAccess) (A1 *> DQ0)  = tpd_A1_DQ0;
    if (SubsequentPageAccess) (A1 *> DQ1)  = tpd_A1_DQ1;
    if (SubsequentPageAccess) (A1 *> DQ2)  = tpd_A1_DQ2;
    if (SubsequentPageAccess) (A1 *> DQ3)  = tpd_A1_DQ3;
    if (SubsequentPageAccess) (A1 *> DQ4)  = tpd_A1_DQ4;
    if (SubsequentPageAccess) (A1 *> DQ5)  = tpd_A1_DQ5;
    if (SubsequentPageAccess) (A1 *> DQ6)  = tpd_A1_DQ6;
    if (SubsequentPageAccess) (A1 *> DQ7)  = tpd_A1_DQ7;
    if (SubsequentPageAccess) (A1 *> DQ8)  = tpd_A1_DQ8;
    if (SubsequentPageAccess) (A1 *> DQ9)  = tpd_A1_DQ9;
    if (SubsequentPageAccess) (A1 *> DQ10) = tpd_A1_DQ10;
    if (SubsequentPageAccess) (A1 *> DQ11) = tpd_A1_DQ11;
    if (SubsequentPageAccess) (A1 *> DQ12) = tpd_A1_DQ12;
    if (SubsequentPageAccess) (A1 *> DQ13) = tpd_A1_DQ13;
    if (SubsequentPageAccess) (A1 *> DQ14) = tpd_A1_DQ14;
    if (SubsequentPageAccess) (A1 *> DQ15) = tpd_A1_DQ15;
    if (SubsequentPageAccess) (A2 *> DQ0)  = tpd_A2_DQ0;
    if (SubsequentPageAccess) (A2 *> DQ1)  = tpd_A2_DQ1;
    if (SubsequentPageAccess) (A2 *> DQ2)  = tpd_A2_DQ2;
    if (SubsequentPageAccess) (A2 *> DQ3)  = tpd_A2_DQ3;
    if (SubsequentPageAccess) (A2 *> DQ4)  = tpd_A2_DQ4;
    if (SubsequentPageAccess) (A2 *> DQ5)  = tpd_A2_DQ5;
    if (SubsequentPageAccess) (A2 *> DQ6)  = tpd_A2_DQ6;
    if (SubsequentPageAccess) (A2 *> DQ7)  = tpd_A2_DQ7;
    if (SubsequentPageAccess) (A2 *> DQ8)  = tpd_A2_DQ8;
    if (SubsequentPageAccess) (A2 *> DQ9)  = tpd_A2_DQ9;
    if (SubsequentPageAccess) (A2 *> DQ10) = tpd_A2_DQ10;
    if (SubsequentPageAccess) (A2 *> DQ11) = tpd_A2_DQ11;
    if (SubsequentPageAccess) (A2 *> DQ12) = tpd_A2_DQ12;
    if (SubsequentPageAccess) (A2 *> DQ13) = tpd_A2_DQ13;
    if (SubsequentPageAccess) (A2 *> DQ14) = tpd_A2_DQ14;
    if (SubsequentPageAccess) (A2 *> DQ15) = tpd_A2_DQ15;

    if (FROMCE) (CENeg *> DQ0) = tpd_CENeg_DQ0;
    if (FROMCE) (CENeg *> DQ1) = tpd_CENeg_DQ1;
    if (FROMCE) (CENeg *> DQ2) = tpd_CENeg_DQ2;
    if (FROMCE) (CENeg *> DQ3) = tpd_CENeg_DQ3;
    if (FROMCE) (CENeg *> DQ4) = tpd_CENeg_DQ4;
    if (FROMCE) (CENeg *> DQ5) = tpd_CENeg_DQ5;
    if (FROMCE) (CENeg *> DQ6) = tpd_CENeg_DQ6;
    if (FROMCE) (CENeg *> DQ7) = tpd_CENeg_DQ7;
    if (FROMCE) (CENeg *> DQ8) = tpd_CENeg_DQ8;
    if (FROMCE) (CENeg *> DQ9) = tpd_CENeg_DQ9;
    if (FROMCE) (CENeg *> DQ10)= tpd_CENeg_DQ10;
    if (FROMCE) (CENeg *> DQ11)= tpd_CENeg_DQ11;
    if (FROMCE) (CENeg *> DQ12)= tpd_CENeg_DQ12;
    if (FROMCE) (CENeg *> DQ13)= tpd_CENeg_DQ13;
    if (FROMCE) (CENeg *> DQ14)= tpd_CENeg_DQ14;
    if (FROMCE) (CENeg *> DQ15)= tpd_CENeg_DQ15;

    if (FROMOE) (OENeg *> DQ0)  = tpd_OENeg_DQ0;
    if (FROMOE) (OENeg *> DQ1)  = tpd_OENeg_DQ1;
    if (FROMOE) (OENeg *> DQ2)  = tpd_OENeg_DQ2;
    if (FROMOE) (OENeg *> DQ3)  = tpd_OENeg_DQ3;
    if (FROMOE) (OENeg *> DQ4)  = tpd_OENeg_DQ4;
    if (FROMOE) (OENeg *> DQ5)  = tpd_OENeg_DQ5;
    if (FROMOE) (OENeg *> DQ6)  = tpd_OENeg_DQ6;
    if (FROMOE) (OENeg *> DQ7)  = tpd_OENeg_DQ7;
    if (FROMOE) (OENeg *> DQ8)  = tpd_OENeg_DQ8;
    if (FROMOE) (OENeg *> DQ9)  = tpd_OENeg_DQ9;
    if (FROMOE) (OENeg *> DQ10) = tpd_OENeg_DQ10;
    if (FROMOE) (OENeg *> DQ11) = tpd_OENeg_DQ11;
    if (FROMOE) (OENeg *> DQ12) = tpd_OENeg_DQ12;
    if (FROMOE) (OENeg *> DQ13) = tpd_OENeg_DQ13;
    if (FROMOE) (OENeg *> DQ14) = tpd_OENeg_DQ14;
    if (FROMOE) (OENeg *> DQ15) = tpd_OENeg_DQ15;

    if (RCR[15] === 1'b0) ( CLK *> DQ0 )   =  tpd_CLK_DQ0   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ1 )   =  tpd_CLK_DQ1   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ2 )   =  tpd_CLK_DQ2   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ3 )   =  tpd_CLK_DQ3   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ4 )   =  tpd_CLK_DQ4   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ5 )   =  tpd_CLK_DQ5   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ6 )   =  tpd_CLK_DQ6   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ7 )   =  tpd_CLK_DQ7   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ8 )   =  tpd_CLK_DQ8   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ9 )   =  tpd_CLK_DQ9   ;
    if (RCR[15] === 1'b0) ( CLK *> DQ10)   =  tpd_CLK_DQ10  ;
    if (RCR[15] === 1'b0) ( CLK *> DQ11)   =  tpd_CLK_DQ11  ;
    if (RCR[15] === 1'b0) ( CLK *> DQ12)   =  tpd_CLK_DQ12  ;
    if (RCR[15] === 1'b0) ( CLK *> DQ13)   =  tpd_CLK_DQ13  ;
    if (RCR[15] === 1'b0) ( CLK *> DQ14)   =  tpd_CLK_DQ14  ;
    if (RCR[15] === 1'b0) ( CLK *> DQ15)   =  tpd_CLK_DQ15  ;

    ( CENeg *> WAITOut)         =  tpd_CE0Neg_WAITOut ;
    ( OENeg *> WAITOut)         =  tpd_OE0Neg_WAITOut ;
    if (RCR[15] === 1'b0) ( CLK *> WAITOut) = tpd_CLK_WAITOut;

///////////////////////////////////////////////////////////////////////////////
// Timing Violation                                                          //
///////////////////////////////////////////////////////////////////////////////
    $setup ( A1   , posedge ADVNeg, tsetup_A1_ADVNeg, Viol);
    $setup ( A2   , posedge ADVNeg, tsetup_A2_ADVNeg, Viol);
    $setup ( A3   , posedge ADVNeg, tsetup_A3_ADVNeg, Viol);
    $setup ( A4   , posedge ADVNeg, tsetup_A4_ADVNeg, Viol);
    $setup ( A5   , posedge ADVNeg, tsetup_A5_ADVNeg, Viol);
    $setup ( A6   , posedge ADVNeg, tsetup_A6_ADVNeg, Viol);
    $setup ( A7   , posedge ADVNeg, tsetup_A7_ADVNeg, Viol);
    $setup ( A8   , posedge ADVNeg, tsetup_A8_ADVNeg, Viol);
    $setup ( A9   , posedge ADVNeg, tsetup_A9_ADVNeg, Viol);
    $setup ( A10  , posedge ADVNeg, tsetup_A10_ADVNeg, Viol);
    $setup ( A11  , posedge ADVNeg, tsetup_A11_ADVNeg, Viol);
    $setup ( A12  , posedge ADVNeg, tsetup_A12_ADVNeg, Viol);
    $setup ( A13  , posedge ADVNeg, tsetup_A13_ADVNeg, Viol);
    $setup ( A14  , posedge ADVNeg, tsetup_A14_ADVNeg, Viol);
    $setup ( A15  , posedge ADVNeg, tsetup_A15_ADVNeg, Viol);
    $setup ( A16  , posedge ADVNeg, tsetup_A16_ADVNeg, Viol);
    $setup ( A17  , posedge ADVNeg, tsetup_A17_ADVNeg, Viol);
    $setup ( A18  , posedge ADVNeg, tsetup_A18_ADVNeg, Viol);
    $setup ( A19  , posedge ADVNeg, tsetup_A19_ADVNeg, Viol);
    $setup ( A20  , posedge ADVNeg, tsetup_A20_ADVNeg, Viol);
    $setup ( A21  , posedge ADVNeg, tsetup_A21_ADVNeg, Viol);
    $setup ( A22  , posedge ADVNeg, tsetup_A22_ADVNeg, Viol);
    $setup ( A23  , posedge ADVNeg, tsetup_A23_ADVNeg, Viol);
    $setup ( A24  , posedge ADVNeg, tsetup_A24_ADVNeg, Viol);

    $setup ( negedge CENeg  , posedge ADVNeg, tsetup_CENeg_ADVNeg, Viol);
    $setup ( negedge RSTNeg , posedge ADVNeg, tsetup_RSTNeg_ADVNeg,Viol);
    $setup ( posedge WENeg  , posedge ADVNeg, tsetup_WENeg_ADVNeg, Viol);

    $setup ( A1   , posedge CLK &&& CLK_rising, tsetup_A1_CLK, Viol);
    $setup ( A2   , posedge CLK &&& CLK_rising, tsetup_A2_CLK, Viol);
    $setup ( A3   , posedge CLK &&& CLK_rising, tsetup_A3_CLK, Viol);
    $setup ( A4   , posedge CLK &&& CLK_rising, tsetup_A4_CLK, Viol);
    $setup ( A5   , posedge CLK &&& CLK_rising, tsetup_A5_CLK, Viol);
    $setup ( A6   , posedge CLK &&& CLK_rising, tsetup_A6_CLK, Viol);
    $setup ( A7   , posedge CLK &&& CLK_rising, tsetup_A7_CLK, Viol);
    $setup ( A8   , posedge CLK &&& CLK_rising, tsetup_A8_CLK, Viol);
    $setup ( A9   , posedge CLK &&& CLK_rising, tsetup_A9_CLK, Viol);
    $setup ( A10  , posedge CLK &&& CLK_rising, tsetup_A10_CLK, Viol);
    $setup ( A11  , posedge CLK &&& CLK_rising, tsetup_A11_CLK, Viol);
    $setup ( A12  , posedge CLK &&& CLK_rising, tsetup_A12_CLK, Viol);
    $setup ( A13  , posedge CLK &&& CLK_rising, tsetup_A13_CLK, Viol);
    $setup ( A14  , posedge CLK &&& CLK_rising, tsetup_A14_CLK, Viol);
    $setup ( A15  , posedge CLK &&& CLK_rising, tsetup_A15_CLK, Viol);
    $setup ( A16  , posedge CLK &&& CLK_rising, tsetup_A16_CLK, Viol);
    $setup ( A17  , posedge CLK &&& CLK_rising, tsetup_A17_CLK, Viol);
    $setup ( A18  , posedge CLK &&& CLK_rising, tsetup_A18_CLK, Viol);
    $setup ( A19  , posedge CLK &&& CLK_rising, tsetup_A19_CLK, Viol);
    $setup ( A20  , posedge CLK &&& CLK_rising, tsetup_A20_CLK, Viol);
    $setup ( A21  , posedge CLK &&& CLK_rising, tsetup_A21_CLK, Viol);
    $setup ( A22  , posedge CLK &&& CLK_rising, tsetup_A22_CLK, Viol);
    $setup ( A23  , posedge CLK &&& CLK_rising, tsetup_A23_CLK, Viol);
    $setup ( A24  , posedge CLK &&& CLK_rising, tsetup_A24_CLK, Viol);

    $setup ( A1   , negedge CLK &&& CLK_falling, tsetup_A1_CLK, Viol);
    $setup ( A2   , negedge CLK &&& CLK_falling, tsetup_A2_CLK, Viol);
    $setup ( A3   , negedge CLK &&& CLK_falling, tsetup_A3_CLK, Viol);
    $setup ( A4   , negedge CLK &&& CLK_falling, tsetup_A4_CLK, Viol);
    $setup ( A5   , negedge CLK &&& CLK_falling, tsetup_A5_CLK, Viol);
    $setup ( A6   , negedge CLK &&& CLK_falling, tsetup_A6_CLK, Viol);
    $setup ( A7   , negedge CLK &&& CLK_falling, tsetup_A7_CLK, Viol);
    $setup ( A8   , negedge CLK &&& CLK_falling, tsetup_A8_CLK, Viol);
    $setup ( A9   , negedge CLK &&& CLK_falling, tsetup_A9_CLK, Viol);
    $setup ( A10  , negedge CLK &&& CLK_falling, tsetup_A10_CLK, Viol);
    $setup ( A11  , negedge CLK &&& CLK_falling, tsetup_A11_CLK, Viol);
    $setup ( A12  , negedge CLK &&& CLK_falling, tsetup_A12_CLK, Viol);
    $setup ( A13  , negedge CLK &&& CLK_falling, tsetup_A13_CLK, Viol);
    $setup ( A14  , negedge CLK &&& CLK_falling, tsetup_A14_CLK, Viol);
    $setup ( A15  , negedge CLK &&& CLK_falling, tsetup_A15_CLK, Viol);
    $setup ( A16  , negedge CLK &&& CLK_falling, tsetup_A16_CLK, Viol);
    $setup ( A17  , negedge CLK &&& CLK_falling, tsetup_A17_CLK, Viol);
    $setup ( A18  , negedge CLK &&& CLK_falling, tsetup_A18_CLK, Viol);
    $setup ( A19  , negedge CLK &&& CLK_falling, tsetup_A19_CLK, Viol);
    $setup ( A20  , negedge CLK &&& CLK_falling, tsetup_A20_CLK, Viol);
    $setup ( A21  , negedge CLK &&& CLK_falling, tsetup_A21_CLK, Viol);
    $setup ( A22  , negedge CLK &&& CLK_falling, tsetup_A22_CLK, Viol);
    $setup ( A23  , negedge CLK &&& CLK_falling, tsetup_A23_CLK, Viol);
    $setup ( A24  , negedge CLK &&& CLK_falling, tsetup_A24_CLK, Viol);

    $setup ( negedge ADVNeg , posedge CLK &&& CLK_rising ,
             tsetup_ADVNeg_CLK, Viol);
    $setup ( negedge ADVNeg , negedge CLK &&& CLK_falling ,
             tsetup_ADVNeg_CLK, Viol);

    $setup ( negedge CENeg  , posedge CLK &&& CLK_rising ,
             tsetup_CENeg_CLK, Viol);
    $setup ( negedge CENeg  , negedge CLK &&& CLK_falling ,
             tsetup_CENeg_CLK, Viol);

    $setup ( posedge WENeg  , posedge CLK &&& CLK_rising ,
             tsetup_WENeg_CLK, Viol);
    $setup ( posedge WENeg  , negedge CLK &&& CLK_falling ,
             tsetup_WENeg_CLK, Viol);

    $setup ( negedge CENeg  , negedge WENeg , tsetup_CENeg_WENeg, Viol);

    $setup ( DQ0   , posedge WENeg , tsetup_DQ0_WENeg, Viol);
    $setup ( DQ1   , posedge WENeg , tsetup_DQ1_WENeg, Viol);
    $setup ( DQ2   , posedge WENeg , tsetup_DQ2_WENeg, Viol);
    $setup ( DQ3   , posedge WENeg , tsetup_DQ3_WENeg, Viol);
    $setup ( DQ4   , posedge WENeg , tsetup_DQ4_WENeg, Viol);
    $setup ( DQ5   , posedge WENeg , tsetup_DQ5_WENeg, Viol);
    $setup ( DQ6   , posedge WENeg , tsetup_DQ6_WENeg, Viol);
    $setup ( DQ7   , posedge WENeg , tsetup_DQ7_WENeg, Viol);
    $setup ( DQ8   , posedge WENeg , tsetup_DQ8_WENeg, Viol);
    $setup ( DQ9   , posedge WENeg , tsetup_DQ9_WENeg, Viol);
    $setup ( DQ10  , posedge WENeg , tsetup_DQ10_WENeg, Viol);
    $setup ( DQ11  , posedge WENeg , tsetup_DQ11_WENeg, Viol);
    $setup ( DQ12  , posedge WENeg , tsetup_DQ12_WENeg, Viol);
    $setup ( DQ13  , posedge WENeg , tsetup_DQ13_WENeg, Viol);
    $setup ( DQ14  , posedge WENeg , tsetup_DQ14_WENeg, Viol);
    $setup ( DQ15  , posedge WENeg , tsetup_DQ15_WENeg, Viol);

    $setup ( A1   , posedge WENeg , tsetup_A1_WENeg, Viol);
    $setup ( A2   , posedge WENeg , tsetup_A2_WENeg, Viol);
    $setup ( A3   , posedge WENeg , tsetup_A3_WENeg, Viol);
    $setup ( A4   , posedge WENeg , tsetup_A4_WENeg, Viol);
    $setup ( A5   , posedge WENeg , tsetup_A5_WENeg, Viol);
    $setup ( A6   , posedge WENeg , tsetup_A6_WENeg, Viol);
    $setup ( A7   , posedge WENeg , tsetup_A7_WENeg, Viol);
    $setup ( A8   , posedge WENeg , tsetup_A8_WENeg, Viol);
    $setup ( A9   , posedge WENeg , tsetup_A9_WENeg, Viol);
    $setup ( A10  , posedge WENeg , tsetup_A10_WENeg, Viol);
    $setup ( A11  , posedge WENeg , tsetup_A11_WENeg, Viol);
    $setup ( A12  , posedge WENeg , tsetup_A12_WENeg, Viol);
    $setup ( A13  , posedge WENeg , tsetup_A13_WENeg, Viol);
    $setup ( A14  , posedge WENeg , tsetup_A14_WENeg, Viol);
    $setup ( A15  , posedge WENeg , tsetup_A15_WENeg, Viol);
    $setup ( A16  , posedge WENeg , tsetup_A16_WENeg, Viol);
    $setup ( A17  , posedge WENeg , tsetup_A17_WENeg, Viol);
    $setup ( A18  , posedge WENeg , tsetup_A18_WENeg, Viol);
    $setup ( A19  , posedge WENeg , tsetup_A19_WENeg, Viol);
    $setup ( A20  , posedge WENeg , tsetup_A20_WENeg, Viol);
    $setup ( A21  , posedge WENeg , tsetup_A21_WENeg, Viol);
    $setup ( A22  , posedge WENeg , tsetup_A22_WENeg, Viol);
    $setup ( A23  , posedge WENeg , tsetup_A23_WENeg, Viol);
    $setup ( A24  , posedge WENeg , tsetup_A24_WENeg, Viol);

    $setup (posedge ADVNeg, posedge WENeg , tsetup_ADVNeg_WENeg, Viol);
    $setup (posedge WPNeg, posedge WENeg , tsetup_WPNeg_WENeg, Viol);

    $setup (posedge CLK &&& CLK_rising, negedge WENeg ,
            tsetup_CLK_WENeg, Viol);
    $setup (negedge CLK &&& CLK_falling, negedge WENeg ,
            tsetup_CLK_WENeg, Viol);

    $setup (posedge WENeg, negedge OENeg , tsetup_WENeg_OENeg, Viol);

    $hold ( posedge WENeg,  CENeg, thold_CENeg_WENeg, Viol);

    $hold (  posedge WENeg ,DQ0 , thold_DQ0_WENeg, Viol);
    $hold (  posedge WENeg ,DQ1 , thold_DQ1_WENeg, Viol);
    $hold (  posedge WENeg ,DQ2 , thold_DQ2_WENeg, Viol);
    $hold (  posedge WENeg ,DQ3 , thold_DQ3_WENeg, Viol);
    $hold (  posedge WENeg ,DQ4 , thold_DQ4_WENeg, Viol);
    $hold (  posedge WENeg ,DQ5 , thold_DQ5_WENeg, Viol);
    $hold (  posedge WENeg ,DQ6 , thold_DQ6_WENeg, Viol);
    $hold (  posedge WENeg ,DQ7 , thold_DQ7_WENeg, Viol);
    $hold (  posedge WENeg ,DQ8 , thold_DQ8_WENeg, Viol);
    $hold (  posedge WENeg ,DQ9 , thold_DQ9_WENeg, Viol);
    $hold (  posedge WENeg ,DQ10, thold_DQ10_WENeg, Viol);
    $hold (  posedge WENeg ,DQ11, thold_DQ11_WENeg, Viol);
    $hold (  posedge WENeg ,DQ12, thold_DQ12_WENeg, Viol);
    $hold (  posedge WENeg ,DQ13, thold_DQ13_WENeg, Viol);
    $hold (  posedge WENeg ,DQ14, thold_DQ14_WENeg, Viol);
    $hold (  posedge WENeg ,DQ15, thold_DQ15_WENeg, Viol);

    $hold (  posedge WENeg ,A1, thold_A1_WENeg, Viol);
    $hold (  posedge WENeg ,A2, thold_A2_WENeg, Viol);
    $hold (  posedge WENeg ,A3, thold_A3_WENeg, Viol);
    $hold (  posedge WENeg ,A4, thold_A4_WENeg, Viol);
    $hold (  posedge WENeg ,A5, thold_A5_WENeg, Viol);
    $hold (  posedge WENeg ,A6, thold_A6_WENeg, Viol);
    $hold (  posedge WENeg ,A7, thold_A7_WENeg, Viol);
    $hold (  posedge WENeg ,A8, thold_A8_WENeg, Viol);
    $hold (  posedge WENeg ,A9, thold_A9_WENeg, Viol);
    $hold (  posedge WENeg ,A10, thold_A10_WENeg, Viol);
    $hold (  posedge WENeg ,A11, thold_A11_WENeg, Viol);
    $hold (  posedge WENeg ,A12, thold_A12_WENeg, Viol);
    $hold (  posedge WENeg ,A13, thold_A13_WENeg, Viol);
    $hold (  posedge WENeg ,A14, thold_A14_WENeg, Viol);
    $hold (  posedge WENeg ,A15, thold_A15_WENeg, Viol);
    $hold (  posedge WENeg ,A16, thold_A16_WENeg, Viol);
    $hold (  posedge WENeg ,A17, thold_A17_WENeg, Viol);
    $hold (  posedge WENeg ,A18, thold_A18_WENeg, Viol);
    $hold (  posedge WENeg ,A19, thold_A19_WENeg, Viol);
    $hold (  posedge WENeg ,A20, thold_A20_WENeg, Viol);
    $hold (  posedge WENeg ,A21, thold_A21_WENeg, Viol);
    $hold (  posedge WENeg ,A22, thold_A22_WENeg, Viol);
    $hold (  posedge WENeg ,A23, thold_A23_WENeg, Viol);
    $hold (  posedge WENeg ,A24, thold_A24_WENeg, Viol);

    $hold (  posedge ADVNeg ,A1, thold_A1_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A2, thold_A2_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A3, thold_A3_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A4, thold_A4_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A5, thold_A5_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A6, thold_A6_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A7, thold_A7_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A8, thold_A8_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A9, thold_A9_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A10, thold_A10_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A11, thold_A11_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A12, thold_A12_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A13, thold_A13_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A14, thold_A14_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A15, thold_A15_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A16, thold_A16_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A17, thold_A17_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A18, thold_A18_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A19, thold_A19_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A20, thold_A20_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A21, thold_A21_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A22, thold_A22_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A23, thold_A23_ADVNeg, Viol);
    $hold (  posedge ADVNeg ,A24, thold_A24_ADVNeg, Viol);

    $hold ( posedge CLK &&& CLK_rising, A1  , thold_A1_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A2  , thold_A2_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A3  , thold_A3_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A4  , thold_A4_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A5  , thold_A5_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A6  , thold_A6_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A7  , thold_A7_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A8  , thold_A8_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A9  , thold_A9_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A10 , thold_A10_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A11 , thold_A11_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A12 , thold_A12_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A13 , thold_A13_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A14 , thold_A14_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A15 , thold_A15_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A16 , thold_A16_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A17 , thold_A17_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A18 , thold_A18_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A19 , thold_A19_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A20 , thold_A20_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A21 , thold_A21_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A22 , thold_A22_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A23 , thold_A23_CLK, Viol);
    $hold ( posedge CLK &&& CLK_rising, A24 , thold_A24_CLK, Viol);

    $hold ( negedge CLK &&& CLK_falling, A1  , thold_A1_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A2  , thold_A2_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A3  , thold_A3_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A4  , thold_A4_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A5  , thold_A5_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A6  , thold_A6_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A7  , thold_A7_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A8  , thold_A8_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A9  , thold_A9_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A10 , thold_A10_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A11 , thold_A11_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A12 , thold_A12_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A13 , thold_A13_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A14 , thold_A14_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A15 , thold_A15_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A16 , thold_A16_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A17 , thold_A17_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A18 , thold_A18_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A19 , thold_A19_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A20 , thold_A20_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A21 , thold_A21_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A22 , thold_A22_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A23 , thold_A23_CLK, Viol);
    $hold ( negedge CLK &&& CLK_falling, A24 , thold_A24_CLK, Viol);

    $width ( posedge CENeg , tpw_CENeg_posedge );
    $width ( posedge ADVNeg, tpw_ADVNeg_posedge );
    $width ( negedge ADVNeg, tpw_ADVNeg_negedge );
    $width ( posedge CLK   , tpw_CLK_posedge );
    $width ( negedge CLK   , tpw_CLK_negedge );
    $width ( posedge WENeg , tpw_WENeg_posedge );
    $width ( negedge WENeg , tpw_WENeg_negedge );
    $width ( negedge RSTNeg, tpw_RSTNeg_negedge );
    $period( posedge CLK   , tperiod_CLK);
    $period( negedge CLK   , tperiod_CLK);

endspecify

    //tdevice parameters aligned to model timescale

    // Program EraseParameter
    time tdevice_EraseParameter
                            = tdevice_EraseParameter_td*1000; //2.5 sec;
    // Parameter Block Erase - 12V
    time tdevice_EraseMain = tdevice_EraseMain_td*1000; //4 sec;

///////////////////////////////////////////////////////////////////////////////
// Main Behavior Block                                                       //
///////////////////////////////////////////////////////////////////////////////

    always @(DQIn, DQOut)
    begin
        if (DQIn==DQOut)
            deq=1'b1;
        else
            deq=1'b0;
    end
    // chech when data is generated from model to avoid setuphold check in
    // those occasion
    assign deg=deq;

    // initialize memory and load preload files if any
    initial
    begin: InitMemory
        integer i;
        for (i=0;i<=MemSize;i=i+1)
        begin
            MemData[i]=MaxData;
        end
        if ((UserPreload) && !(mem_file_name == "none"))
        begin
            // File Read Section
            //#i28f512p33_2 memory file
            //#   /         - comment
            //#   @aaaaa    - <aaaaa> stands for address
            //#   dddd      - <dddd> is word to be written at Mem(aaaaa++)
            //#                 (aaaaa is incremented at every load)
            //#
            //#   only first 1-6 columns are loaded. NO empty lines !
            $readmemh(mem_file_name, MemData);
        end

        for (i=0;i<=BlockNum;i=i+1)
        begin
            OTP[i]=1'b0;
        end
        if ((UserPreload) && !(otp_blocks_file == "none"))
            begin
            // File Read Section
            //#i28f512p33_2 memory file
            //#   /         - comment
            //#   @aaa      - <aaa> stands for address
            //#   dddd      - <dddd> is word to be written at OTP(aaa++)
            //#                 (aaa is incremented at every load)
            //#
            //#   only first 1-6 columns are loaded. NO empty lines !
            $readmemh(otp_blocks_file, OTP);
        end

        PR[9'h80] = 16'hFFFE;
        for (i=9'h81;i<=9'h109;i=i+1)
        begin
            PR[i]=MaxData;
        end
        if ((UserPreload) && !(prot_reg_file == "none"))
        begin
            // File Read Section
            //#i28f512p33_2 memory file
            //#   /         - comment
            //#   @aaa      - <aaa> stands for address
            //#   dddd      - <dddd> is word to be written at PR(aaa++)
            //#                 (aaa is incremented at every load)
            //#
            //#   only first 1-6 columns are loaded. NO empty lines !
            $readmemh(prot_reg_file, PR);
        end

        for (i=0;i<=BlockNum;i=i+1)
        begin
            Block_Lock[i] = LOCKED;
            BlockLockBit[i] = 1'b1;
            BlockLockDownBit[i] = 1'b0;
        end
    end

    initial
    begin
        ///////////////////////////////////////////////////////////////////////
        //CFI array data
        ///////////////////////////////////////////////////////////////////////

        CFI_array[9'h10]=16'h51;
        CFI_array[9'h11]=16'h52;
        CFI_array[9'h12]=16'h59;
        CFI_array[9'h13]=16'h01;
        CFI_array[9'h14]=16'h00;
        CFI_array[9'h15]=16'h0A;
        CFI_array[9'h16]=16'h01;
        CFI_array[9'h17]=16'h00;
        CFI_array[9'h18]=16'h00;
        CFI_array[9'h19]=16'h00;
        CFI_array[9'h1A]=16'h00;
        // System Interface Information
        CFI_array[9'h1B]=16'h23;
        CFI_array[9'h1C]=16'h36;
        CFI_array[9'h1D]=16'h85;
        CFI_array[9'h1E]=16'h95;
        CFI_array[9'h1F]=16'h08;
        CFI_array[9'h20]=16'h09;
        CFI_array[9'h21]=16'h0A;
        CFI_array[9'h22]=16'h00;
        CFI_array[9'h23]=16'h01;
        CFI_array[9'h24]=16'h01;
        CFI_array[9'h25]=16'h02;
        CFI_array[9'h26]=16'h00;
        // Device Geometry definition
        CFI_array[9'h27]=16'h19;
        CFI_array[9'h28]=16'h01;
        CFI_array[9'h29]=16'h00;
        CFI_array[9'h2A]=16'h06;
        CFI_array[9'h2B]=16'h00;
        CFI_array[9'h2C]=16'h02;
        CFI_array[9'h2D]=16'h03;
        CFI_array[9'h2E]=16'h00;
        CFI_array[9'h2F]=16'h80;
        CFI_array[9'h30]=16'h00;
        CFI_array[9'h31]=16'hFE;
        CFI_array[9'h32]=16'h00;
        CFI_array[9'h33]=16'h00;
        CFI_array[9'h34]=16'h02;
        CFI_array[9'h35]=16'h00;
        CFI_array[9'h36]=16'h00;
        CFI_array[9'h37]=16'h00;
        CFI_array[9'h38]=16'h00;
        // Primary-vendor specific extended query
        CFI_array[9'h10A]=16'h50;
        CFI_array[9'h10B]=16'h52;
        CFI_array[9'h10C]=16'h49;
        CFI_array[9'h10D]=16'h31;
        CFI_array[9'h10E]=16'h34;
        CFI_array[9'h10F]=16'hE6;
        CFI_array[9'h110]=16'h01;
        CFI_array[9'h111]=16'h00;
        CFI_array[9'h112]=16'h00; // Bottom Parameter Block Lower die
        CFI_array[9'h113]=16'h01;
        CFI_array[9'h114]=16'h03;
        CFI_array[9'h115]=16'h00;
        CFI_array[9'h116]=16'h30;
        CFI_array[9'h117]=16'h90;
        // Protection register information
        CFI_array[9'h118]=16'h02;
        CFI_array[9'h119]=16'h80;
        CFI_array[9'h11A]=16'h00;
        CFI_array[9'h11B]=16'h03;
        CFI_array[9'h11C]=16'h03;
        CFI_array[9'h11D]=16'h89;
        CFI_array[9'h11E]=16'h00;
        CFI_array[9'h11F]=16'h00;
        CFI_array[9'h120]=16'h00;
        CFI_array[9'h121]=16'h00;
        CFI_array[9'h122]=16'h00;
        CFI_array[9'h123]=16'h00;
        CFI_array[9'h124]=16'h10;
        CFI_array[9'h125]=16'h00;
        CFI_array[9'h126]=16'h04;
        // Burst read information
        CFI_array[9'h127]=16'h03;
        CFI_array[9'h128]=16'h04;
        CFI_array[9'h129]=16'h01;
        CFI_array[9'h12A]=16'h02;
        CFI_array[9'h12B]=16'h03;
        CFI_array[9'h12C]=16'h07;
        //Partition and Erase Block Region Information
        CFI_array[9'h12D]=16'h01;
        CFI_array[9'h12E]=16'h24;
        CFI_array[9'h12F]=16'h00;
        CFI_array[9'h130]=16'h01;
        CFI_array[9'h131]=16'h00;
        CFI_array[9'h132]=16'h11;
        CFI_array[9'h133]=16'h00;
        CFI_array[9'h134]=16'h00;
        CFI_array[9'h135]=16'h02;
        CFI_array[9'h136]=16'h03;
        CFI_array[9'h137]=16'h00;
        CFI_array[9'h138]=16'h80;
        CFI_array[9'h139]=16'h00;
        CFI_array[9'h13A]=16'h64;
        CFI_array[9'h13B]=16'h00;
        CFI_array[9'h13C]=16'h02;
        CFI_array[9'h13D]=16'h03;
        CFI_array[9'h13E]=16'h00;
        CFI_array[9'h13F]=16'h80;
        CFI_array[9'h140]=16'h00;
        CFI_array[9'h141]=16'h00;
        CFI_array[9'h142]=16'h00;
        CFI_array[9'h143]=16'h80;
        CFI_array[9'h144]=16'hFE;
        CFI_array[9'h145]=16'h00;
        CFI_array[9'h146]=16'h00;
        CFI_array[9'h147]=16'h02;
        CFI_array[9'h148]=16'h64;
        CFI_array[9'h149]=16'h00;
        CFI_array[9'h14A]=16'h02;
        CFI_array[9'h14B]=16'h03;
        CFI_array[9'h14C]=16'h00;
        CFI_array[9'h14D]=16'h80;
        CFI_array[9'h14E]=16'h00;
        CFI_array[9'h14F]=16'h00;
        CFI_array[9'h150]=16'h00;
        CFI_array[9'h151]=16'h80;
        CFI_array[9'h152]=16'hFF;
        CFI_array[9'h153]=16'hFF;
        CFI_array[9'h154]=16'hFF;
        CFI_array[9'h155]=16'hFF;
        CFI_array[9'h156]=16'hFF;
    end

    initial
    begin
        current_state          = RESET_POWER_DOWN;
        next_state             = RESET_POWER_DOWN;
        read_state             = READ_ARRAY;

        WordProgram_in         = 1'b0;
        BuffProgram_in         = 1'b0;
        BEFP_in                = 1'b0;
        BEFPsetup_in           = 1'b0;
        ParameterErase_in      = 1'b0;
        MainErase_in           = 1'b0;
        ProgramSuspend_in      = 1'b0;
        EraseSuspend_in        = 1'b0;
        RstDuringErsPrg_in     = 1'b0;

        CLOCK           = 1'b0;
        Write           = 1'b0;
        Read            = 1'b0;
        Pmode           = 1'b0;
        abort           = 1'b0;
        ExtendProgTime  = 1'b0;
        AssertWAITOut   = 1'b0;
        DeassertWAITOut = 1'b0;
        read_out        = 1'b0;

        SR      = 8'b10000000;
        RCR     = 16'b1011111111001111;
        LATCHED = 1'b0;
        Viol    = 1'b0;
        word_cntr = 0;

    end

    ///////////////////////////////////////////////////////////////////////////
    //// Internal Delays
    ///////////////////////////////////////////////////////////////////////////
    always @(posedge BEFP_in)
    begin:BEFP
        BEFP_out = 1'b1;
        #tdevice_BEFP BEFP_out = 1'b0;
    end

    always @(posedge BEFPsetup_in)
    begin:BEFPsetup
        BEFPsetup_out = 1'b1;
        #tdevice_BEFPsetup BEFPsetup_out = 1'b0;
    end

    always @(posedge ProgramSuspend_in)
    begin:ProgramSuspend
        ProgramSuspend_out = 1'b1;
        #tdevice_ProgramSuspend ProgramSuspend_out = 1'b0;
    end

    always @(posedge EraseSuspend_in)
    begin:EraseSuspend
        EraseSuspend_out = 1'b1;
        #tdevice_EraseSuspend EraseSuspend_out = 1'b0;
    end

    always @(posedge RstDuringErsPrg_in)
    begin:RstDuringErsPrg
        RstDuringErsPrg_out = 1'b1;
        #tdevice_RstDuringErsPrg RstDuringErsPrg_out = 1'b0;
    end

    //////////////////////////////////////////////////////////////
    // Clock control
    //////////////////////////////////////////////////////////////

    always @ (posedge CLK_ipd)
    begin : CLKControl1
        if ((RSTNeg_ipd) && (~CENeg_ipd) && (WENeg_ipd) &&
        (RCR[15] == 1'b0) && (RCR[6] == 1'b1) &&
        (current_state != RESET_POWER_DOWN))
        begin
            CLOCK = 1'b1;
            #1 CLOCK <= 1'b0;
        end
    end

    always @ (negedge CLK_ipd)
    begin : CLKControl2
        if ((RSTNeg_ipd) && (~CENeg_ipd) && (WENeg_ipd) &&
        (RCR[15] == 1'b0) && (RCR[6] == 1'b0) &&
        (current_state != RESET_POWER_DOWN))
        begin
            CLOCK = 1'b1;
            #1 CLOCK <= 1'b0;
        end
    end

    always @ (negedge RSTNeg_ipd)
    begin : RSTControl
        if (WordProgram_out ||
        BuffProgram_out ||
        ParameterErase_out || MainErase_out || BEFP_out)
        begin
            RstDuringErsPrg_in = 1'b0;
            #1 RstDuringErsPrg_in <= 1'b1;
        end
    end

    //////////////////////////////////////////////////////////////////////////
    //// bus cycle decode
    //////////////////////////////////////////////////////////////////////////
    always @ (falling_edge_ADVNeg or rising_edge_ADVNeg or rising_edge_CLOCK
    or OENeg or RSTNeg or rising_edge_WENeg or rising_edge_CENeg or WENeg
    or CENeg or Alow_event)
    begin : BusCycleDecode
        if (~RSTNeg || CENeg || falling_edge_ADVNeg)
            LATCHED = 0;

        if (RSTNeg && current_state != RESET_POWER_DOWN)
        begin
            if (~CENeg && ~LATCHED && ((rising_edge_ADVNeg && WENeg) ||
            (~ADVNeg && WENeg && ~RCR[15] && rising_edge_CLOCK) ) )
            begin
                LatchedAddr = A;
                ReadAddr = A;
                LATCHED = 1'b1;
                burst_cntr = 0;
                BurstDelay = RCR[13:11];
                case (RCR[2:0])
                    3'b001: BurstLength = 4;
                    3'b010: BurstLength = 8;
                    3'b011: BurstLength = 16;
                    3'b111: BurstLength = 0;
                endcase
                DataHold = 0;
            end

            // Write control
            if (OENeg)
            begin
                if (~WENeg && ~CENeg)
                    Write = 0;
                else if ((~CENeg && rising_edge_WENeg) || (~WENeg &&
                rising_edge_CENeg)||(rising_edge_CENeg && rising_edge_WENeg))
                begin
                    LatchedData = DQIn;
                    LatchedAddr = A;
                    Write = 1;
                end
            end

            // Read control
            if (RCR[15])
            begin
                if (WENeg && ~CENeg && ~OENeg)
                begin
                    if (~ADVNeg)
                        ReadAddr = A;
                    Read = 1;
                end
                else
                begin
                    Read = 0;
                    Pmode = 0;
                end
                if (Read && Alow_event)
                begin
                    Pmode = 1;
                    Pmode <= #2 0;
                end
            end
            else
            begin
                if (rising_edge_CLOCK)
                begin
                    if (BurstDelay > 0)
                    begin
                        #1 BurstDelay = BurstDelay - 1;
                        if (RCR[8] && (BurstDelay == 0 || (BurstDelay == 1
                        && RCR[9] ) ) )
                            DeassertWAITOut = ~(DeassertWAITOut);
                    end
                    else
                    begin
                        if (DataHold == 0)
                        begin
                            burst_cntr = burst_cntr + 1;
                            if (~OENeg)
                                Read = ~(Read);
                            if (RCR[9])
                                DataHold = 1;
                            if ( (burst_cntr > (BurstLength - RCR[8]) ) &&
                            BurstLength > 0)
                                AssertWAITOut = ~(AssertWAITOut);
                            else if (read_state == READ_ARRAY && ~RCR[9] &&
                            RCR[13:11] > 4)
                            begin
                                if (~RCR[8])
                                begin
                                    if (burst_cntr > 4 || burst_cntr <= 0)
                                        AssertWAITOut = ~(AssertWAITOut);
                                    else
                                        DeassertWAITOut = ~(DeassertWAITOut);
                                end
                                else
                                begin
                                    if (burst_cntr >= 4 || burst_cntr < 0)
                                        AssertWAITOut = ~(AssertWAITOut);
                                    else
                                        DeassertWAITOut = ~(DeassertWAITOut);
                                end
                            end
                                DeassertWAITOut = ~(DeassertWAITOut);
                        end
                        else
                            DataHold = DataHold - 1;
                    end
                end
            end
        end
    end

//////////////////////////////////////////////////////////////////////////////
//// sequential process for reset control and FSM state transition
//////////////////////////////////////////////////////////////////////////////
    always @(next_state)
    begin : FSM
        if (ExtendProgTime == 1'b0)
            current_state = next_state;
    end

    ////////////////////////////////////////////////////////////////////////////
    //     obtain 'LAST_EVENT information
    ////////////////////////////////////////////////////////////////////////////
    always @(negedge OENeg_ipd)
    begin
        OENeg_event = $time;
    end
    always @(negedge CENeg_ipd)
    begin
        CENeg_event = $time;
    end
    always @(A)
    begin
        ADDR_event = $time;
    end

    ///////////////////////////////////////////////////////////////////////////
    // FSM - Combinational process for next state generation
    ///////////////////////////////////////////////////////////////////////////
    always @(falling_edge_RSTNeg or rising_edge_RSTNeg or rising_edge_Write or
        RstDuringErsPrg_out_event or WordProgram_out_event or abort or
        ProgramSuspend_out_event or BuffProgram_out_event
        or ExtendProgTime_event or falling_edge_EraseSuspend_out or
        ParameterErase_out_event or falling_edge_MainErase_out
        or falling_edge_BEFPsetup_out or falling_edge_BEFP_out
        )
    begin : StateGen

        if (falling_edge_RSTNeg)
            next_state = RESET_POWER_DOWN;
        else
        begin
            case (current_state)

            RESET_POWER_DOWN :
            begin
                if (((rising_edge_RSTNeg && ~RstDuringErsPrg_out) ||
                (RstDuringErsPrg_out_event && ~RstDuringErsPrg_out)) &&
                $time > 0 )
                begin
                    next_state = READY;
                end
            end

            READY:
            begin
                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'h10, 16'h40 : next_state = PROG_SETUP;
                        16'hE8 : next_state = BP_SETUP;
                        16'h20 : next_state = ERASE_SETUP;
                        16'h80 : next_state = BEFP_SETUP;
                        16'h60 : next_state = LOCK_SETUP;
                        16'hC0 : next_state = OTP_SETUP;
                        default : next_state = current_state;
                    endcase
                end
            end

            LOCK_SETUP  :
            begin
                if (rising_edge_Write)
                    next_state = READY;
            end

            OTP_SETUP  :
            begin
                if (rising_edge_Write)
                    next_state = OTP_BUSY;
            end

            OTP_BUSY :
            begin
                if (abort ||
                (WordProgram_out_event && ~WordProgram_out) )
                    next_state = READY;
            end

            PROG_SETUP :
            begin
                if (rising_edge_Write)
                    next_state = PROG_BUSY;
            end

            PROG_BUSY :
            begin
                if (abort ||
                (WordProgram_out_event && ~WordProgram_out) )
                    next_state = READY;
                else if (ProgramSuspend_out_event && ~ProgramSuspend_out)
                    next_state = PROG_SUSP;
            end

            PROG_SUSP :
            begin
                if (rising_edge_Write && LatchedData == 16'hD0)
                    next_state = PROG_BUSY;
            end

            BP_SETUP :
            begin
                if (rising_edge_Write)
                begin
                    word_cnt = LatchedData + 1;
                    next_state = BP_LOAD;
                end
            end

            BP_LOAD :
            begin
                if (rising_edge_Write)
                begin
                    word_cnt = word_cnt - 1;
                    if (word_cnt == 0)
                        next_state = BP_CONFIRM;
                end
            end

            BP_CONFIRM :
            begin
                if (rising_edge_Write)
                begin
                    if (LatchedData == 16'hD0)
                        next_state = BP_BUSY;
                    else
                        next_state = READY;
                end
            end

            BP_BUSY :
            begin
                if (abort ||
                (BuffProgram_out_event && ~BuffProgram_out && ~ExtendProgTime))
                    next_state = READY;
                else if (ProgramSuspend_out_event && ~ProgramSuspend_out)
                    next_state = BP_SUSP;
                else if (ExtendProgTime_event)
                    next_state = current_state;
            end

            BP_SUSP :
            begin
                if (rising_edge_Write && LatchedData == 16'hD0)
                    next_state = BP_BUSY;
            end

            ERASE_SETUP :
            begin
                if (rising_edge_Write)
                begin
                    if (LatchedData == 16'hD0)
                        next_state = ERASE_BUSY;
                    else
                        next_state = READY;
                end
            end

            ERASE_BUSY :
            begin
                if ((abort ||
                (ParameterErase_out_event && ~ParameterErase_out) ||
                (falling_edge_MainErase_out ) ) && ~suspended_erase)
                    next_state = READY;
                else if (falling_edge_EraseSuspend_out)
                    next_state = ERS_SUSP;
            end

            ERS_SUSP :
            begin
                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'h10, 16'h40: next_state = PROG_SETUP_ERS_SUSP;
                        16'hE8 : next_state = BP_SETUP_ERS_SUSP;
                        16'hD0: next_state = ERASE_BUSY;
                        16'h60: next_state = LOCK_SETUP_ERS_SUSP;
                        default: next_state = current_state;
                    endcase
                end
            end

            PROG_SETUP_ERS_SUSP :
            begin
                if (rising_edge_Write)
                    next_state = PROG_BUSY_ERS_SUSP;
            end

            PROG_BUSY_ERS_SUSP :
            begin
                if (abort ||
                (WordProgram_out_event && ~WordProgram_out) )
                    next_state = ERS_SUSP;
                else if (ProgramSuspend_out_event && ~ProgramSuspend_out)
                    next_state = PROG_SUSP_ERS_SUSP;
            end

            PROG_SUSP_ERS_SUSP :
            begin
                if (rising_edge_Write && LatchedData == 16'hD0)
                    next_state = PROG_BUSY_ERS_SUSP;
            end

            BP_SETUP_ERS_SUSP :
            begin
                if (rising_edge_Write)
                begin
                    word_cnt = LatchedData + 1;
                    next_state = BP_LOAD_ERS_SUSP;
                end
            end

            BP_LOAD_ERS_SUSP :
            begin
                if (rising_edge_Write)
                begin
                    word_cnt = word_cnt - 1;
                    if (word_cnt == 0)
                        next_state = BP_CONFIRM_ERS_SUSP;
                end
            end

            BP_CONFIRM_ERS_SUSP :
            begin
                if (rising_edge_Write)
                begin
                    if (LatchedData == 16'hD0)
                        next_state = BP_BUSY_ERS_SUSP;
                    else
                        next_state = ERS_SUSP;
                end
            end

            BP_BUSY_ERS_SUSP :
            begin
                if (abort ||
                (BuffProgram_out_event && ~BuffProgram_out && ~ExtendProgTime))
                    next_state = ERS_SUSP;
                else if (ProgramSuspend_out_event && ~ProgramSuspend_out)
                    next_state = BP_SUSP_ERS_SUSP;
                else if (ExtendProgTime_event)
                    next_state = current_state;
            end

            BP_SUSP_ERS_SUSP :
            begin
                if (rising_edge_Write && LatchedData == 16'hD0)
                    next_state = BP_BUSY_ERS_SUSP;
            end

            LOCK_SETUP_ERS_SUSP :
            begin
                if (rising_edge_Write)
                    next_state = ERS_SUSP;
            end

            BEFP_SETUP :
            begin
                if (rising_edge_Write)
                begin
                    if (LatchedData != 16'hD0)
                        next_state = READY;
                    else
                    begin
                        BEFP_block2 = BlockNumber(LatchedAddr);
                        word_cnt = 32;
                    end
                end
                else if (falling_edge_BEFPsetup_out)
                begin
                    if (SR[4] == 1'b0)
                        next_state = BEFP_LOAD;
                    else
                        next_state = READY;
                end
            end

            BEFP_LOAD :
            begin
                if (rising_edge_Write)
                begin
                    if ((BlockNumber(LatchedAddr) != BEFP_block2) &&
                    LatchedData == 16'hFFFF)
                        next_state = READY;
                    else
                    begin
                        word_cnt = word_cnt - 1;
                        if (word_cnt == 0)
                            next_state = BEFP_BUSY;
                    end
                end
            end

            BEFP_BUSY :
            begin
                if (falling_edge_BEFP_out)
                begin
                    word_cnt = 32;
                    next_state = BEFP_LOAD;
                end
            end
            endcase
        end
    end

    ////////////////////////////////////////////////////////////////////////////
    // Functional
    ////////////////////////////////////////////////////////////////////////////
    always @(rising_edge_Write or WordProgram_out_event or
             BuffProgram_out_event or falling_edge_RSTNeg or
             ParameterErase_out_event or falling_edge_MainErase_out or
             falling_edge_BEFPsetup_out or falling_edge_BEFP_out or
             abort or falling_edge_EraseSuspend_out or ProgramSuspend_out_event)
    begin

        if (rising_edge_Write)
        begin
            if ((current_state != RESET_POWER_DOWN) &&
            (current_state != OTP_BUSY) &&
            (current_state != PROG_BUSY) &&
            (current_state != BP_BUSY) &&
            (current_state != ERASE_BUSY) &&
            (current_state != PROG_BUSY_ERS_SUSP) &&
            (current_state != BP_BUSY_ERS_SUSP) &&
            (current_state != BEFP_SETUP) &&
            (current_state != BEFP_LOAD) &&
            (LatchedData == 8'h50))
                SR = 8'b10000000;
        end

        case (current_state)

            RESET_POWER_DOWN :
            begin
                SR = 8'b10000000;
                for (i=0;i<=BlockNum;i=i+1)
                begin
                    Block_Lock[i] = LOCKED;
                    BlockLockBit[i] = 1'b1;
                    BlockLockDownBit[i] = 1'b0;
                end
                read_state = READ_ARRAY;
                RCR = 16'b1011111111001111;
            end

            READY :
            begin
                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70 : read_state = READ_STATUS;
                        16'h90 : read_state = READ_ID;
                        16'h98 : read_state = READ_QUERY;
                    endcase
                end
            end

            LOCK_SETUP, LOCK_SETUP_ERS_SUSP :
            begin
                if (rising_edge_Write)
                begin
                    block_number = BlockNumber(LatchedAddr);
                    if (LatchedData == 16'h03)
                    begin
                        RCR = A[15:0];
                        read_state = READ_ARRAY;
                    end
                    else if (LatchedData == 16'h01)
                    begin
                        read_state = READ_STATUS;
                        if (Block_Lock[block_number] == UNLOCKED)
                            Block_Lock[block_number] = LOCKED;
                        BlockLockBit[block_number] = 1'b1;
                    end
                    else if (LatchedData == 16'hD0)
                    begin
                        read_state = READ_STATUS;
                        if (!( (Block_Lock[block_number] == LOCKED_DOWN) &&
                        WPNeg == 1'b0) )
                        begin
                            Block_Lock[block_number] = UNLOCKED;
                            BlockLockBit[block_number] = 0;
                        end
                    end
                    else if (LatchedData == 16'h2F)
                    begin
                        read_state = READ_STATUS;
                        Block_Lock[block_number] = LOCKED_DOWN;
                        BlockLockBit[block_number] = 1'b1;
                        BlockLockDownBit[block_number] = 1'b1;
                    end
                    else
                    begin
                        read_state = READ_STATUS;
                        SR[4] = 1'b1;
                        SR[5] = 1'b1;
                    end
                end
                else
                    read_state = READ_STATUS;
            end

            OTP_SETUP :
            begin
                read_state = READ_STATUS;
                if (rising_edge_Write)
                begin
                    DataBuff[0] = LatchedData;
                    AddrBuff[0] = LatchedAddr;
                    WordProgram_in = 1'b1;
                    WordProgram_in <= #1 1'b0;
                end
            end

            OTP_BUSY :
            begin
                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70, 16'h90, 16'h98 : read_state = READ_STATUS;
                    endcase
                end

                mem_bits = PR[9'h80];
                prog_bits = PR[9'h89];

                if (VPP != 1'b1)
                begin
                    SR[3] = 1'b1;
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if ((AddrBuff[0] < 9'h80) || (AddrBuff[0] > 9'h109))
                begin
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if ((AddrBuff[0] > 9'h80) && (AddrBuff[0] < 9'h85))
                begin
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if ((AddrBuff[0] > 9'h84) && (AddrBuff[0] < 9'h89) &&
                (mem_bits[1] != 1'b1))
                begin
                    SR[1] = 1'b1;
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if ((AddrBuff[0] > 9'h89) && (AddrBuff[0] < 9'h10A) &&
                (prog_bits[(AddrBuff[0]-9'h8A)/8] != 1'b1))
                begin
                    SR[1] = 1'b1;
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else
                    SR[7] = 1'b0;

                if (falling_edge_RSTNeg)
                    PR[AddrBuff[0]] = -1;

                if (WordProgram_out_event && ~WordProgram_out && ~abort)
                begin
                    if (PR[AddrBuff[0]] > -1)
                    begin
                        prog_bits = DataBuff[0];
                        mem_bits = PR[AddrBuff[0]];
                        for (i=0; i<= 15; i=i+1)
                        begin
                            if (prog_bits[i] == 0)
                                mem_bits[i] = 0;
                        end
                        PR[AddrBuff[0]] = mem_bits;
                    end
                    SR[7] = 1;
                end
            end

            PROG_SETUP, PROG_SETUP_ERS_SUSP :
            begin
                read_state = READ_STATUS;
                if (rising_edge_Write)
                begin
                    DataBuff[0] = LatchedData;
                    AddrBuff[0] = LatchedAddr;
                    WordProgram_in = 1;
                    WordProgram_in <= #1 0;
                end
            end

            PROG_BUSY, PROG_BUSY_ERS_SUSP :
            begin
                SR[2] = 0;
                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70 : read_state = READ_STATUS;
                        16'h90 : read_state = READ_ID;
                        16'h98 : read_state = READ_QUERY;
                        16'hB0 :
                        begin
                            ProgramSuspend_in = 1'b1;
                            ProgramSuspend_in <= #1 1'b0;
                        end
                    endcase
                end

                block_number = BlockNumber(AddrBuff[0]);

                if (VPP == 1'b0)
                begin
                    SR[3] = 1'b1;
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if (OTP[block_number] == 1'b1)
                begin
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if (Block_Lock[block_number] != UNLOCKED)
                begin
                    SR[1] = 1'b1;
                    SR[4] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else
                    SR[7] = 1'b0;

                if (falling_edge_RSTNeg )
                    MemData[AddrBuff[0]] = -1;

                if (WordProgram_out_event && ~WordProgram_out && ~abort)
                begin
                    if (MemData[AddrBuff[0]] > -1 )
                    begin
                        prog_bits = DataBuff[0];
                        mem_bits = MemData[AddrBuff[0]];
                        for (i= 0; i<= 15; i=i+1)
                            if (prog_bits[i] == 0)
                                mem_bits[i] = 0;
                        MemData[AddrBuff[0]] = mem_bits;
                    end
                    SR[7] = 1;
                end
            end

            PROG_SUSP, PROG_SUSP_ERS_SUSP :
            begin
                SR[2] = 1'b1;
                SR[7] = 1'b1;

                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70 : read_state = READ_STATUS;
                        16'h90 : read_state = READ_ID;
                        16'h98 : read_state = READ_QUERY;
                        16'hD0 :
                        begin
                            WordProgramResume = 1'b1;
                            WordProgramResume <= #1 1'b0;
                        end
                    endcase
                end
            end

            BP_SETUP, BP_SETUP_ERS_SUSP :
            begin
                read_state = READ_STATUS;

                if (rising_edge_Write)
                begin
                    word_number = LatchedData;
                    word_cntr   = 0;
                end
            end

            BP_LOAD, BP_LOAD_ERS_SUSP :
            begin
                read_state = READ_STATUS;

                if (rising_edge_Write)
                begin
                    DataBuff[word_cntr] = LatchedData;
                    AddrBuff[word_cntr] = LatchedAddr;
                    if (word_cntr == 0)
                    begin
                        lowest_addr = LatchedAddr;
                        highest_addr = LatchedAddr;
                    end
                    else
                    begin
                        if (LatchedAddr < lowest_addr)
                            lowest_addr = LatchedAddr;
                        if (LatchedAddr > highest_addr)
                            highest_addr = LatchedAddr;
                    end
                    word_cntr = word_cntr + 1;
                end
            end

            BP_CONFIRM, BP_CONFIRM_ERS_SUSP :
            begin
                read_state = READ_STATUS;

                if (rising_edge_Write)
                begin
                    if (LatchedData != 16'hD0)
                    begin
                        SR[7] = 1'b1;
                        SR[5] = 1'b1;
                        SR[4] = 1'b1;
                    end
                    else if (LatchedData == 16'hD0)
                    begin
                        BuffProgram_in = 1;
                        BuffProgram_in <= #1 0;
                    end
                end
            end

            BP_BUSY, BP_BUSY_ERS_SUSP :
            begin
                SR[2] = 0;
                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70 : read_state = READ_STATUS;
                        16'h90 : read_state = READ_ID;
                        16'h98 : read_state = READ_QUERY;
                        16'hB0 :
                        begin
                            suspended_bp = 1'b1;
                            ProgramSuspend_in = 1'b1;
                            ProgramSuspend_in <= #1 1'b0;
                        end
                    endcase
                end

                block_number = BlockNumber(AddrBuff[0]);

                if (VPP == 0)
                begin
                    SR[3] = 1;
                    SR[4] = 1;
                    SR[7] = 1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if (OTP[block_number] == 1)
                begin
                    SR[4] = 1;
                    SR[7] = 1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if (Block_Lock[block_number] != UNLOCKED)
                begin
                    SR[1] = 1;
                    SR[4] = 1;
                    SR[7] = 1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if ((lowest_addr < AddrBuff[0]) ||
                (highest_addr > (AddrBuff[0]+word_number)) &&
                (word_number != -1))
                begin
                    SR[4] = 1;
                    SR[7] = 1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else if (BlockNumber(highest_addr) != block_number)
                begin
                    SR[4] = 1;
                    SR[5] = 1;
                    SR[7] = 1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                end
                else
                    SR[7] = 0;

                if (falling_edge_RSTNeg)
                begin
                    for (j=0;j<=word_number; j=j+1)
                        MemData[AddrBuff[j]] = -1;
                end

                if ( BuffProgram_out_event && ~BuffProgram_out
                && ~suspended_bp && ~abort )
                begin
                    for (j=0; j<= word_number; j=j+1)
                    begin
                        if (MemData[AddrBuff[j]] > -1 )
                        begin
                            prog_bits = DataBuff[j];
                            mem_bits = MemData[AddrBuff[j]];
                            for (i=0; i<=15; i=i+1)
                            begin
                                if (prog_bits[i] == 1'b0)
                                    mem_bits[i] = 1'b0;
                            end
                            MemData[AddrBuff[j]] = mem_bits;
                        end
                    end
                    for (j=0; j<= word_number; j=j+1)
                    begin
                        if ((AddrBuff[j] / 32) != (AddrBuff[0]/32))
                        begin
                            ExtendProgTime = 1;
                            ExtendProgTime <= #1 0;
                            word_number = -1;
                            BuffProgram_in = 1'b1;
                            BuffProgram_in <= #1 1'b0;
                        end
                    end
                    SR[7] = 1;
                end
            end

            BP_SUSP, BP_SUSP_ERS_SUSP :
            begin
                SR[2] = 1'b1;
                SR[7] = 1'b1;

                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70 : read_state = READ_STATUS;
                        16'h90 : read_state = READ_ID;
                        16'h98 : read_state = READ_QUERY;
                        16'hD0 :
                        begin
                            suspended_bp = 1'b0;
                            BP_ProgramResume = 1'b1;
                            BP_ProgramResume <= #1 1'b0;
                        end
                    endcase
                end
            end

            ERASE_SETUP :
            begin
                read_state = READ_STATUS;

                if (rising_edge_Write)
                begin
                    if (LatchedData == 16'hD0)
                    begin
                        erasing_block = BlockNumber(LatchedAddr);
                        if (BlockSize(erasing_block) == ParameterBlockSize)
                        begin
                            ParameterErase_in = 1;
                            ParameterErase_in <= #1 0;
                        end
                        else
                        begin
                            MainErase_in = 1;
                            MainErase_in <= #1 0;
                        end
                    end
                    else
                    begin
                        SR[7] = 1'b1;
                        SR[5] = 1'b1;
                        SR[4] = 1'b1;
                    end
                end
            end

            ERASE_BUSY :
            begin
                SR[6] = 0;

                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70 : read_state = READ_STATUS;
                        16'h90 : read_state = READ_ID;
                        16'h98 : read_state = READ_QUERY;
                        16'hB0 :
                        begin
                            suspended_erase = 1'b1;
                            EraseSuspend_in = 1'b1;
                            EraseSuspend_in <= #1 1'b0;
                        end
                    endcase
                end

                aborted = 1'b0;

                if (VPP == 1'b0)
                begin
                    SR[3] = 1'b1;
                    SR[5] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                    aborted = 1'b1;
                end
                else if (OTP[erasing_block] == 1'b1)
                begin
                    SR[5] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                    aborted = 1'b1;
                end
                else if (Block_Lock[erasing_block] != UNLOCKED)
                begin
                    SR[1] = 1'b1;
                    SR[5] = 1'b1;
                    SR[7] = 1'b1;
                    abort = 1'b1;
                    abort <= #1 1'b0;
                    aborted = 1'b1;
                end
                else
                    SR[7] = 1'b0;

                block_size = BlockSize(erasing_block);
                start_addr = StartBlockAddr(erasing_block);

                if (~aborted)
                begin
                    for (i = 0; i< block_size; i=i+1 )
                        MemData[start_addr + i] = -1;
                end

                if ( ( (ParameterErase_out_event && ~ParameterErase_out)
                || (falling_edge_MainErase_out)) && ~abort && ~suspended_erase)
                begin
                    SR[7] = 1'b1;
                    for (i=0;i<=block_size;i=i+1)
                        MemData[start_addr + i] = MaxData;
                end
            end

            ERS_SUSP :
            begin
                SR[6] = 1'b1;
                SR[7] = 1'b1;

                if (rising_edge_Write)
                begin
                    case (LatchedData)
                        16'hFF : read_state = READ_ARRAY;
                        16'h70 : read_state = READ_STATUS;
                        16'h90 : read_state = READ_ID;
                        16'h98 : read_state = READ_QUERY;
                        16'hD0 :
                        begin
                            suspended_erase = 1'b0;
                            if (BlockSize(erasing_block) == ParameterBlockSize)
                            begin
                                ParameterEraseResume = 1'b1;
                                ParameterEraseResume <= #1 1'b0;
                            end
                            else
                            begin
                                MainEraseResume = 1'b1;
                                MainEraseResume <= #1 1'b0;
                            end
                        end
                    endcase
                end
            end

            BEFP_SETUP :
            begin
                read_state = READ_STATUS;

                if (rising_edge_Write && (LatchedData == 16'hD0))
                begin
                    BEFP_addr  = LatchedAddr;
                    BEFP_block = BlockNumber(LatchedAddr);
                    word_cntr = 0;
                    if ((VPP != 1'b1) || (VPP_voltage != 9))
                    begin
                        SR[3] = 1'b1;
                        SR[4] = 1'b1;
                    end
                    if (Block_Lock[BEFP_block] != UNLOCKED)
                    begin
                        SR[1] = 1'b1;
                        SR[4] = 1'b1;
                    end
                    else if (((BEFP_addr % 32) != 0) ||
                    (OTP[BEFP_block] == 1'b1))
                        SR[4] = 1'b1;
                    BEFPsetup_in = 1'b1;
                    BEFPsetup_in <= #1 1'b0;
                end
                else if (falling_edge_BEFPsetup_out)
                begin
                    if (SR[4] == 0)
                    begin
                        SR[7] = 0;
                        SR[0] = 0;
                    end
                end
            end

            BEFP_LOAD :
            begin
                if (rising_edge_Write)
                begin
                    if ((BlockNumber(LatchedAddr) != BEFP_block) &&
                    (LatchedData == 16'hFFFF))
                    begin
                        SR[7] = 1'b1;
                        SR[0] = 1'b0;
                    end
                    else
                    begin
                        DataBuff[word_cntr] = LatchedData;
                        word_cntr = word_cntr + 1;
                        if (word_cntr == 31)
                        begin
                            BEFP_in = 1'b1;
                            BEFP_in <= #1 1'b0;
                        end
                    end
                end
            end

            BEFP_BUSY :
            begin

                if (falling_edge_RSTNeg)
                begin
                    for (j = 0 ; j<= 31; j=j+1)
                        MemData[BEFP_addr+j] = -1;
                end

                if (falling_edge_BEFP_out)
                begin
                    for (j=0;j<=31;j=j+1)
                    begin
                        if (MemData[BEFP_addr+j] > -1)
                        begin
                            prog_bits = DataBuff[j];
                            mem_bits  = MemData[BEFP_addr + j];
                            for (i=0;i<=15;i=i+1)
                            begin
                                if (prog_bits[i] == 1'b0)
                                    mem_bits[i] = 1'b0;
                            end
                            MemData[BEFP_addr + j] = mem_bits;
                        end
                    end
                    BEFP_addr = BEFP_addr + 32;
                    if ((BEFP_addr > MemSize) ||
                    (BlockNumber(BEFP_addr) > BEFP_block))
                        BEFP_addr = BEFP_addr - BlockSize(BEFP_block);
                    SR[0] = 1'b0;
                    word_cntr = 0;
                end
                else
                    SR[0] = 1'b1;
            end

        endcase
    end

    ///////////////////////////////////////////////////////////
    // Combinatorial output generation
    ///////////////////////////////////////////////////////////
    always @(Ahigh_event or Alow_event or rising_edge_Read or
        A_event or OENeg or falling_edge_Read or CENeg
        )
    begin : Output
        case (read_state)
            READ_ARRAY :
            begin
                if (RCR[15] == 1'b1)
                begin
                    if (Ahigh_event && ~ADVNeg)
                        ReadAddr = A;
                    else if (Alow_event)
                        ReadAddr = ReadAddr - (ReadAddr % 4) + A[1:0];
                end

                if (current_state == PROG_BUSY ||
                current_state == PROG_BUSY_ERS_SUSP ||
                current_state == BP_BUSY ||
                current_state == BP_BUSY_ERS_SUSP ||
                current_state == ERASE_BUSY)
                    DQOut_tmp = 16'bx;
                else
                begin
                    if (MemData[ReadAddr] > -1)
                        DQOut_tmp = MemData[ReadAddr];
                    else
                        DQOut_tmp = 16'bx;
                end
            end

            READ_ID :
            begin
                if ((((ReadAddr-2) % MainBlockSize) == 0) ||
                ((ReadAddr < MainBlockSize) &&
                (((ReadAddr-2) % ParameterBlockSize) == 0)))
                begin
                    DQOut_tmp[0] = BlockLockBit[BlockNumber(ReadAddr)];
                    DQOut_tmp[1] = BlockLockDownBit[BlockNumber(ReadAddr)];
                    DQOut_tmp[15:2] = 14'b0;
                end
                else if (ReadAddr == 0)
                    DQOut_tmp = 16'h0089;
                else if (ReadAddr == 1)
                begin
                    DQOut_tmp = DeviceID_B;
                end
                else if (ReadAddr == 5)
                    DQOut_tmp = RCR;
                else if ((ReadAddr >= 9'h80) && (ReadAddr <= 9'h109))
                begin
                    if (PR[ReadAddr] > -1)
                        DQOut_tmp = PR[ReadAddr];
                    else
                        DQOut_tmp = 16'bx;
                end
            end

            READ_QUERY :
            begin
                if (((ReadAddr >= 9'h10) && (ReadAddr <= 9'h38)) ||
                ((ReadAddr >= 9'h10A) && (ReadAddr <= 9'h156)))
                    DQOut_tmp = CFI_array[ReadAddr];
                else
                    DQOut_tmp = 16'b0;
            end

            READ_STATUS :
            begin
                DQOut_tmp[15:8] = 8'b0;
                DQOut_tmp[7:0] = SR;
            end
        endcase

        if (RCR[15] == 1'b1) // Asynchronous read
        begin
            if (rising_edge_Read || (Read && ((A_event && ~ADVNeg) ||
            Alow_event)))
                DQOut_zd = DQOut_tmp;
            else if (falling_edge_Read)
                DQOut_zd = 16'bz;
        end
        else // Burst read
        begin
            if (rising_edge_Read || falling_edge_Read)
            begin
                if ((burst_cntr > BurstLength) && (BurstLength != 0))
                    read_out = 1'b0;
                else if (read_state == READ_ARRAY)
                begin
                    if ((RCR[9] == 1'b0) && (RCR[13:11] > 4) &&
                    ((burst_cntr >= 5) || (burst_cntr < 1)))
                    begin
                        read_out = 1'b0;
                        if (burst_cntr >= 5)
                            burst_cntr = 5 - RCR[13:11];
                    end
                    else
                    begin
                        read_out = 1'b1;
                        if (ReadAddr < MemSize)
                            ReadAddr = ReadAddr + 1;
                        if ((RCR[3] == 1'b0) && (BurstLength != 0) &&
                        ((ReadAddr % BurstLength) == 0))
                            ReadAddr = ReadAddr - BurstLength;
                    end
                end
                else
                    read_out = 1'b1;

                if (read_out)
                begin
                    DQOut_zd = DQOut_tmp;
                end
            end
        end
    end

    always @(CENeg, OENeg)
    begin : OutputDisable
        if ((CENeg) || (OENeg))
            DQOut_zd = 16'bz;
        else if ((~CENeg) && (~OENeg) && (RCR[15] == 1'b0))
            DQOut_zd = 16'bx;
    end

    ////////////////////////////////////////////////////////////////
    // WAIT output control process
    ////////////////////////////////////////////////////////////////
    always @(AssertWAITOut_event or DeassertWAITOut_event or falling_edge_OENeg
    or OENeg or CENeg or falling_edge_CENeg)
    begin : WAITOut_control

        if (OENeg || CENeg || ~RSTNeg || (current_state == RESET_POWER_DOWN))
            WAITOut_zd = 1'bz;
        else if ((falling_edge_OENeg && ~CENeg) ||
        (falling_edge_CENeg && ~OENeg))
        begin
            if (RCR[15] == 1'b1)
            begin
                if (~RCR[10])
                    WAITOut_zd = 1'b1;
                else
                    WAITOut_zd = 1'b0;
            end
            else
            begin
                if (~RCR[10])
                    WAITOut_zd = 1'b0;
                else
                    WAITOut_zd = 1'b1;
            end
        end
        else if (AssertWAITOut_event)
        begin
            if (~RCR[10])
                WAITOut_zd = 1'b0;
            else
                WAITOut_zd = 1'b1;
        end
        else if (DeassertWAITOut_event)
        begin
            if (~RCR[10])
                WAITOut_zd = 1'b1;
            else
                WAITOut_zd = 1'b0;
        end
    end

    ///////////////////////////////////////////////////////////////////
    // Timing control for erase start, suspend and resume
    ///////////////////////////////////////////////////////////////////
    always @(rising_edge_MainErase_in or rising_edge_ParameterErase_in or
             RstDuringErsPrg_out_event or
             abort_event or
             rising_edge_ParameterEraseResume or EraseSuspend_event or
             rising_edge_MainEraseResume )
    begin : erase_time
        merase_duration = tdevice_EraseMain;
        perase_duration = tdevice_EraseParameter;

        if (rising_edge_MainErase_in)
        begin
            melapsed = 0;
            MainErase_out <= #1 1'b1;
            ->merase_event;
            mstart = $time;
        end
        if (rising_edge_ParameterErase_in)
        begin
            pelapsed = 0;
            ParameterErase_out <= #1 1'b1;
            ->perase_event;
            pstart = $time;
        end
        if ((RstDuringErsPrg_out_event && ~RstDuringErsPrg_out) ||
        abort_event)
        begin
            disable merase_process;
            disable perase_process;
            MainErase_out = 1'b0;
            ParameterErase_out = 1'b0;
        end

        if (EraseSuspend_event && ~EraseSuspend_out)
        begin
            disable merase_process;
            melapsed = $time - mstart;
            merase_duration = merase_duration - melapsed;
            disable perase_process;
            pelapsed = $time - pstart;
            perase_duration = perase_duration - pelapsed;
        end
        if (rising_edge_MainEraseResume)
        begin
            mstart = $time;
            MainErase_out = 1'b1;
            -> merase_event;
        end
        if (rising_edge_ParameterEraseResume)
        begin
            pstart = $time;
            ParameterErase_out = 1'b1;
            ->perase_event;
        end
    end

    always @(merase_event)
    begin : merase_process
        #merase_duration MainErase_out = 1'b0;
    end
    always @(perase_event)
    begin : perase_process
        #perase_duration ParameterErase_out = 1'b0;
    end

    /////////////////////////////////////////////////////////////////
    // Timing control for programming start, suspend and resume
    /////////////////////////////////////////////////////////////////
    time buffp_duration;
    time wordp_duration;
    time welapsed;
    time elapsed;
    event prog_event;
    event buffp_event;
    time wstart;
    time start;
    reg rising_edge_WordProgram_in = 1'b0;
    reg rising_edge_BuffProgram_in = 1'b0;
    reg rising_edge_WordProgramResume = 1'b0;
    reg rising_edge_BP_ProgramResume = 1'b0;

    always @(rising_edge_WordProgram_in or rising_edge_BuffProgram_in or
             RstDuringErsPrg_out_event or
             abort_event or
             ProgramSuspend_out_event or rising_edge_WordProgramResume or
             rising_edge_BP_ProgramResume)
    begin
        if (VPP_voltage != 9)
        begin
            buffp_duration = tdevice_BuffProgram;
            wordp_duration = tdevice_WordProgram;
        end
        else
        begin
            buffp_duration = tdevice_BuffProgram9V;
            wordp_duration = tdevice_WordProgram9V;
        end

        if (rising_edge_WordProgram_in)
        begin
            welapsed = 0;
            WordProgram_out <= #1 1'b1;
            -> prog_event;
            wstart = $time;
        end
        if (rising_edge_BuffProgram_in)
        begin
            elapsed = 0;
            BuffProgram_out = 1'b1;
            -> buffp_event;
            start = $time;
        end
        if ((RstDuringErsPrg_out_event && ~RstDuringErsPrg_out) ||
        abort_event)
        begin
            disable prog_process;
            disable buffp_process;
            WordProgram_out = 1'b0;
            BuffProgram_out = 1'b0;
        end

        if (ProgramSuspend_out_event && ~ProgramSuspend_out)
        begin
            disable prog_process;
            disable buffp_process;
            elapsed = $time - start;
            welapsed = $time - wstart;
            buffp_duration = buffp_duration - elapsed;
            wordp_duration = wordp_duration - welapsed;
        end
        if (rising_edge_WordProgramResume)
        begin
            wstart = $time;
            WordProgram_out = 1'b1;
            -> prog_event;
        end
        if (rising_edge_BP_ProgramResume)
        begin
            start = $time;
            BuffProgram_out = 1'b1;
            -> buffp_event;
        end
    end

    always @(prog_event)
    begin : prog_process
        #wordp_duration WordProgram_out = 1'b0;
    end
    always @(buffp_event)
    begin : buffp_process
        #buffp_duration BuffProgram_out = 1'b0;
    end

    ////////////////////////////////////////////////////////////////////
    //Output timing control
    ////////////////////////////////////////////////////////////////////
    always @(DQOut_zd)
    begin : OutputGen
        if (DQOut_zd[0] !== 1'bz)
        begin
            CEDQ_t = CENeg_event  + CEDQ_01;
            OEDQ_t = OENeg_event  + OEDQ_01;
            ADDRDQ_t = ADDR_event + ADDRDQIN_01;
            if (Pmode)
                ADDRDQ_t = ADDR_event + ADDRDQPAGE_01;

            FROMCE = ((CEDQ_t >= OEDQ_t) && (CEDQ_t >= $time));
            FROMOE = ((OEDQ_t >= CEDQ_t) && (OEDQ_t >= $time));
            FROMADDR = 1'b1;

            DQOut_Pass = DQOut_zd;
        end
    end

    always @(DQOut_zd)
    begin
        if (DQOut_zd[0] === 1'bz)
        begin
            disable OutputGen;
            FROMCE = 1'b1;
            FROMOE = 1'b1;
            FROMADDR = 1'b0;
            DQOut_Pass = DQOut_zd;
        end
    end

    reg  BuffInOE, BuffInCE, BuffInADDRIN, BuffInADDRPAGE;
    wire BuffOutOE, BuffOutCE, BuffOutADDRIN, BuffOutADDRPAGE;

    BUFFER    BUFOE   (BuffOutOE, BuffInOE);
    BUFFER    BUFCE   (BuffOutCE, BuffInCE);
    BUFFER    BUFADDRIN (BuffOutADDRIN, BuffInADDRIN);
    BUFFER    BUFADDRPAGE (BuffOutADDRPAGE, BuffInADDRPAGE);

    initial
    begin
        BuffInOE   = 1'b1;
        BuffInCE   = 1'b1;
        BuffInADDRIN = 1'b1;
        BuffInADDRPAGE = 1'b1;
    end

    always @(posedge BuffOutOE)
    begin
        OEDQ_01 = $time;
    end
    always @(posedge BuffOutCE)
    begin
        CEDQ_01 = $time;
    end
    always @(posedge BuffOutADDRIN)
    begin
        ADDRDQIN_01 = $time;
    end
    always @(posedge BuffOutADDRPAGE)
    begin
        ADDRDQPAGE_01 = $time;
    end

/////////////////////////////////////////////////////////////////////////////
// functions & tasks
/////////////////////////////////////////////////////////////////////////////
    function integer BlockNumber;
        input [HiAddrBit:0] ADDR;
        integer block_number;
    begin
        block_number = ADDR / MainBlockSize;
        if (block_number == 0)
            block_number = block_number +
                (ADDR % MainBlockSize) / ParameterBlockSize;
        else
            block_number = block_number +
                MainBlockSize / ParameterBlockSize - 1;
        BlockNumber = block_number;
    end
    endfunction

    function integer StartBlockAddr;
        input [16:0] block_number;
        integer start_block_addr;
    begin
        if (block_number < 4)
            start_block_addr = block_number * ParameterBlockSize;
        else
            start_block_addr = (block_number - 3) * MainBlockSize;
        StartBlockAddr = start_block_addr;
    end
    endfunction

    function integer BlockSize;
        input [16:0] block_number;
        integer block_number;
        integer block_size;
    begin
        if ((block_number < 4) ||
        (block_number > (BlockNum - 4) ))
            block_size = ParameterBlockSize;
        else
            block_size = MainBlockSize;
        BlockSize = block_size;
    end
    endfunction

    ////////////////////////////////////////////////////////////////
    // edge controll processes
    ////////////////////////////////////////////////////////////////
    always @(negedge ADVNeg)
    begin
        falling_edge_ADVNeg = 1;
        #1 falling_edge_ADVNeg = 0;
    end

    always @(posedge ADVNeg)
    begin
        rising_edge_ADVNeg  = 1;
        #1 rising_edge_ADVNeg = 0;
    end

    always @(posedge CLOCK)
    begin
        rising_edge_CLOCK = 1;
        #1 rising_edge_CLOCK = 0;
    end

    always @(negedge RSTNeg)
    begin
        falling_edge_RSTNeg = 1;
        #1 falling_edge_RSTNeg = 0;
    end

    always @(posedge RSTNeg)
    begin
        rising_edge_RSTNeg = 1;
        #1 rising_edge_RSTNeg = 0;
    end

    always @(posedge Write)
    begin
        rising_edge_Write = 1;
        #1 rising_edge_Write = 0;
    end

    always @(RstDuringErsPrg_out)
    begin
        RstDuringErsPrg_out_event = 1;
        #1 RstDuringErsPrg_out_event = 0;
    end

    always @(WordProgram_out)
    begin
        WordProgram_out_event = 1;
        #1 WordProgram_out_event = 0;
    end

    always @(ProgramSuspend_out)
    begin
        ProgramSuspend_out_event = 1;
        #1 ProgramSuspend_out_event = 0;
    end

    always @(BuffProgram_out)
    begin
        if (~suspended_bp)
        begin
            BuffProgram_out_event = 1;
            #1 BuffProgram_out_event = 0;
        end
    end

    always @(posedge ExtendProgTime)
    begin
        ExtendProgTime_event = 1;
        #1 ExtendProgTime_event = 0;
    end

    always @(ParameterErase_out)
    begin
        ParameterErase_out_event = 1;
        #1 ParameterErase_out_event = 0;
    end

    always @(negedge MainErase_out)
    begin
        falling_edge_MainErase_out = 1;
        #1 falling_edge_MainErase_out = 0;
    end

    always @(negedge EraseSuspend_out)
    begin
        falling_edge_EraseSuspend_out = 1;
        #1 falling_edge_EraseSuspend_out = 0;
    end

    always @(negedge BEFPsetup_out)
    begin
        falling_edge_BEFPsetup_out = 1;
        #1 falling_edge_BEFPsetup_out = 0;
    end

    always @(negedge BEFP_out)
    begin
        falling_edge_BEFP_out = 1;
        #1 falling_edge_BEFP_out = 0;
    end

    always @(A[HiAddrBit:2])
    begin
        Ahigh_event = 1;
        #1 Ahigh_event = 0;
    end

    always @(A[1:0])
    begin
        Alow_event = 1;
        #1 Alow_event = 0;
    end

    always @(A)
    begin
        A_event = 1;
        #1 A_event = 0;
    end

    always @(posedge Read)
    begin
        rising_edge_Read = 1;
        #1 rising_edge_Read = 0;
    end

    always @(negedge Read)
    begin
        falling_edge_Read = 1;
        #1 falling_edge_Read = 0;
    end

    always @(posedge CENeg)
    begin
        rising_edge_CENeg = 1;
        #1 rising_edge_CENeg = 0;
    end

    always @(posedge OENeg)
    begin
        rising_edge_OENeg = 1;
        #1 rising_edge_OENeg = 0;
    end

    always @(AssertWAITOut)
    begin
        AssertWAITOut_event = 1;
        #1 AssertWAITOut_event = 0;
    end

    always @(DeassertWAITOut)
    begin
        DeassertWAITOut_event = 1;
        #1 DeassertWAITOut_event = 0;
    end

    always @(negedge OENeg)
    begin
        falling_edge_OENeg = 1;
        #1 falling_edge_OENeg = 0;
    end

    always @(negedge CENeg)
    begin
        falling_edge_CENeg = 1;
        #1 falling_edge_CENeg = 0;
    end

    always @(posedge WENeg)
    begin
        rising_edge_WENeg = 1;
        #1 rising_edge_WENeg = 0;
    end

    always @(posedge WordProgram_in)
    begin
        rising_edge_WordProgram_in = 1'b1;
        #1 rising_edge_WordProgram_in = 1'b0;
    end

    always @(posedge BuffProgram_in)
    begin
        rising_edge_BuffProgram_in = 1'b1;
        #1 rising_edge_BuffProgram_in = 1'b0;
    end

    always @(posedge BP_ProgramResume)
    begin
        rising_edge_BP_ProgramResume = 1'b1;
        #1 rising_edge_BP_ProgramResume = 1'b0;
    end
    always @(posedge WordProgramResume)
    begin
        rising_edge_WordProgramResume = 1'b1;
        #1 rising_edge_WordProgramResume = 1'b0;
    end

    always @(posedge MainErase_in)
    begin
        rising_edge_MainErase_in = 1'b1;
        #1 rising_edge_MainErase_in = 1'b0;
    end

    always @(posedge ParameterErase_in)
    begin
        rising_edge_ParameterErase_in = 1'b1;
        #1 rising_edge_ParameterErase_in = 1'b0;
    end

    always @(posedge MainEraseResume)
    begin
        rising_edge_MainEraseResume = 1'b1;
        #1 rising_edge_MainEraseResume = 1'b0;
    end

    always @(posedge ParameterEraseResume)
    begin
        rising_edge_ParameterEraseResume = 1'b1;
        #1 rising_edge_ParameterEraseResume = 1'b0;
    end

    always @(EraseSuspend_out)
    begin
        EraseSuspend_event = 1'b1;
        #1 EraseSuspend_event = 1'b0;
    end

endmodule

module BUFFER (OUT,IN);
    input IN;
    output OUT;
    buf   (OUT, IN);
endmodule
