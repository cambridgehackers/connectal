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
import MemServerInternal::*;
import MMU::*;
import NandCfgRequest::*;
import MMURequest::*;
import StrstrRequest::*;
import NandCfgIndication::*;
import MemServerRequest::*;
import MemServerIndication::*;
import MMUIndication::*;
import StrstrIndication::*;
import NandSim::*;
import NandSimNames::*;
import Strstr::*;

module mkConnectalTop(ConnectalTop#(PhysAddrWidth,64,Empty,1));
   
   // nandsim 
   NandCfgIndicationProxy nandCfgIndicationProxy <- mkNandCfgIndicationProxy(IfcNames_NandCfgIndicationH2S);
   NandSim nandSim <- mkNandSim(nandCfgIndicationProxy.ifc);
   NandCfgRequestWrapper nandCfgRequestWrapper <- mkNandCfgRequestWrapper(IfcNames_NandCfgRequestS2H,nandSim.request);
   
   // strstr algo
   StrstrIndicationProxy strstrIndicationProxy <- mkStrstrIndicationProxy(IfcNames_AlgoIndicationH2S);
   Strstr#(64,64) strstr <- mkStrstr(strstrIndicationProxy.ifc);
   StrstrRequestWrapper strstrRequestWrapper <- mkStrstrRequestWrapper(IfcNames_AlgoRequestS2H,strstr.request);
   
   // backing store mmu
   MMUIndicationProxy backingStoreMMUIndicationProxy <- mkMMUIndicationProxy(IfcNames_BackingStoreMMUIndicationH2S);
   MMU#(PhysAddrWidth) backingStoreMMU <- mkMMU(0, True, backingStoreMMUIndicationProxy.ifc);
   MMURequestWrapper backingStoreMMURequestWrapper <- mkMMURequestWrapper(IfcNames_BackingStoreMMURequestS2H, backingStoreMMU.request);

   // algo mmu
   MMUIndicationProxy algoMMUIndicationProxy <- mkMMUIndicationProxy(IfcNames_MMUIndicationH2S);
   MMU#(PhysAddrWidth) algoMMU <- mkMMU(1, True, algoMMUIndicationProxy.ifc);
   MMURequestWrapper algoMMURequestWrapper <- mkMMURequestWrapper(IfcNames_MMURequestS2H, algoMMU.request);
   
   // nandsim mmu
   MMUIndicationProxy nandMMUIndicationProxy <- mkMMUIndicationProxy(IfcNames_NandMMUIndicationH2S);
   MMU#(PhysAddrWidth) nandMMU <- mkMMU(0, False, nandMMUIndicationProxy.ifc);
   MMURequestWrapper nandMMURequestWrapper <- mkMMURequestWrapper(IfcNames_NandMMURequestS2H, nandMMU.request);
   
   // host memory dma server
   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(IfcNames_MemServerIndicationH2S);
   let rcs = append(strstr.config_read_client,nandSim.readClient);
   MemServer#(PhysAddrWidth,64,1) hostDma <- mkMemServer(rcs, nandSim.writeClient, cons(backingStoreMMU,cons(algoMMU,nil)), hostMemServerIndicationProxy.ifc);
   MemServerRequestWrapper memServerRequestWrapper <- mkMemServerRequestWrapper(IfcNames_MemServerRequestS2H, hostDma.request);

   // nandsim memory dma server
   MemServerIndicationProxy nandsimMemServerIndicationProxy <- mkMemServerIndicationProxy(IfcNames_NandMemServerIndicationH2S);
   MemServer#(PhysAddrWidth,64,1) nandsimDma <- mkMemServer(strstr.haystack_read_client, nil, cons(nandMMU,nil), nandsimMemServerIndicationProxy.ifc);
   mkConnection(nandsimDma.masters[0], nandSim.memSlave);
   
   Vector#(13,StdPortal) portals;

   portals[0] = nandCfgRequestWrapper.portalIfc;
   portals[1] = nandCfgIndicationProxy.portalIfc;

   portals[2] = strstrRequestWrapper.portalIfc;
   portals[3] = strstrIndicationProxy.portalIfc; 
   
   portals[4] = backingStoreMMURequestWrapper.portalIfc;
   portals[5] = backingStoreMMUIndicationProxy.portalIfc;

   portals[6] = nandMMURequestWrapper.portalIfc;
   portals[7] = nandMMUIndicationProxy.portalIfc;
   
   portals[8] = algoMMURequestWrapper.portalIfc;
   portals[9] = algoMMUIndicationProxy.portalIfc;
   
   portals[10] = hostMemServerIndicationProxy.portalIfc;
   portals[11] = nandsimMemServerIndicationProxy.portalIfc;
   portals[12] = memServerRequestWrapper.portalIfc;
   
   let ctrl_mux <- mkSlaveMux(portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = hostDma.masters;
endmodule : mkConnectalTop
