// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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
import ConnectalConfig::*;
import ConnectalClocks::*;
import Clocks :: *;
import DefaultValue      :: *;
import Vector            :: *;
import Connectable       :: *;
import ConnectableWithTrace::*;
import Portal            :: *;
import ConnectalMemTypes          :: *;
import AxiMasterSlave    :: *;
import XilinxCells       :: *;
import ConnectalXilinxCells   :: *;
import PS8LIB::*;
import ZYNQ_ULTRA::*;
import CtrlMux::*;
import AxiDma            :: *;
import Top               :: *;
import Bscan             :: *;
import HostInterface     :: *;
import Platform          :: *;
`include "ConnectalProjectConfig.bsv"
import `PinTypeInclude::*;

`ifdef XILINX_SYS_CLK
`define SYS_CLK_PARAM #( Clock sys_clk_p, Clock sys_clk_n )
`define SYS_CLK_ARG sys_clk_p, sys_clk_n,
`else
`define SYS_CLK_PARAM
`define SYS_CLK_ARG
`endif

interface I2C_Pins;
   interface Inout#(Bit#(1)) scl;
   interface Inout#(Bit#(1)) sda;
endinterface

(* always_ready, always_enabled *)
interface ZynqUltraTop;
   (* prefix="" *)
   interface ZynqPins zynq;
`ifdef USE_I2C0
   (* prefix="I2C0" *)
   interface I2C_Pins         i2c0;
`endif
`ifdef USE_I2C1
   (* prefix="I2C1" *)
   interface I2C_Pins         i2c1;
`endif
   (* prefix="" *)
   interface `PinType          pins;
   interface Vector#(4, Clock) deleteme_unused_clock;
   //interface Vector#(4, Reset) deleteme_unused_reset;
endinterface

module mkZynqUltraTop `SYS_CLK_PARAM (ZynqUltraTop);
`ifndef TOP_SOURCES_PORTAL_CLOCK
   let axiClock <- exposeCurrentClock();
`else
   B2C axiClockB2C <- mkB2C();
   let axiClock = axiClockB2C.c;
`endif
   PS8LIB ps8 <- mkPS8LIB(axiClock);
   Clock mainclock = ps8.portalClock;
   Reset mainreset = ps8.portalReset;

`ifdef XILINX_SYS_CLK
   Clock sys_clk_200mhz <- mkClockIBUFDS(
`ifdef ClockDefaultParam
       defaultValue,
`endif
       sys_clk_p, sys_clk_n);
   Clock sys_clk_200mhz_buf <- mkClockBUFG(clocked_by sys_clk_200mhz);
`endif // XILINX_SYS_CLK

   BscanTop bscan <- mkBscanTop(3, clocked_by mainclock, reset_by mainreset); // Use USER3  (JTAG IDCODE address 0x22)
   BscanLocal lbscan <- mkBscanLocal(bscan, clocked_by bscan.tck, reset_by bscan.rst);
   Vector#(NumberOfUserTiles,ConnectalTop#(`PinType)) ts <- replicateM(mkConnectalTop(
`ifdef IMPORT_HOSTIF
      (interface HostInterface;
          interface ps8 = ps8;
	  interface portalClock = mainclock;
	  interface portalReset = mainreset;
	  interface derivedClock = ps8.derivedClock;
	  interface derivedReset = ps8.derivedReset;
          interface bscan = lbscan.loc[0];
`ifdef XILINX_SYS_CLK
       interface tsys_clk_200mhz = sys_clk_200mhz;
       interface tsys_clk_200mhz_buf = sys_clk_200mhz_buf;
`endif
      endinterface),
`else                  // enables synthesis boundary
`ifdef IMPORT_HOST_CLOCKS
      ps8.derivedClock, ps8.derivedReset,
`endif
`endif
      clocked_by mainclock, reset_by mainreset));

`ifdef TOP_SOURCES_PORTAL_CLOCK
   C2B portalClockC2B <- mkC2B(ts[0].portalClockSource, clocked_by axiClockB2C.c);
   rule rl_portal_clock_source;
      axiClockB2C.inputclock(portalClockC2B.o);
   endrule
`endif

   Platform top <- mkPlatform(ts, clocked_by mainclock, reset_by mainreset);
   mkConnectionWithTrace(ps8, top, lbscan.loc[1], clocked_by mainclock, reset_by mainreset);

   let intr_mux <- mkInterruptMux(top.interrupt);
   rule send_int_rule;
      ps8.interrupt(pack(intr_mux));
   endrule

   module bufferClock#(Integer i)(Clock); let bc <- mkClockBUFG(clocked_by ps8.plclk[i]); return bc; endmodule
   //module bufferReset#(Integer i)(Reset); let rc <- mkSyncReset(10, ps8.fclkreset[i], ps8.fclkclk[0]); return rc; endmodule
   Vector#(4, Clock) unused_clock <- genWithM(bufferClock);
   //Vector#(4, Reset) unused_reset <- genWithM(bufferReset);

   //interface zynq = ps8.pins;
   interface pins = top.pins;
   interface deleteme_unused_clock = unused_clock;
   //interface deleteme_unused_reset = unused_reset;
endmodule
