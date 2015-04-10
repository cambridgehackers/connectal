/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
import SpecialFIFOs::*;
import Vector::*;
import BuildVector::*;
import StmtFSM::*;
import FIFO::*;
import CtrlMux::*;
import Portal::*;
import ConnectalMemory::*;
import HostInterface::*;
import MemTypes::*;
import MemServer::*;
import MMU::*;
import MemwriteRequest::*;
import MemServerRequest::*;
import MMURequest::*;
import MemwriteIndication::*;
import MemServerIndication::*;
import MMUIndication::*;
import Memwrite::*;

typedef enum {HostMemServerIndication, HostMemServerRequest, HostMMURequest, HostMMUIndication, MemwriteIndication, MemwriteRequest} IfcNames deriving (Eq,Bits);

module mkConnectalTop(StdConnectalDmaTop#(PhysAddrWidth));

   MemwriteIndicationProxy memwriteIndicationProxy <- mkMemwriteIndicationProxy(MemwriteIndication);
   Memwrite memwrite <- mkMemwrite(memwriteIndicationProxy.ifc);
   MemwriteRequestWrapper memwriteRequestWrapper <- mkMemwriteRequestWrapper(MemwriteRequest,memwrite.request);

   Vector#(1, MemWriteClient#(64)) writeClients = vec(memwrite.dmaClient);

   MMUIndicationProxy hostMMUIndicationProxy <- mkMMUIndicationProxy(HostMMUIndication);
   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(HostMemServerIndication);

   MemServerWithMMU#(PhysAddrWidth,64,1) dma <- mkMemServerWithMMU(nil, writeClients, hostMemServerIndicationProxy.ifc, hostMMUIndicationProxy.ifc);

   MMURequestWrapper hostMMURequestWrapper <- mkMMURequestWrapper(HostMMURequest, dma.mmuRequest);
   MemServerRequestWrapper hostMemServerRequestWrapper <- mkMemServerRequestWrapper(HostMemServerRequest, dma.memServerRequest);
   
   Vector#(6,StdPortal) portals;
   portals[0] = memwriteRequestWrapper.portalIfc;
   portals[1] = memwriteIndicationProxy.portalIfc; 
   portals[2] = hostMemServerRequestWrapper.portalIfc;
   portals[3] = hostMemServerIndicationProxy.portalIfc; 
   portals[4] = hostMMURequestWrapper.portalIfc;
   portals[5] = hostMMUIndicationProxy.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = dma.masters;
endmodule
