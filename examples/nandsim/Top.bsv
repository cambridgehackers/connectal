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
import MemServer::*;
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

module mkConnectalTop(ConnectalTop#(PhysAddrWidth,64,Empty,1));

   NandCfgIndicationProxy nandCfgIndicationProxy <- mkNandCfgIndicationProxy(IfcNames_NandCfgIndicationH2S);
   NandSim nandSim <- mkNandSim(nandCfgIndicationProxy.ifc);
   NandCfgRequestWrapper nandCfgRequestWrapper <- mkNandCfgRequestWrapper(IfcNames_NandCfgRequestS2H,nandSim.request);

   MMUIndicationProxy mmuMMUIndicationProxy <- mkMMUIndicationProxy(IfcNames_MMUIndicationH2S);
   MMU#(PhysAddrWidth) mmu <- mkMMU(0, True, mmuMMUIndicationProxy.ifc);
   MMURequestWrapper mmuMMURequestWrapper <- mkMMURequestWrapper(IfcNames_MMURequestS2H, mmu.request);

   MemServerIndicationProxy memServerIndicationProxy <- mkMemServerIndicationProxy(IfcNames_MemServerIndicationH2S);
   MemServer#(PhysAddrWidth,64,1) hostDma <- mkMemServer(nandSim.readClient, nandSim.writeClient, cons(mmu, nil), memServerIndicationProxy.ifc);
   MemServerRequestWrapper memServerRequestWrapper <- mkMemServerRequestWrapper(IfcNames_MemServerRequestS2H, hostDma.request);


   Vector#(6,StdPortal) portals;
   portals[0] = nandCfgRequestWrapper.portalIfc;
   portals[1] = nandCfgIndicationProxy.portalIfc;
   portals[2] = memServerRequestWrapper.portalIfc;
   portals[3] = memServerIndicationProxy.portalIfc;
   portals[4] = mmuMMURequestWrapper.portalIfc;
   portals[5] = mmuMMUIndicationProxy.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);

   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = hostDma.masters;
endmodule : mkConnectalTop
