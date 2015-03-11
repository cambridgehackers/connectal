// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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

import Vector::*;
import Portal::*;
import CtrlMux::*;
import HostInterface::*;
import MemreadIndication::*;
import Memread::*;
import MMUIndication::*;
import MMU::*;
import MemServerIndication::*;
import MemServer::*;
import MemreadRequest::*;
import MMURequest::*;
import MemServerRequest::*;
import Tile::*;

`ifndef PinType
`define PinType Empty
`endif
typedef `PinType PinType;

typedef enum {MemreadIndicationH2S,MMUIndicationH2S,MemServerIndicationH2S,MemreadRequestS2H,MMURequestS2H,MemServerRequestS2H} IfcNames deriving (Eq,Bits);

module mkConnectalTop
`ifdef IMPORT_HOSTIF
       #(HostType host)
`endif
       (ConnectalTop#(PhysAddrWidth,DataBusWidth,Empty,`NumberOfMasters));
  

   MemreadIndicationProxy lMemreadIndicationProxy <- mkMemreadIndicationProxy(MemreadIndicationH2S);
   Memread lMemread <- mkMemread(lMemreadIndicationProxy.ifc);
   MMUIndicationProxy lMMUIndicationProxy <- mkMMUIndicationProxy(MMUIndicationH2S);
   MMU#(PhysAddrWidth) lMMU <- mkMMU(0,True, lMMUIndicationProxy.ifc);
   MemServerIndicationProxy lMemServerIndicationProxy <- mkMemServerIndicationProxy(MemServerIndicationH2S);
   MemServer#(PhysAddrWidth,DataBusWidth,`NumberOfMasters) lMemServer <- mkMemServer(lMemread.dmaClient,nil,cons(lMMU,nil), lMemServerIndicationProxy.ifc);
   MemreadRequestWrapper lMemreadRequestWrapper <- mkMemreadRequestWrapper(MemreadRequestS2H, lMemread.request);
   MMURequestWrapper lMMURequestWrapper <- mkMMURequestWrapper(MMURequestS2H, lMMU.request);
   MemServerRequestWrapper lMemServerRequestWrapper <- mkMemServerRequestWrapper(MemServerRequestS2H, lMemServer.request);

   Vector#(6,StdPortal) portals;
   portals[0] = lMemreadIndicationProxy.portalIfc;
   portals[1] = lMMUIndicationProxy.portalIfc;
   portals[2] = lMemServerIndicationProxy.portalIfc;
   portals[3] = lMemreadRequestWrapper.portalIfc;
   portals[4] = lMMURequestWrapper.portalIfc;
   portals[5] = lMemServerRequestWrapper.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = lMemServer.masters;
   interface PinType  pins;
   endinterface

endmodule : mkConnectalTop
