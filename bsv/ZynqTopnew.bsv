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
import PS7Helper::*;

(* always_ready, always_enabled *)
interface ZynqTop#(type pins);
   (* prefix="" *)
   interface ZynqPins zynq;
   (* prefix="GPIO" *)
   interface LEDS             leds;
   interface pins             pins;
endinterface


typedef (function Module#(PortalTop#(nmasters, ipins)) mkpt()) MkPortalTop#(numeric type nmasters, type ipins);

module [Module] mkZynqTopFromPortal#(MkPortalTop#(nmasters,ipins) constructor)(ZynqTop#(ipins));
   let defaultClock <- exposeCurrentClock;
   let defaultReset <- exposeCurrentReset;
   let top <- constructor(clocked_by defaultClock);
   StdAxi3Master master = ?;
   if (valueOf(nmasters) > 0) begin
      let m <- mkAxi3Master(top.m_axi[0]);
      master = m;
   end
   ZynqPins ps7 <- mkPS7Slave(defaultClock, defaultReset, top.ctrl, master, top.interrupt);

   interface zynq = ps7;
   interface leds = top.leds;
   interface pins = top.pins;
endmodule

module mkZynqTopnew(ZynqTop#(Empty));
   let top <- mkZynqTopFromPortal(mkPortalTop);
   return top;
endmodule

