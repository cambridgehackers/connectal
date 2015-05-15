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
import Pipe::*;
import CnocPortal::*;
import Pareff::*;
import GetPut::*;
import Connectable::*;

`ifndef PinType
`define PinType Empty
`endif

typedef `PinType PinType;
typedef `NumberOfMasters NumberOfMasters;

module  mkXsimHost#(Clock derivedClock, Reset derivedReset)(XsimHost);
   interface derivedClock = derivedClock;
   interface derivedReset = derivedReset;
endmodule

interface XsimSource;
    method Action beat(Bit#(32) v);
endinterface
import "BVI" XsimSource =
module mkXsimSourceBVI#(Bit#(32) portal)(XsimSource);
    port portal = portal;
    method beat(beat) enable(en_beat);
endmodule
module mkXsimSource#(PortalMsgIndication indication)(Empty);
   let tmp <- mkXsimSourceBVI(indication.id);
   rule ind_dst_rdy;
      indication.message.deq();
      tmp.beat(indication.message.first());
   endrule
endmodule

interface MsgSinkR#(numeric type bytes_per_beat);
   method Bool src_rdy();
   method Bit#(32) beat();
endinterface

import "BVI" XsimSink =
module mkXsimSinkBVI#(Bit#(32) portal)(MsgSinkR#(4));
    port portal = portal;
    method src_rdy src_rdy();
    method beat beat();
    schedule (src_rdy, beat) CF (src_rdy, beat);
endmodule
module mkXsimSink#(PortalMsgRequest request)(MsgSinkR#(4));
   let sink <- mkXsimSinkBVI(request.id);
   rule req_src_rdy if (sink.src_rdy);
      request.message.enq(sink.beat);
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
   let top <- mkCnocTop(
`ifdef IMPORT_HOSTIF
       host
`endif
       );
   mapM_(mkXsimSource, top.indications);
   mapM_(mkXsimSink, top.requests);
   mapM_(mkConnection, zip(top.masters, replicateM(mkPareffDmaMaster)));
endmodule
