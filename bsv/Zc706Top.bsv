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
import ConnectableWithTrace::*;
import CtrlMux::*;
import AxiMasterSlave    :: *;
import AxiDma            :: *;

interface I2C_Pins;
   interface Inout#(Bit#(1)) scl;
   interface Inout#(Bit#(1)) sda;
endinterface

(* always_ready, always_enabled *)
interface ZynqTop#(type pins);
   (* prefix="" *)
   interface ZynqPins zynq;
//   (* prefix="GPIO" *)
//   interface LEDS             leds;
//   (* prefix="XADC" *)
//   interface XADC             xadc;
`ifdef USE_I2C
   (* prefix="I2C" *)
   interface I2C_Pins         i2c;
`endif
   (* prefix="" *)
   interface pins             pins;
   interface Vector#(4, Clock) deleteme_unused_clock;
   interface Vector#(4, Reset) deleteme_unused_reset;
endinterface

`ifdef USES_FCLK1
`define CLOCK_DECL Clock clk1
`define CLOCK_ARG  ps7.fclkclk[1],
`else
`define CLOCK_DECL
`define CLOCK_ARG
`endif

typedef (function Module#(PortalTop#(32, 64, ipins, nMasters)) mkpt(`CLOCK_DECL)) MkPortalTop#(type ipins, numeric type nMasters);

module [Module] mkZynqTopFromPortal#(MkPortalTop#(ipins,nMasters) constructor)(ZynqTop#(ipins))
   provisos(Add#(a__,nMasters,4));

   PS7 ps7 <- mkPS7();
   Clock mainclock = ps7.fclkclk[0];
   Clock clock200 = ps7.fclkclk[3];
   Reset mainreset = ps7.fclkreset[0];
   IDELAYCTRL idel <- mkIDELAYCTRL(2, clocked_by clock200, reset_by mainreset);

   let tscl <- mkIOBUF(~ps7.i2c[1].scltn, ps7.i2c[1].sclo, clocked_by mainclock, reset_by mainreset);
   let tsda <- mkIOBUF(~ps7.i2c[1].sdatn, ps7.i2c[1].sdao, clocked_by mainclock, reset_by mainreset);
   rule sdai;
      ps7.i2c[1].sdai(tsda.o);
      ps7.i2c[1].scli(tscl.o);
   endrule

   let top <- constructor(`CLOCK_ARG clocked_by mainclock, reset_by mainreset);
   mkConnection(ps7, top, clocked_by mainclock, reset_by mainreset);

   let intr_mux <- mkInterruptMux(top.interrupt);
   rule send_int_rule;
      ps7.interrupt(pack(intr_mux));
   endrule

   module bufferClock#(Integer i)(Clock); let bc <- mkClockBUFG(clocked_by ps7.fclkclk[i]); return bc; endmodule
   module bufferReset#(Integer i)(Reset); let rc <- mkAsyncReset(2, ps7.fclkreset[i], ps7.fclkclk[0]); return rc; endmodule
   Vector#(4, Clock) unused_clock <- genWithM(bufferClock);
   Vector#(4, Reset) unused_reset <- genWithM(bufferReset);
   interface zynq = ps7.pins;
   // interface leds = top.leds;
   // interface XADC xadc;
   //     method Bit#(4) gpio;
   //         return 0;
   //     endmethod
   // endinterface
`ifdef USE_I2C
   interface I2C_Pins i2c;
      interface Inout scl = tscl.io;
      interface Inout sda = tsda.io;
   endinterface
`endif
   interface pins = top.pins;
   interface deleteme_unused_clock = unused_clock;
   interface deleteme_unused_reset = unused_reset;
endmodule

`ifndef PinType
`define PinType Empty
`endif
module mkZynqTop(ZynqTop#(`PinType));
   let top <- mkZynqTopFromPortal(mkPortalTop);
   return top;
endmodule
