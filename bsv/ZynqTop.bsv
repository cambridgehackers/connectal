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
import ConnectableWithTrace::*;
import CtrlMux::*;
import AxiMasterSlave    :: *;
import AxiDma            :: *;

(* always_ready, always_enabled *)
interface ZynqTop#(type pins);
   (* prefix="" *)
   interface ZynqPins zynq;
   (* prefix="GPIO" *)
   interface LEDS             leds;
   (* prefix="XADC" *)
   interface XADC             xadc;
   interface pins             pins;
   interface Clock unused_clock;
   interface Reset unused_reset;
endinterface

typedef (function Module#(PortalTop#(32, 64, ipins, nMasters)) mkpt()) MkPortalTop#(type ipins, numeric type nMasters);

module [Module] mkZynqTopFromPortal#(MkPortalTop#(ipins,nMasters) constructor)(ZynqTop#(ipins))
   provisos(Add#(a__,nMasters,4));
	       
   PS7 ps7 <- mkPS7();
   Clock mainclock = ps7.fclkclk[0];
   Reset mainreset = ps7.fclkreset[0];

   let top <- constructor(clocked_by mainclock, reset_by mainreset);
   
   Axi3Slave#(32,32,12) ctrl <- mkAxiDmaSlave(top.slave);
   mkConnection(ps7.m_axi_gp[0].client, ctrl, clocked_by mainclock, reset_by mainreset);
   Vector#(nMasters,Axi3Master#(32,64,6)) m_axis;   
   if(valueOf(nMasters) > 0) begin
      m_axis[0] <- mkAxiDmaMaster(clocked_by mainclock, reset_by mainreset, top.masters[0]);
      mkConnectionWithTrace(m_axis[0], ps7.s_axi_hp[0].axi.server, clocked_by mainclock, reset_by mainreset);
   end
   if(valueOf(nMasters) > 1) begin
      m_axis[1] <- mkAxiDmaMaster(clocked_by mainclock, reset_by mainreset, top.masters[1]);
      mkConnectionWithTrace(m_axis[1], ps7.s_axi_hp[1].axi.server, clocked_by mainclock, reset_by mainreset);
   end
   if(valueOf(nMasters) > 2) begin
      m_axis[2] <- mkAxiDmaMaster(clocked_by mainclock, reset_by mainreset, top.masters[2]);
      mkConnectionWithTrace(m_axis[2], ps7.s_axi_hp[2].axi.server, clocked_by mainclock, reset_by mainreset);
   end   
   if(valueOf(nMasters) > 3) begin
      m_axis[3] <- mkAxiDmaMaster(clocked_by mainclock, reset_by mainreset, top.masters[3]);
      mkConnectionWithTrace(m_axis[3], ps7.s_axi_hp[3].axi.server, clocked_by mainclock, reset_by mainreset);
   end
   
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
   interface unused_clock = mainclock;
   interface unused_reset = mainreset;
endmodule

module mkZynqTop(ZynqTop#(Empty));
   let top <- mkZynqTopFromPortal(mkPortalTop);
   return top;
endmodule
