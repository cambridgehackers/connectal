// Copyright (c) 2015 Connectal Project

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
import Top::*;

`include "ConnectalProjectConfig.bsv"

interface AsicTop;
   interface Vector#(TAdd#(2,NumberOfRequests), PortalMsgRequest) requests;
   interface Vector#(TAdd#(2,NumberOfIndications), PortalMsgIndication) indications;
endinterface

module mkAsicTop#(Clock derivedClock, Reset derivedReset)(AsicTop);

   Reg#(Bool) dumpstarted <- mkReg(False);
   rule startdump if (!dumpstarted);
      //$dumpfile("dump.vcd");
      //$dumpvars;
      $display("AsicTop starting");
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

   let lMMUIndicationOutputNoc <- mkPortalMsgIndication(extend(pack(PlatformIfcNames_MMUIndicationH2S)), lMMUIndicationOutput.portalIfc.indications, lMMUIndicationOutput.portalIfc.messageSize);
   let lMMURequestInputNoc <- mkPortalMsgRequest(extend(pack(PlatformIfcNames_MMURequestS2H)), lMMURequestInput.portalIfc.requests);
   let lMemServerIndicationOutputNoc <- mkPortalMsgIndication(extend(pack(PlatformIfcNames_MemServerIndicationH2S)), lMemServerIndicationOutput.portalIfc.indications, lMemServerIndicationOutput.portalIfc.messageSize);
   let lMemServerRequestInputNoc <- mkPortalMsgRequest(extend(pack(PlatformIfcNames_MemServerRequestS2H)), lMemServerRequestInput.portalIfc.requests);

   interface requests = append(top.requests, vec(lMMURequestInputNoc, lMemServerRequestInputNoc));
   interface indications = append(top.indications, vec(lMMUIndicationOutputNoc, lMemServerIndicationOutputNoc));
   //  mapM_(mkAsicMemoryConnection, lMemServer.masters);
endmodule
