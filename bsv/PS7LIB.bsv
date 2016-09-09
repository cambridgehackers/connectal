
// Copyright (c) 2013 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
`include "ConnectalProjectConfig.bsv"
import BuildVector::*;
import Clocks::*;
import DefaultValue::*;
import GetPut::*;
import Connectable::*;
import ConnectableWithTrace::*;
import Bscan::*;
import Vector::*;
import PPS7LIB::*;
import AxiMasterSlave::*;
import AxiDma::*;
import XilinxCells::*;
import ConnectalXilinxCells::*;
import ConnectalClocks::*;
import AxiBits::*;
import AxiGather::*;

(* always_ready, always_enabled *)
interface Bidir#(numeric type data_width);
    method Action             i(Bit#(data_width) v);
    method Bit#(data_width)   o();
    method Bit#(data_width)   t();
endinterface

interface PS7LIB;
`ifdef PS7EXTENDED
    interface Vector#(2, Pps7Emiocan)  can;
    interface Vector#(4, Pps7Dma)  dma;
    interface Vector#(2, Pps7Emioenet) enet;
    interface Pps7Event            event_;
//    interface Vector#(4,Pps7Fclk_clktrig)fclk_clktrig;
//    interface Pps7Fpga             fpga;
    interface Pps7Ftmd             ftmd;
    interface Pps7Ftmt             ftmt;
    interface Pps7Emiopjtag            pjtag;
    interface Vector#(2, Pps7Emiosdio) sdio;
    interface Vector#(2, Pps7Emiospi)  spi;
//    interface Pps7Sram             sram;
    interface Pps7Emiotrace            trace;
    interface Vector#(2, Pps7Emiottc)  ttc;
    interface Vector#(2, Pps7Emiouart) uart;
    interface Vector#(2, Pps7Emiousb)  usb;
    interface Pps7Emiowdt              wdt;
`endif
    interface Pps7Ddr              ddr;
    method Bit#(4)     fclkclk();
    method Action      fclkclktrign(Bit#(4) v);
    method Bit#(4)     fclkresetn();
    method Action      fpgaidlen(Bit#(1) v);
    interface Pps7Emiogpio             gpio;
    interface Vector#(2, Pps7Emioi2c)  i2c;
    interface Pps7Irq              irq;
    interface Inout#(Bit#(54))     mio;
    interface Pps7Ps               ps;

    interface Vector#(2, AxiMasterCommon#(32,32,12)) m_axi_gp;
    interface Vector#(2, AxiSlaveCommon#(32,32,6,Empty)) s_axi_gp;
    interface Vector#(4, AxiSlaveCommon#(32,64,6,HPType)) s_axi_hp;
    interface AxiSlaveCommon#(32,64,3,ACPType) s_axi_acp;
endinterface

module mkPS7LIB#(Clock axi_clock, Reset axi_reset)(PS7LIB);
    PPS7LIB foo <- mkPPS7LIB(
        axi_clock, axi_clock, axi_clock, axi_clock, axi_clock, axi_clock, axi_clock, axi_clock,
        axi_clock, axi_reset, axi_reset, axi_reset, axi_reset, axi_reset, axi_reset, axi_reset,
        axi_reset, axi_reset);
`ifdef PS7EXTENDED
    Vector#(2, Pps7Emiocan)     vcan;
    Vector#(4, Pps7Dma)     vdma;
    Vector#(2, Pps7Emioenet)     venet;
    Vector#(2, Pps7Emiosdio)     vsdio;
    Vector#(2, Pps7Emiospi)     vspi;
    Vector#(2, Pps7Emiottc)     vttc;
    Vector#(2, Pps7Emiouart)     vuart;
    Vector#(2, Pps7Emiousb)     vusb;
`endif
    Vector#(2, Pps7Emioi2c)     vi2c;
    Vector#(2, AxiMasterCommon#(32,32,12)) vtopm_axi_gp;
    Vector#(2, AxiSlaveCommon#(32,32,6,Empty)) vtops_axi_gp;
    Vector#(1, AxiSlaveCommon#(32,64,3,ACPType)) vtops_axi_acp;
    Vector#(4, AxiSlaveCommon#(32,64,6,HPType)) vtops_axi_hp;

`ifdef PS7EXTENDED
    vcan[0] = foo.emiocan0;
    vcan[1] = foo.emiocan1;
    vdma[0] = foo.dma0;
    vdma[1] = foo.dma1;
    vdma[2] = foo.dma2;
    vdma[3] = foo.dma3;
    venet[0] = foo.emioenet0;
    venet[1] = foo.emioenet1;
    vsdio[0] = foo.emiosdio0;
    vsdio[1] = foo.emiosdio1;
    vspi[0] = foo.emiospi0;
    vspi[1] = foo.emiospi1;
    vttc[0] = foo.emiottc0;
    vttc[1] = foo.emiottc1;
    vuart[0] = foo.emiouart0;
    vuart[1] = foo.emiouart1;
    vusb[0] = foo.emiousb0;
    vusb[1] = foo.emiousb1;
`endif
    vi2c[0] = foo.emioi2c0;
    vi2c[1] = foo.emioi2c1;
    vtopm_axi_gp[0] <- mkAxi3MasterGather(foo.maxigp0, clocked_by axi_clock, reset_by axi_reset);
    vtopm_axi_gp[1] <- mkAxi3MasterGather(foo.maxigp1, clocked_by axi_clock, reset_by axi_reset);
    vtops_axi_gp[0] <- mkAxi3SlaveGather(foo.saxigp0, clocked_by axi_clock, reset_by axi_reset);
    vtops_axi_gp[1] <- mkAxi3SlaveGather(foo.saxigp1, clocked_by axi_clock, reset_by axi_reset);
    vtops_axi_acp[0] <- mkAxi3SlaveGather(foo.saxiacp, clocked_by axi_clock, reset_by axi_reset);
    vtops_axi_hp[0] <- mkAxi3SlaveGather(foo.saxihp0, clocked_by axi_clock, reset_by axi_reset);
    vtops_axi_hp[1] <- mkAxi3SlaveGather(foo.saxihp1, clocked_by axi_clock, reset_by axi_reset);
    vtops_axi_hp[2] <- mkAxi3SlaveGather(foo.saxihp2, clocked_by axi_clock, reset_by axi_reset);
    vtops_axi_hp[3] <- mkAxi3SlaveGather(foo.saxihp3, clocked_by axi_clock, reset_by axi_reset);
    Wire#(Bit#(1)) fpgaidlenw <- mkDWire(1);
    rule fpgaidle;
       foo.fpgaidlen(fpgaidlenw);
    endrule
    rule misc;
       foo.emiosramintin(0);
       // UG585 "fclkclktrign is currently not supported and must be tied to ground"
       foo.fclkclktrign(0);
    endrule

`ifdef PS7EXTENDED
    interface Pps7Can can = vcan;
    interface Pps7Dma     dma = vdma;
    interface Pps7Enet     enet = venet;
    interface Pps7Sdio    sdio = vsdio;
    interface Pps7Spi    spi = vspi;
    interface Pps7Ttc    ttc = vttc;
    interface Pps7Uart    uart = vuart;
    interface Pps7Usb    usb = vusb;
    interface Pps7Event     event_ = foo.event_;
//    interface Pps7Fpga     fpga = foo.fpga;
    interface Pps7Ftmd     ftmd = foo.ftmd;
    interface Pps7Ftmt     ftmt = foo.ftmt;
    interface Pps7Pjtag     pjtag = foo.emiopjtag;
//    interface Pps7Sram     sram = foo.sram;
    interface Pps7Emiotrace     trace = foo.emiotrace;
    interface Pps7Wdt     wdt = foo.emiowdt;
`endif
    interface i2c = vi2c;
    interface ddr = foo.ddr;
    interface fclkclk = foo.fclkclk;
    interface fclkresetn = foo.fclkresetn;
    method Action      fclkclktrign(Bit#(4) v);
        foo.fclkclktrign(v);
    endmethod
    method Action      fpgaidlen(Bit#(1) v);
       fpgaidlenw <= v;
    endmethod
    interface gpio = foo.emiogpio;
    interface irq = foo.irq;
    interface mio = foo.mio;
    interface ps = foo.ps;

    interface m_axi_gp = vtopm_axi_gp;
    interface s_axi_gp = vtops_axi_gp;
    interface s_axi_hp = vtops_axi_hp;
    interface s_axi_acp = vtops_axi_acp[0];
endmodule

interface ZynqPins;
    (* prefix="DDR_Addr" *) interface Inout#(Bit#(15))     a;
    (* prefix="DDR_BankAddr" *) interface Inout#(Bit#(3))     ba;
    (* prefix="DDR_CAS_n" *) interface Inout#(Bit#(1))     casb;
    (* prefix="DDR_CKE" *) interface Inout#(Bit#(1))     cke;
    (* prefix="DDR_CS_n" *) interface Inout#(Bit#(1))     csb;
    (* prefix="DDR_Clk_n" *) interface Inout#(Bit#(1))     ckn;
    (* prefix="DDR_Clk_p" *) interface Inout#(Bit#(1))     ck;
    (* prefix="DDR_DM" *) interface Inout#(Bit#(4))     dm;
    (* prefix="DDR_DQ" *) interface Inout#(Bit#(32))     dq;
    (* prefix="DDR_DQS_n" *) interface Inout#(Bit#(4))     dqsn;
    (* prefix="DDR_DQS_p" *) interface Inout#(Bit#(4))     dqs;
    (* prefix="DDR_DRSTB" *) interface Inout#(Bit#(1))     drstb;
    (* prefix="DDR_ODT" *) interface Inout#(Bit#(1))     odt;
    (* prefix="DDR_RAS_n" *) interface Inout#(Bit#(1))     rasb;
    (* prefix="FIXED_IO_ddr_vrn" *) interface Inout#(Bit#(1))     vrn;
    (* prefix="FIXED_IO_ddr_vrp" *) interface Inout#(Bit#(1))     vrp;
    (* prefix="DDR_WEB" *) interface Inout#(Bit#(1))     web;
    (* prefix="MIO" *)
    interface Inout#(Bit#(54))       mio;
    (* prefix="FIXED_IO_ps" *)
    interface Pps7Ps ps;
endinterface

interface PS7;
    (* prefix="" *)
    interface ZynqPins pins;
    interface Vector#(2, AxiMasterCommon#(32,32,12))     m_axi_gp;
    interface Vector#(2, AxiSlaveCommon#(32,32,6,Empty)) s_axi_gp;
    interface Vector#(4, AxiSlaveCommon#(32,64,6,HPType))   s_axi_hp;
    interface Vector#(1, AxiSlaveCommon#(32,64,3,ACPType))   s_axi_acp;
    method Action                             interrupt(Bit#(1) v);
    interface Vector#(4, Clock) fclkclk;
    interface Vector#(4, Reset) fclkreset;
    interface Vector#(2, Pps7Emioi2c)  i2c;
    interface Clock portalClock;
    interface Reset portalReset;
    interface Clock derivedClock;
    interface Reset derivedReset;
`ifdef PS7EXTENDED      
    interface Pps7Emiosdio emiosdio1;   
    interface Pps7Emiospi  emiospi0;
`endif
endinterface

module mkPS7#(Clock axiClock)(PS7);
   // B2C converts a bit to a clock, enabling us to break the apparent cycle
   Vector#(4, B2C) b2c <- replicateM(mkB2C());

   // need the bufg here to reduce clock skew
   module mkBufferedClock#(Integer i)(Clock); let c <- mkClockBUFG(clocked_by b2c[i].c); return c; endmodule
   module mkBufferedReset#(Integer i)(Reset); let r <- mkResetBUFG(clocked_by b2c[i].c, reset_by b2c[i].r); return r; endmodule
   Vector#(4, Clock) fclk <- genWithM(mkBufferedClock);
   Vector#(4, Reset) freset <- genWithM(mkBufferedReset);

`ifndef TOP_SOURCES_PORTAL_CLOCK
   Clock single_clock = fclk[0];
`ifdef ZYNQ_NO_RESET
   freset[0]          = noReset;
`endif
   let single_reset   = freset[0];
`else
   //Clock axiClockBuf <- mkClockBUFG(clocked_by axiClock);
   Clock axiClockBuf = axiClock;
   Clock single_clock = axiClockBuf;
   Reset axiResetUnbuffered <- mkSyncReset(10, freset[0], single_clock);
   Reset axiReset <- mkResetBUFG(clocked_by axiClockBuf, reset_by axiResetUnbuffered);
   let single_reset   = axiReset;
`endif

   ClockGenerator7Params clockParams = defaultValue;
   // input clock 200MHz for speed grade -2, 100MHz for speed grade -1
   // fpll needs to be in the range 600MHz - 1200MHz for either input clock
   //
   // fclkin = 1e9 / mainClockPeriod
   // fpll = 1e9 = mult_f * 1e9 / mainClockPeriod
   // mult_f = mainClockPeriod
   //
   // fclkout0 = 1e9 / divide_f = 1e9 / derivedClockPeriod
   // divide_f = derivedClockPeriod
   //
   clockParams.clkfbout_mult_f       = mainClockPeriod;
   clockParams.clkfbout_phase     = 0.0;
   clockParams.clkfbout_phase     = 0.0;
   clockParams.clkin1_period      = mainClockPeriod;
   clockParams.clkout0_divide_f   = derivedClockPeriod;
   clockParams.clkout0_duty_cycle = 0.5;
   clockParams.clkout0_phase      = 0.0000;
   clockParams.clkout0_buffer     = True;
   clockParams.clkin_buffer = False;
   ClockGenerator7   clockGen <- mkClockGenerator7(clockParams, clocked_by single_clock, reset_by single_reset);
   let derived_clock = clockGen.clkout0;
   let derived_reset_unbuffered <- mkSyncReset(10, single_reset, derived_clock);
   let derived_reset <- mkResetBUFG(clocked_by derived_clock, reset_by derived_reset_unbuffered);

   PS7LIB ps7 <- mkPS7LIB(single_clock, single_reset, clocked_by single_clock, reset_by single_reset);

   // this rule connects the fclkclk wires to the clock net via B2C
   for (Integer i = 0; i < 4; i = i + 1) begin
      ReadOnly#(Bit#(4)) fclkb;
      ReadOnly#(Bit#(4)) fclkresetnb;
      fclkb       <- mkNullCrossingWire(b2c[i].c, ps7.fclkclk);
      fclkresetnb <- mkNullCrossingWire(b2c[i].c, ps7.fclkresetn);
`ifndef BSV_POSITIVE_RESET
      let resetValue = 0;
`else
      let resetValue = 1;
`endif
      rule b2c_rule1;
	 b2c[i].inputclock(fclkb[i]);
	 b2c[i].inputreset(fclkresetnb[i] == 0 ? resetValue : ~resetValue);
      endrule
      rule issue_rule;
         ps7.s_axi_hp[i].extra.rdissuecap1en(0);
         ps7.s_axi_hp[i].extra.wrissuecap1en(0);
      endrule
   end

   IDELAYCTRL idel <- mkIDELAYCTRL(2, clocked_by fclk[3], reset_by freset[0]);

    rule arb_rule;
        ps7.ddr.arb(4'b0);
    endrule

`ifdef PS7EXTENDED         
    interface Pps7Emiosdio emiosdio1 = ps7.sdio[1];
    interface Pps7Emiospi  emiospi0  = ps7.spi[0];
`endif      
    interface ZynqPins pins;
    interface a = ps7.ddr.a;
    interface ba = ps7.ddr.ba;
    interface casb = ps7.ddr.casb;
    interface cke = ps7.ddr.cke;
    interface csb = ps7.ddr.csb;
    interface ckn = ps7.ddr.ckn;
    interface ck = ps7.ddr.ckp;
    interface dm = ps7.ddr.dm;
    interface dq = ps7.ddr.dq;
    interface dqsn = ps7.ddr.dqsn;
    interface dqs = ps7.ddr.dqsp;
    interface drstb = ps7.ddr.drstb;
    interface odt = ps7.ddr.odt;
    interface rasb = ps7.ddr.rasb;
    interface vrn = ps7.ddr.vrn;
    interface vrp = ps7.ddr.vrp;
    interface web = ps7.ddr.web;
    interface mio = ps7.mio;
    interface ps = ps7.ps;
    endinterface
    interface m_axi_gp = ps7.m_axi_gp;
    interface s_axi_gp = ps7.s_axi_gp;
    interface s_axi_hp = ps7.s_axi_hp;
    interface fclkclk = fclk;
    interface fclkreset = freset;
`ifndef TOP_SOURCES_PORTAL_CLOCK
    interface portalClock = fclk[0];
    interface portalReset = freset[0];
`else
    interface portalClock = axiClockBuf;
    interface portalReset = axiReset;
`endif
    interface derivedClock = derived_clock;
    interface derivedReset = derived_reset;
    method Action interrupt(Bit#(1) v);
        ps7.irq.f2p({19'b0, v});
    endmethod
    interface i2c = ps7.i2c;
   interface s_axi_acp = vec(ps7.s_axi_acp);
endmodule
