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
import MemServerCompat::*;
import MemServerInternal::*;
import MMU::*;
import HostInterface::*;
import NandCfgRequest::*;
import MMURequest::*;
import RegexpRequest::*;
import NandCfgIndication::*;
import MemServerIndication::*;
import MMUIndication::*;
import RegexpIndication::*;
import NandSim::*;
import NandSimNames::*;
import Regexp::*;

module mkConnectalTop(StdConnectalDmaTop#(PhysAddrWidth));
   
   // nandsim 
   NandCfgIndicationProxy nandSimIndicationProxy <- mkNandCfgIndicationProxy(NandCfgIndication);
   NandSim nandSim <- mkNandSim(nandSimIndicationProxy.ifc);
   NandCfgRequestWrapper nandSimRequestWrapper <- mkNandCfgRequestWrapper(NandCfgRequest,nandSim.request);
   
   // regexp algo
   RegexpIndicationProxy regexpIndicationProxy <- mkRegexpIndicationProxy(AlgoIndication);
   Regexp#(64) regexp <- mkRegexp(regexpIndicationProxy.ifc);
   RegexpRequestWrapper regexpRequestWrapper <- mkRegexpRequestWrapper(AlgoRequest,regexp.request);
   
   // backing store mmu
   MMUIndicationProxy backingStoreMMUIndicationProxy <- mkMMUIndicationProxy(BackingStoreMMUIndication);
   MMU#(PhysAddrWidth) backingStoreMMU <- mkMMU(0, True, backingStoreMMUIndicationProxy.ifc);
   MMURequestWrapper backingStoreMMURequestWrapper <- mkMMURequestWrapper(BackingStoreMMURequest, backingStoreMMU.request);

   // algo mmu
   MMUIndicationProxy algoMMUIndicationProxy <- mkMMUIndicationProxy(AlgoMMUIndication);
   MMU#(PhysAddrWidth) algoMMU <- mkMMU(1, True, algoMMUIndicationProxy.ifc);
   MMURequestWrapper algoMMURequestWrapper <- mkMMURequestWrapper(AlgoMMURequest, algoMMU.request);
   
   // nandsim mmu
   MMUIndicationProxy nandsimMMUIndicationProxy <- mkMMUIndicationProxy(NandMMUIndication);
   MMU#(PhysAddrWidth) nandsimMMU <- mkMMU(0, False, nandsimMMUIndicationProxy.ifc);
   MMURequestWrapper nandsimMMURequestWrapper <- mkMMURequestWrapper(NandMMURequest, nandsimMMU.request);
   
   // host memory dma server
   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(HostMemServerIndication);
   let rcs = append(regexp.config_read_client,nandSim.readClient);
   MemServerCompat#(PhysAddrWidth,64,1) hostDma <- mkMemServerCompat(rcs, nandSim.writeClient, cons(backingStoreMMU,cons(algoMMU,nil)), hostMemServerIndicationProxy.ifc);
   
   // nandsim memory dma server
   MemServerIndicationProxy nandsimMemServerIndicationProxy <- mkMemServerIndicationProxy(NandMemServerIndication);
   MemServerCompat#(PhysAddrWidth,64,1) nandsimDma <- mkMemServerCompat(regexp.haystack_read_client, nil, cons(nandsimMMU,nil), nandsimMemServerIndicationProxy.ifc);
   mkConnection(nandsimDma.masters[0], nandSim.memSlave);
   
   Vector#(12,StdPortal) portals;

   portals[0] = nandSimRequestWrapper.portalIfc;
   portals[1] = nandSimIndicationProxy.portalIfc; 

   portals[2] = regexpRequestWrapper.portalIfc;
   portals[3] = regexpIndicationProxy.portalIfc; 
   
   portals[4] = backingStoreMMURequestWrapper.portalIfc;
   portals[5] = backingStoreMMUIndicationProxy.portalIfc;

   portals[6] = nandsimMMURequestWrapper.portalIfc;
   portals[7] = nandsimMMUIndicationProxy.portalIfc;
   
   portals[8] = algoMMURequestWrapper.portalIfc;
   portals[9] = algoMMUIndicationProxy.portalIfc;
   
   portals[10] = hostMemServerIndicationProxy.portalIfc;
   portals[11] = nandsimMemServerIndicationProxy.portalIfc;
   
   let ctrl_mux <- mkSlaveMux(portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = hostDma.masters;
endmodule : mkConnectalTop
