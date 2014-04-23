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

import Clocks :: *;
import Vector            :: *;
import Connectable       :: *;
import Portal            :: *;
import Leds              :: *;
import Top               :: *;
import AxiMasterSlave    :: *;
import AxiDma            :: *;
import XilinxCells       :: *;
import XbsvXilinxCells   :: *;
import PS7LIB::*;
import PPS7LIB::*;
import XADC::*;
import ConnectableWithTrace::*;
import CtrlMux::*;

interface I2C_Pins;
   interface Inout#(Bit#(1)) scl;
   interface Inout#(Bit#(1)) sda;
endinterface

(* always_ready, always_enabled *)
interface ZynqTop#(type pins);
   (* prefix="" *)
   interface ZynqPins zynq;
   (* prefix="GPIO" *)
   interface LEDS             leds;
   (* prefix="XADC" *)
   interface XADC             xadc;
   (* prefix="I2C" *)
   interface I2C_Pins         i2c;
   (* prefix="" *)
   interface pins             pins;
   interface Vector#(4, Clock) unused_clock;
   interface Vector#(4, Reset) unused_reset;
endinterface

typedef (function Module#(PortalTop#(32, 64, ipins, 0)) mkpt(Clock clock200, Clock io_vita_clk)) MkPortalTop#(type ipins);

module [Module] mkZynqTopFromPortal#(Clock fmc_video_clk1, MkPortalTop#(ipins) constructor)(ZynqTop#(ipins));
   PS7 ps7 <- mkPS7();
   Clock mainclock <- mkClockBUFG(clocked_by ps7.fclkclk[0]);
   Clock clock200 <- mkClockBUFG(clocked_by ps7.fclkclk[3]);
   Reset mainreset = ps7.fclkreset[0];

   let tscl <- mkIOBUF(~ps7.i2c[1].scltn, ps7.i2c[1].sclo, clocked_by mainclock, reset_by mainreset);
   let tsda <- mkIOBUF(~ps7.i2c[1].sdatn, ps7.i2c[1].sdao, clocked_by mainclock, reset_by mainreset);
   rule sdai;
      ps7.i2c[1].sdai(tsda.o);
      ps7.i2c[1].scli(tscl.o);
   endrule

   Clock fmc_video_clk1_buf <- mkClockIBUFG(clocked_by fmc_video_clk1);
   let top <- constructor(clock200, fmc_video_clk1_buf, clocked_by mainclock, reset_by mainreset);
   Axi3Slave#(32,32,12) ctrl <- mkAxiDmaSlave(top.slave);
   mkConnection(ps7.m_axi_gp[0].client, ctrl, clocked_by mainclock, reset_by mainreset);
   //Axi3Master#(32,64,6) m_axi <- mkAxiDmaMaster(top.masters[0], clocked_by mainclock, reset_by mainreset);
   //mkConnectionWithTrace(m_axi, ps7.s_axi_hp[0].axi.server, clocked_by mainclock, reset_by mainreset);

   let intr_mux <- mkInterruptMux(top.interrupt);
   rule send_int_rule;
      ps7.interrupt(pack(intr_mux));
   endrule

   interface zynq = ps7.pins;
   interface leds = top.leds;
   interface XADC xadc;
      method Bit#(4) gpio;
         return 0;
      endmethod
   endinterface

   interface I2C_Pins i2c;
      interface Inout scl = tscl.io;
      interface Inout sda = tsda.io;
   endinterface

   interface pins = top.pins;

   // these are exported to make bsc happy, and then the ports are disconnected after synthesis
   interface unused_clock = ps7.fclkclk;
   interface unused_reset = ps7.fclkreset;
endmodule

module mkImageonZynqTop#(Clock fmc_video_clk1)(ZynqTop#(ImageCapturePins));
   let top <- mkZynqTopFromPortal(fmc_video_clk1, mkPortalTop);
   return top;
endmodule
