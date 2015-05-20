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
import Connectable::*;
import CtrlMux::*;
import Portal::*;
import HostInterface::*;
import ConnectalMemory::*;
import MemServer::*;
import MMU::*;
import MemUtils::*;
import MemServerRequest::*;
import MMURequest::*;
import MemServerIndication::*;
import MMUIndication::*;
import MmIndication::*;
import TimerIndication::*;
import TimerRequest::*;
import RbmRequest::*;
import RbmIndication::*;
import SigmoidRequest::*;
import SigmoidIndication::*;
import MatrixTN::*;
import MmRequestTN::*;
import RbmTypes::*;
import Sigmoid::*;
import Rbm::*;

module  mkConnectalTop#(HostInterface host) (ConnectalTop#(PhysAddrWidth,TMul#(32,N),Empty,NumberOfMasters));

   RbmIndicationProxy rbmIndicationProxy <- mkRbmIndicationProxy(IfcNames_RbmIndicationPortal);
   MmIndicationProxy   mmIndicationProxy <- mkMmIndicationProxy(IfcNames_MmIndicationPortal);
   SigmoidIndicationProxy   sigmoidIndicationProxy <- mkSigmoidIndicationProxy(IfcNames_SigmoidIndicationPortal);
   TimerIndicationProxy timerIndicationProxy <- mkTimerIndicationProxy(IfcNames_TimerIndicationPortal);

   Rbm#(N) rbm <- mkRbm(host,rbmIndicationProxy.ifc,sigmoidIndicationProxy.ifc, mmIndicationProxy.ifc, timerIndicationProxy.ifc);
   RbmRequestWrapper rbmRequestWrapper <- mkRbmRequestWrapper(IfcNames_RbmRequestPortal,rbm.rbmRequest);
   MmRequestTNWrapper mmRequestWrapper <- mkMmRequestTNWrapper(IfcNames_MmRequestPortal,rbm.mmRequest);
   SigmoidRequestWrapper   sigmoidRequestWrapper <- mkSigmoidRequestWrapper(IfcNames_SigmoidRequestPortal,rbm.sigmoidRequest);
   TimerRequestWrapper timerRequestWrapper <- mkTimerRequestWrapper(IfcNames_TimerRequestPortal,rbm.timerRequest);

   MMUIndicationProxy hostMMUIndicationProxy <- mkMMUIndicationProxy(IfcNames_HostMMUIndication);
   MMU#(PhysAddrWidth) hostMMU <- mkMMU(0, True, hostMMUIndicationProxy.ifc);
   MMURequestWrapper hostMMURequestWrapper <- mkMMURequestWrapper(IfcNames_HostMMURequest, hostMMU.request);

   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(IfcNames_HostMemServerIndication);
   MemServer#(PhysAddrWidth, TMul#(32,N), NumberOfMasters) dma <- mkMemServer(rbm.readClients, rbm.writeClients, cons(hostMMU,nil), hostMemServerIndicationProxy.ifc);
   MemServerRequestWrapper hostMemServerRequestWrapper <- mkMemServerRequestWrapper(IfcNames_HostMemServerRequest, dma.request);

   Vector#(12,StdPortal) portals;
   portals[0] = mmRequestWrapper.portalIfc;
   portals[1] = mmIndicationProxy.portalIfc; 
   portals[2] = hostMemServerRequestWrapper.portalIfc;
   portals[3] = hostMemServerIndicationProxy.portalIfc; 
   portals[4] = timerRequestWrapper.portalIfc;
   portals[5] = timerIndicationProxy.portalIfc; 
   portals[6] = sigmoidRequestWrapper.portalIfc;
   portals[7] = sigmoidIndicationProxy.portalIfc;
   portals[8] = rbmRequestWrapper.portalIfc;
   portals[9] = rbmIndicationProxy.portalIfc;
   portals[10] = hostMMURequestWrapper.portalIfc;
   portals[11] = hostMMUIndicationProxy.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = dma.masters;
endmodule : mkConnectalTop
