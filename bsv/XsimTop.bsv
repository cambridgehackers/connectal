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

import "BVI" XsimSource =
module mkXsimSource#(Bool src_rdy, MsgBeat#(4) beat)(Empty);
    port src_rdy = src_rdy;
    port beat = beat;
endmodule

interface MsgSinkR#(numeric type bytes_per_beat);
   method Bool src_rdy();
   method MsgBeat#(4) beat();
endinterface

import "BVI" XsimSink =
module mkXsimSink#(Bool dst_rdy)(MsgSinkR#(4));
    port dst_rdy = dst_rdy;
    method src_rdy src_rdy();
    method beat beat();
    schedule (src_rdy, beat) CF (src_rdy, beat);
endmodule

module mkXsimTop(Empty);
   Clock derivedClock <- exposeCurrentClock;
   Reset derivedReset <- exposeCurrentReset;

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

   mkXsimSource(top.indications[0].src_rdy, top.indications[0].beat);
   rule ind_dst_rdy;
       top.indications[0].dst_rdy(True);
   endrule
   MsgSinkR#(4) sink <- mkXsimSink(top.requests[0].dst_rdy);
   rule req_src_rdy;
       top.requests[0].src_rdy(sink.src_rdy);
   endrule
   rule req_beat;
       top.requests[0].beat(sink.beat);
   endrule
endmodule
