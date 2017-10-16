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
import ConnectalMemTypes:: *;
import ConnectalMMU:: *;
import MemServer:: *;
import MMURequest::*;
import MMUIndication::*;
import MemServerIndication::*;
import MemServerRequest::*;
import SimDma::*;
import IfcNames::*;
import BuildVector::*;

`include "ConnectalProjectConfig.bsv"

`ifdef PinTypeInclude
import `PinTypeInclude::*;
`endif
`ifdef PinType
typedef `PinType PinType;
`else
typedef Empty PinType;
`endif

`ifndef SVDPI
import "BDPI" function Action dpi_init();
import "BDPI" function ActionValue#(Bool) dpi_cycle(); // returns non-zero if verilog should $finish().
`endif

interface XsimTop;
   interface PinType pins;
endinterface

interface XsimSource;
    method Action beat(Bit#(32) v);
endinterface
`ifdef SVDPI
import "BVI" XsimSource =
module mkXsimSourceBVI#(Bit#(32) portal)(XsimSource);
    port portal = portal;
    method beat(beat) enable(en_beat);
    schedule (beat) C (beat);
endmodule
module mkXsimSource#(PortalMsgIndication indication)(Empty);
   let tmp <- mkXsimSourceBVI(indication.id);
   rule ind_dst_rdy;
      indication.message.deq();
      tmp.beat(indication.message.first());
   endrule
endmodule
`else
import "BDPI" function Action dpi_msgSource_beat(Bit#(32)  portal, Bit#(32)  beat);
module mkXsimSource#(PortalMsgIndication indication)(Empty);
   rule ind_dst_rdy;
      indication.message.deq();
      dpi_msgSource_beat(indication.id, indication.message.first());
   endrule
endmodule
`endif

interface MsgSinkR#(numeric type bytes_per_beat);
   method ActionValue#(Bit#(32)) beat();
endinterface

`ifdef SVDPI
import "BVI" XsimSink =
module mkXsimSinkBVI#(Bit#(32) portal)(MsgSinkR#(4));
   port portal = portal;
   method beat beat() enable (EN_beat) ready (RDY_beat);
   schedule (beat) C (beat);
endmodule
module mkXsimSink#(PortalMsgRequest request)(Empty);
   let sink <- mkXsimSinkBVI(request.id);

   rule req_src_rdy;
      let beat <- sink.beat();
      request.message.enq(beat);
   endrule
endmodule
`else
import "BDPI" function ActionValue#(Bit#(33)) dpi_msgSink_beat(Bit#(32) portal);
module mkXsimSink#(PortalMsgRequest request)(Empty);
   rule req_src_rdy;
      let beat <- dpi_msgSink_beat(request.id);
      if (unpack(beat[32]))
	 request.message.enq(beat[31:0]);
   endrule
endmodule
`endif

module mkXsimMemoryConnection#(PhysMemMaster#(addrWidth, dataWidth) master)(Empty)
   provisos (Mul#(TDiv#(dataWidth, 8), 8, dataWidth),
	     Mul#(TDiv#(dataWidth, 32), 32, dataWidth),
	     Add#(a__, TDiv#(DataBusWidth,8), TDiv#(dataWidth, 8)),
	     Mul#(TDiv#(dataWidth, 32), 4, TDiv#(dataWidth, 8)));
   PhysMemSlave#(addrWidth,dataWidth) slave <- mkSimDmaDmaMaster();
   mkConnection(master, slave);
endmodule

module mkXsimTop#(Clock derivedClock, Reset derivedReset, Clock sys_clk)(XsimTop);

   Reg#(Bool) dumpstarted <- mkReg(False);
   rule startdump if (!dumpstarted);
      //$dumpfile("dump.vcd");
      //$dumpvars;
      $display("XsimTop starting");
      dumpstarted <= True;
   endrule
   XsimHost host <- mkXsimHost(derivedClock, derivedReset, sys_clk);
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

`ifndef SVDPI
   Reg#(Bool) initCalled <- mkReg(False);
   rule call_init if (!initCalled);
      dpi_init();
      initCalled <= True;
   endrule
   rule finish;
      let doFinish <- dpi_cycle();
      if (doFinish) begin
	 $display("simulator calling $finish");
	 $finish();
      end
   endrule
`endif

   MMUIndicationOutput lMMUIndicationOutput <- mkMMUIndicationOutput;
   MMURequestInput lMMURequestInput <- mkMMURequestInput;
   MMU#(PhysAddrWidth) lMMU <- mkMMU(0,True, lMMUIndicationOutput.ifc);
   mkConnection(lMMURequestInput.pipes, lMMU.request);

   MemServerIndicationOutput lMemServerIndicationOutput <- mkMemServerIndicationOutput;
   MemServerRequestInput lMemServerRequestInput <- mkMemServerRequestInput;
   MemServer::MemServer#(PhysAddrWidth,DataBusWidth,NumberOfMasters) lMemServer <- mkMemServer(top.readers, top.writers, cons(lMMU,nil), lMemServerIndicationOutput.ifc);
   mkConnection(lMemServerRequestInput.pipes, lMemServer.request);

   let lMMUIndicationOutputNoc <- mkPortalMsgIndication(extend(pack(PlatformIfcNames_MMUIndicationH2S)), lMMUIndicationOutput.portalIfc.indications, lMMUIndicationOutput.portalIfc.messageSize);
   let lMMURequestInputNoc <- mkPortalMsgRequest(extend(pack(PlatformIfcNames_MMURequestS2H)), lMMURequestInput.portalIfc.requests);
   let lMemServerIndicationOutputNoc <- mkPortalMsgIndication(extend(pack(PlatformIfcNames_MemServerIndicationH2S)), lMemServerIndicationOutput.portalIfc.indications, lMemServerIndicationOutput.portalIfc.messageSize);
   let lMemServerRequestInputNoc <- mkPortalMsgRequest(extend(pack(PlatformIfcNames_MemServerRequestS2H)), lMemServerRequestInput.portalIfc.requests);

   mapM_(mkXsimSink, append(top.requests, append(vec(lMMURequestInputNoc), vec(lMemServerRequestInputNoc))));
   mapM_(mkXsimSource, append(top.indications, append(vec(lMMUIndicationOutputNoc), vec(lMemServerIndicationOutputNoc))));
   mapM_(mkXsimMemoryConnection, lMemServer.masters);

`ifdef PinType
   interface pins = top.pins;
`endif
endmodule
