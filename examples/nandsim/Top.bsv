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
import StmtFSM::*;
import FIFO::*;
import BRAM::*;
import DefaultValue::*;
import Connectable::*;
import CtrlMux::*;
import Portal::*;
import HostInterface::*;
import ConnectalMemory::*;
import MemServerCompat::*;
import MemUtils::*;
import MMU::*;
import NandCfgRequest::*;
import MemServerRequest::*;
import MMURequest::*;
import NandCfgIndication::*;
import MemServerIndication::*;
import MMUIndication::*;
import NandSim::*;
import NandSimNames::*;

module mkConnectalTop(StdConnectalDmaTop#(PhysAddrWidth));

   NandCfgIndicationProxy nandCfgIndicationProxy <- mkNandCfgIndicationProxy(NandCfgIndication);
   NandSim nandSim <- mkNandSim(nandCfgIndicationProxy.ifc);
   NandCfgRequestWrapper nandCfgRequestWrapper <- mkNandCfgRequestWrapper(NandCfgRequest,nandSim.request);

   MMUIndicationProxy backingStoreMMUIndicationProxy <- mkMMUIndicationProxy(BackingStoreMMUIndication);
   MMU#(PhysAddrWidth) backingStoreSGList <- mkMMU(0, True, backingStoreMMUIndicationProxy.ifc);
   MMURequestWrapper backingStoreMMURequestWrapper <- mkMMURequestWrapper(BackingStoreMMURequest, backingStoreSGList.request);

   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(HostMemServerIndication);
   MemServerCompat#(PhysAddrWidth,64,1) hostDma <- mkMemServerCompat(nandSim.readClient, nandSim.writeClient, cons(backingStoreSGList, nil), hostMemServerIndicationProxy.ifc);
   MemServerRequestWrapper hostMemServerRequestWrapper <- mkMemServerRequestWrapper(HostMemServerRequest, hostDma.request);


   Vector#(6,StdPortal) portals;
   portals[0] = nandCfgRequestWrapper.portalIfc;
   portals[1] = nandCfgIndicationProxy.portalIfc;
   portals[2] = hostMemServerRequestWrapper.portalIfc;
   portals[3] = hostMemServerIndicationProxy.portalIfc;
   portals[4] = backingStoreMMURequestWrapper.portalIfc;
   portals[5] = backingStoreMMUIndicationProxy.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);

   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = hostDma.masters;
endmodule : mkConnectalTop
