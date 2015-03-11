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
import SpecialFIFOs::*;
import Vector::*;
import StmtFSM::*;
import FIFO::*;
import CtrlMux::*;
import Portal::*;
import Leds::*;
import ConnectalMemory::*;
import MemTypes::*;
import MemServer::*;
import MMU::*;
import HostInterface::*;
import MemcpyRequest::*;
import MemServerRequest::*;
import MMURequest::*;
import MemcpyIndication::*;
import MemServerIndication::*;
import MMUIndication::*;
import Memcpy::*;

typedef enum {MemcpyIndication, 
	      MemcpyRequest, 

	      HostMemServerIndication, 
	      HostMemServerRequest, 

	      HostMMU0ConfigRequest, 
	      HostMMU0ConfigIndication,
	      
	      HostMMU1ConfigRequest, 
	      HostMMU1ConfigIndication,
	      
	      HostMMU2ConfigRequest, 
	      HostMMU2ConfigIndication,

	      HostMMU3ConfigRequest, 
	      HostMMU3ConfigIndication } IfcNames deriving (Eq,Bits);

module mkConnectalTop(StdConnectalDmaTop#(PhysAddrWidth));

   MemcpyIndicationProxy memcpyIndicationProxy <- mkMemcpyIndicationProxy(MemcpyIndication);
   Memcpy memcpy <- mkMemcpy(memcpyIndicationProxy.ifc);
   MemcpyRequestWrapper memcpyRequestWrapper <- mkMemcpyRequestWrapper(MemcpyRequest,memcpy.request);


   MMUIndicationProxy hostMMU0ConfigIndicationProxy <- mkMMUIndicationProxy(HostMMU0ConfigIndication);
   MMU#(PhysAddrWidth) hostMMU0 <- mkMMU(0, True, hostMMU0ConfigIndicationProxy.ifc);
   MMURequestWrapper hostMMU0ConfigRequestWrapper <- mkMMURequestWrapper(HostMMU0ConfigRequest, hostMMU0.request);
   
   MMUIndicationProxy hostMMU1ConfigIndicationProxy <- mkMMUIndicationProxy(HostMMU1ConfigIndication);
   MMU#(PhysAddrWidth) hostMMU1 <- mkMMU(1, True, hostMMU1ConfigIndicationProxy.ifc);
   MMURequestWrapper hostMMU1ConfigRequestWrapper <- mkMMURequestWrapper(HostMMU1ConfigRequest, hostMMU1.request);
   
   MMUIndicationProxy hostMMU2ConfigIndicationProxy <- mkMMUIndicationProxy(HostMMU2ConfigIndication);
   MMU#(PhysAddrWidth) hostMMU2 <- mkMMU(2, True, hostMMU2ConfigIndicationProxy.ifc);
   MMURequestWrapper hostMMU2ConfigRequestWrapper <- mkMMURequestWrapper(HostMMU2ConfigRequest, hostMMU2.request);

   MMUIndicationProxy hostMMU3ConfigIndicationProxy <- mkMMUIndicationProxy(HostMMU3ConfigIndication);
   MMU#(PhysAddrWidth) hostMMU3 <- mkMMU(3, True, hostMMU3ConfigIndicationProxy.ifc);
   MMURequestWrapper hostMMU3ConfigRequestWrapper <- mkMMURequestWrapper(HostMMU3ConfigRequest, hostMMU3.request);
   
   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(HostMemServerIndication);
   let sgls = cons(hostMMU0,cons(hostMMU1, cons(hostMMU2,cons(hostMMU3,nil))));  
   MemServer#(PhysAddrWidth,64,1) dma <- mkMemServer(memcpy.dmaReadClient, memcpy.dmaWriteClient, sgls, hostMemServerIndicationProxy.ifc);
   MemServerRequestWrapper hostMemServerRequestWrapper <- mkMemServerRequestWrapper(HostMemServerRequest, dma.request);

   Vector#(12,StdPortal) portals;
   portals[0] = memcpyRequestWrapper.portalIfc;
   portals[1] = memcpyIndicationProxy.portalIfc; 
   portals[2] = hostMemServerRequestWrapper.portalIfc;
   portals[3] = hostMemServerIndicationProxy.portalIfc; 
   
   portals[4] = hostMMU0ConfigRequestWrapper.portalIfc;
   portals[5] = hostMMU0ConfigIndicationProxy.portalIfc;
   
   portals[6] = hostMMU1ConfigRequestWrapper.portalIfc;
   portals[7] = hostMMU1ConfigIndicationProxy.portalIfc;
   
   portals[8] = hostMMU2ConfigRequestWrapper.portalIfc;
   portals[9] = hostMMU2ConfigIndicationProxy.portalIfc;

   portals[10] = hostMMU3ConfigRequestWrapper.portalIfc;
   portals[11] = hostMMU3ConfigIndicationProxy.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = dma.masters;
   interface leds = default_leds;
endmodule


