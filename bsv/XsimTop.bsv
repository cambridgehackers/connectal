// Copyright (c) 2015 Quanta Research Cambridge, Inc.

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
import Portal            :: *;
import Top               :: *;
import HostInterface     :: *;
import BlueNoC::*;
import BnocPortal::*;

`ifndef PinType
`define PinType Empty
`endif

typedef `PinType PinType;
typedef `NumberOfMasters NumberOfMasters;

module  mkXsimHost#(Clock derivedClock, Reset derivedReset)(XsimHost);
   interface derivedClock = derivedClock;
   interface derivedReset = derivedReset;
endmodule

interface XsimTop;
   interface MsgSource#(4) msgSource;
   interface MsgSink#(4) msgSink;
   interface Clock singleClock;
   interface Reset singleReset;
endinterface

module mkXsimTop(XsimTop);
   Clock derivedClock <- exposeCurrentClock;
   Reset derivedReset <- exposeCurrentReset;
   Clock single_clock = derivedClock;
   Reset single_reset = derivedReset;

   Reg#(Bool) dumpstarted <- mkReg(False);
   rule startdump if (!dumpstarted);
      //$dumpfile("dump.vcd");
      //$dumpvars;
      dumpstarted <= True;
   endrule
   XsimHost host <- mkXsimHost(derivedClock, derivedReset);
   BluenocTop#(1,1) top <- mkBluenocTop(
`ifdef IMPORT_HOSTIF
       host
`endif
       );

   interface msgSink = top.requests[0];
   interface msgSource = top.indications[0];
   interface Clock singleClock = single_clock;
   interface Reset singleReset = single_reset;
endmodule
