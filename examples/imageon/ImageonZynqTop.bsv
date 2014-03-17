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
import XilinxCells       :: *;
import XbsvXilinxCells   :: *;
import PS7LIB::*;
import PPS7LIB::*;
import XADC::*;
import FIFOF::*;
import HDMI::*;
import Imageon::*;
import ConnectableWithTrace::*;

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
   (* prefix="" *)
   interface pins             pins;
   interface Vector#(4, Clock) unused_clock;
   interface Vector#(4, Reset) unused_reset;
endinterface

typedef (function Module#(PortalTop#(32, 64, ipins)) mkpt(Clock clock200, Clock io_vita_clk)) MkPortalTop#(type ipins);

module [Module] mkZynqTopFromPortal#(Clock io_vita_clk_out_p, Clock io_vita_clk_out_n, MkPortalTop#(ipins) constructor)(ZynqTop#(ipins));
   Clock io_vita_clk <- XilinxCells::mkClockIBUFDS(io_vita_clk_out_p, io_vita_clk_out_n);
   PS7 ps7 <- mkPS7();
   Clock mainclock = ps7.fclkclk[0];
   Reset mainreset = ps7.fclkreset[0];

   // I have a feeling the fclkclk[3] is not what we want. Jamey
   let top <- constructor(ps7.fclkclk[3], io_vita_clk, clocked_by mainclock, reset_by mainreset);

   mkConnection(ps7.m_axi_gp[0].client, top.ctrl);
   mkConnectionWithTrace(top.m_axi, ps7.s_axi_hp[0].axi.server);

   rule send_int_rule;
       ps7.interrupt(pack(top.interrupt));
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

module mkImageonZynqTop#(Clock io_vita_clk_out_p, Clock io_vita_clk_out_n)(ZynqTop#(ImageonVita));
   let top <- mkZynqTopFromPortal(io_vita_clk_out_p, io_vita_clk_out_n, mkPortalTop);
   return top;
endmodule
