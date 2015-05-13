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
import Vector            :: *;
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
module mkXsimSourceBVI#(Bit#(32) portal, Bool src_rdy, MsgBeat#(4) beat)(Empty);
    port portal = portal;
    port src_rdy = src_rdy;
    port beat = beat;
endmodule
module mkXsimSource#(MsgSource#(4) indication, Integer i)(Empty);
   mkXsimSourceBVI(fromInteger(i), indication.src_rdy, indication.beat());
   rule ind_dst_rdy;
      indication.dst_rdy(True);
   endrule
endmodule

interface MsgSinkR#(numeric type bytes_per_beat);
   method Bool src_rdy();
   method MsgBeat#(4) beat();
endinterface

import "BVI" XsimSink =
module mkXsimSinkBVI#(Bit#(32) portal, Bool dst_rdy)(MsgSinkR#(4));
    port portal = portal;
    port dst_rdy = dst_rdy;
    method src_rdy src_rdy();
    method beat beat();
    schedule (src_rdy, beat) CF (src_rdy, beat);
endmodule
module mkXsimSink#(MsgSink#(4) request, Integer portalIndex)(MsgSinkR#(4));
   let sink <- mkXsimSinkBVI(fromInteger(portalIndex), request.dst_rdy);
   rule req_src_rdy;
      request.src_rdy(sink.src_rdy);
   endrule
   rule req_beat;
      request.beat(sink.beat);
   endrule
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
   //BluenocTop#(1,1) top <- mkBluenocTop(
   //BluenocTop#(numRequests, numIndications) top <- mkBluenocTop(
   let top <- mkBluenocTop(
`ifdef IMPORT_HOSTIF
       host
`endif
       );

   mapM_(uncurry(mkXsimSource), zip(top.indications, genVector()));
   mapM_(uncurry(mkXsimSink), zip(top.requests, genVector()));
endmodule
