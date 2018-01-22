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
import ConnectalMemory::*;
import MemServer::*;
import MemServerInternal::*;
import ConnectalMMU::*;
import ConnectalConfig::*;
import NandCfgRequest::*;
import MMURequest::*;
import RegexpRequest::*;
import NandCfgIndication::*;
import MemServerRequest::*;
import MemServerIndication::*;
import MMUIndication::*;
import RegexpIndication::*;
import NandSim::*;
import NandSimNames::*;
import Regexp::*;

module mkConnectalTop(ConnectalTop);
   
   // nandsim 
   NandCfgIndicationProxy nandSimIndicationProxy <- mkNandCfgIndicationProxy(IfcNames_NandCfgIndicationH2S);
   NandSim nandSim <- mkNandSim(nandSimIndicationProxy.ifc);
   NandCfgRequestWrapper nandSimRequestWrapper <- mkNandCfgRequestWrapper(IfcNames_NandCfgRequestS2H,nandSim.request);
   
   // regexp algo
   RegexpIndicationProxy regexpIndicationProxy <- mkRegexpIndicationProxy(IfcNames_AlgoIndicationH2S);
   Regexp#(64) regexp <- mkRegexp(regexpIndicationProxy.ifc);
   RegexpRequestWrapper regexpRequestWrapper <- mkRegexpRequestWrapper(IfcNames_AlgoRequestS2H,regexp.request);
   
   // backing store mmu
   MMUIndicationProxy mMUIndicationProxy <- mkMMUIndicationProxy(IfcNames_MMUIndicationH2S);
   MMU#(PhysAddrWidth) mMU <- mkMMU(0, True, mMUIndicationProxy.ifc);
   MMURequestWrapper mMURequestWrapper <- mkMMURequestWrapper(IfcNames_MMURequestS2H, mMU.request);

   // algo mmu
   MMUIndicationProxy algoMMUIndicationProxy <- mkMMUIndicationProxy(IfcNames_MMUIndicationH2S);
   MMU#(PhysAddrWidth) algoMMU <- mkMMU(1, True, algoMMUIndicationProxy.ifc);
   MMURequestWrapper algoMMURequestWrapper <- mkMMURequestWrapper(IfcNames_MMURequestS2H, algoMMU.request);
   
   // nandsim mmu
   MMUIndicationProxy nandsimMMUIndicationProxy <- mkMMUIndicationProxy(IfcNames_NandMMUIndicationH2S);
   MMU#(PhysAddrWidth) nandsimMMU <- mkMMU(0, False, nandsimMMUIndicationProxy.ifc);
   MMURequestWrapper nandsimMMURequestWrapper <- mkMMURequestWrapper(IfcNames_NandMMURequestS2H, nandsimMMU.request);
   
   // host memory dma server
   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(IfcNames_MemServerIndicationH2S);
   let rcs = append(regexp.config_read_client,nandSim.readClient);
   MemServer#(PhysAddrWidth,64,1) hostDma <- mkMemServer(rcs, nandSim.writeClient, cons(mMU,cons(algoMMU,nil)), hostMemServerIndicationProxy.ifc);
   MemServerRequestWrapper memServerRequestWrapper <- mkMemServerRequestWrapper(IfcNames_MemServerRequestS2H, hostDma.request);
   
   // nandsim memory dma server
   MemServerIndicationProxy nandsimMemServerIndicationProxy <- mkMemServerIndicationProxy(IfcNames_NandMemServerIndicationH2S);
   MemServer#(PhysAddrWidth,64,1) nandsimDma <- mkMemServer(regexp.haystack_read_client, nil, cons(nandsimMMU,nil), nandsimMemServerIndicationProxy.ifc);
   mkConnection(nandsimDma.masters[0], nandSim.memSlave);
   
   Vector#(13,StdPortal) portals;

   portals[0] = nandSimRequestWrapper.portalIfc;
   portals[1] = nandSimIndicationProxy.portalIfc; 

   portals[2] = regexpRequestWrapper.portalIfc;
   portals[3] = regexpIndicationProxy.portalIfc; 
   
   portals[4] = mMURequestWrapper.portalIfc;
   portals[5] = mMUIndicationProxy.portalIfc;

   portals[6] = nandsimMMURequestWrapper.portalIfc;
   portals[7] = nandsimMMUIndicationProxy.portalIfc;
   
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
