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
import XbsvXilinxCells   :: *;
import PS7LIB::*;
import PPS7LIB::*;
import XADC::*;
import FIFOF::*;
import HDMI::*;
import ConnectableWithTrace::*;
import CtrlMux::*;
import AxiMasterSlave    :: *;
import AxiDma            :: *;

//`define TRACE_AXI
//`define AXI_READ_TIMING

(* always_ready, always_enabled *)
interface ZynqTop#(type pins);
   (* prefix="" *)
   interface ZynqPins zynq;
   (* prefix="GPIO" *)
   interface LEDS             leds;
   (* prefix="XADC" *)
   interface XADC             xadc;
   (* prefix="hdmi" *)
   interface pins             pins;
   interface Vector#(4, Clock) unused_clock;
   interface Vector#(4, Reset) unused_reset;
endinterface

typedef (function Module#(PortalTop#(32, 64, ipins)) mkpt(Clock clk1)) MkPortalTop#(type ipins);

module [Module] mkZynqTopFromPortal#(MkPortalTop#(ipins) constructor)(ZynqTop#(ipins));
   PS7 ps7 <- mkPS7();
   Clock mainclock = ps7.fclkclk[0];
   Reset mainreset = ps7.fclkreset[0];

   let top <- constructor(ps7.fclkclk[1], clocked_by mainclock, reset_by mainreset);
   
   Axi3Slave#(32,32,12) ctrl <- mkAxiDmaSlave(top.slave);
   mkConnectionWithTrace(ps7.m_axi_gp[0].client, ctrl, clocked_by mainclock, reset_by mainreset);
   Axi3Master#(32,64,6) m_axi <- mkAxiDmaMaster(top.master, clocked_by mainclock, reset_by mainreset);
   mkConnection(m_axi, ps7.s_axi_hp[0].axi.server, clocked_by mainclock, reset_by mainreset);

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
   interface pins = top.pins;

   // these are exported to make bsc happy, and then the ports are disconnected after synthesis
   interface unused_clock = ps7.fclkclk;
   interface unused_reset = ps7.fclkreset;
endmodule

module mkHdmiZynqTop(ZynqTop#(HDMI));
   let top <- mkZynqTopFromPortal(mkPortalTop);
   return top;
endmodule
