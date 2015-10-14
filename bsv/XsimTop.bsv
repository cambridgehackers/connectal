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
import ConnectalConfig::*;
import Vector            :: *;
import GetPut::*;
import Connectable::*;
import Portal            :: *;
import Top               :: *;
import HostInterface     :: *;
import Pipe::*;
import CnocPortal::*;
import MemTypes:: *;
import MMU:: *;
import MemServer:: *;
import MMURequest::*;
import MMUIndication::*;
import MemServerIndication::*;
import MemServerRequest::*;
import SimDma::*;
import IfcNames::*;
import BuildVector::*;

`include "ConnectalProjectConfig.bsv"

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

module mkXsimMemoryConnection#(PhysMemMaster#(addrWidth, dataWidth) master)(Empty)
   provisos (Mul#(TDiv#(dataWidth, 8), 8, dataWidth),
	     Mul#(TDiv#(dataWidth, 32), 32, dataWidth),
	     Add#(a__, TDiv#(DataBusWidth,8), TDiv#(dataWidth, 8)),
	     Mul#(TDiv#(dataWidth, 32), 4, TDiv#(dataWidth, 8)));
   PhysMemSlave#(addrWidth,dataWidth) slave <- mkSimDmaDmaMaster();
   mkConnection(master, slave);
endmodule

module mkXsimTop#(Clock derivedClock, Reset derivedReset)(Empty);

   Reg#(Bool) dumpstarted <- mkReg(False);
   rule startdump if (!dumpstarted);
      //$dumpfile("dump.vcd");
      //$dumpvars;
      $display("XsimTop starting");
      dumpstarted <= True;
   endrule
   XsimHost host <- mkXsimHost(derivedClock, derivedReset);
   let top <- mkCnocTop(
`ifdef IMPORT_HOSTIF
       host
`else
`ifdef IMPORT_HOST_CLOCKS // enables synthesis boundary
       derivedClock, derivedReset
`else
// otherwise no params
`endif
`endif
       );

   MMUIndicationOutput lMMUIndicationOutput <- mkMMUIndicationOutput;
   MMURequestInput lMMURequestInput <- mkMMURequestInput;
   MMU#(PhysAddrWidth) lMMU <- mkMMU(0,True, lMMUIndicationOutput.ifc);
   mkConnection(lMMURequestInput.pipes, lMMU.request);

   MemServerIndicationOutput lMemServerIndicationOutput <- mkMemServerIndicationOutput;
   MemServerRequestInput lMemServerRequestInput <- mkMemServerRequestInput;
   MemServer#(PhysAddrWidth,DataBusWidth,NumberOfMasters) lMemServer <- mkMemServer(top.readers, top.writers, cons(lMMU,nil), lMemServerIndicationOutput.ifc);
   mkConnection(lMemServerRequestInput.pipes, lMemServer.request);

   let lMMUIndicationOutputNoc <- mkPortalMsgIndication(extend(pack(IfcNames_MMUIndicationH2S)), lMMUIndicationOutput.portalIfc.indications, lMMUIndicationOutput.portalIfc.messageSize);
   let lMMURequestInputNoc <- mkPortalMsgRequest(extend(pack(IfcNames_MMURequestS2H)), lMMURequestInput.portalIfc.requests);
   let lMemServerIndicationOutputNoc <- mkPortalMsgIndication(extend(pack(IfcNames_MemServerIndicationH2S)), lMemServerIndicationOutput.portalIfc.indications, lMemServerIndicationOutput.portalIfc.messageSize);
   let lMemServerRequestInputNoc <- mkPortalMsgRequest(extend(pack(IfcNames_MemServerRequestS2H)), lMemServerRequestInput.portalIfc.requests);

   mapM_(mkXsimSink, append(top.requests, append(vec(lMMURequestInputNoc), vec(lMemServerRequestInputNoc))));
   mapM_(mkXsimSource, append(top.indications, append(vec(lMMUIndicationOutputNoc), vec(lMemServerIndicationOutputNoc))));
   mapM_(mkXsimMemoryConnection, lMemServer.masters);
endmodule
