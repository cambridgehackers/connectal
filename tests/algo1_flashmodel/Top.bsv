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
import ConnectalConfig::*;
import SpecialFIFOs::*;
import Vector::*;
import BuildVector::*;
import StmtFSM::*;
import FIFO::*;
import BRAM::*;
import DefaultValue::*;
import Connectable::*;
import CtrlMux::*;
import Portal::*;
import HostInterface::*;
import ConnectalMemory::*;
import ConnectalMemTypes::*;
import MemServer::*;
import MemServerInternal::*;
import ConnectalMMU::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import MMURequest::*;
import StrstrRequest::*;
import MemServerIndication::*;
import MMUIndication::*;
import StrstrIndication::*;
import NandSimNames::*;
import Strstr::*;
import AuroraCommon::*;
import FlashTop::*;
import ControllerTypes::*;
import FlashRequest::*;
import FlashIndication::*;
import TopPins::*;

module mkConnectalTop#(HostInterface host)(ConnectalTop);
   
   Clock clk250 = host.derivedClock;
   Reset rst250 = host.derivedReset;
	
   // strstr algo
   StrstrIndicationProxy strstrIndicationProxy <- mkStrstrIndicationProxy(IfcNames_AlgoIndicationH2S);
   Strstr#(128,128) strstr <- mkStrstr(strstrIndicationProxy.ifc);
   StrstrRequestWrapper strstrRequestWrapper <- mkStrstrRequestWrapper(IfcNames_AlgoRequestS2H,strstr.request);
   
   // algo mmu
   MMUIndicationProxy algoMMUIndicationProxy <- mkMMUIndicationProxy(IfcNames_AlgoMMUIndicationH2S);
   MMU#(PhysAddrWidth) algoMMU <- mkMMU(0, True, algoMMUIndicationProxy.ifc);
   MMURequestWrapper algoMMURequestWrapper <- mkMMURequestWrapper(IfcNames_AlgoMMURequestS2H, algoMMU.request);

   // backing store mmu
   MMUIndicationProxy backingMMUIndicationProxy <- mkMMUIndicationProxy(IfcNames_BackingStoreMMUIndicationH2S);
   MMU#(PhysAddrWidth) backingMMU <- mkMMU(1, True, backingMMUIndicationProxy.ifc);
   MMURequestWrapper backingMMURequestWrapper <- mkMMURequestWrapper(IfcNames_BackingStoreMMURequestS2H, backingMMU.request);
   
   // nand mmu
   MMUIndicationProxy nandMMUIndicationProxy <- mkMMUIndicationProxy(IfcNames_NandMMUIndicationH2S);
   MMU#(FlashAddrWidth) nandMMU <- mkMMU(0, False, nandMMUIndicationProxy.ifc);
   MMURequestWrapper nandMMURequestWrapper <- mkMMURequestWrapper(IfcNames_NandMMURequestS2H, nandMMU.request);

   // flash top
   FlashIndicationProxy flashIndicationProxy <- mkFlashIndicationProxy(IfcNames_NandCfgIndicationH2S);
   FlashTop flashtop <- mkFlashTop(flashIndicationProxy.ifc, clk250, rst250);
   FlashRequestWrapper flashRequestWrapper <- mkFlashRequestWrapper(IfcNames_NandCfgRequestS2H,flashtop.request);
   
   // host memory server
   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(IfcNames_MemServerIndicationH2S);
   let rcs = append(strstr.config_read_client,flashtop.hostMemReadClient);
   let wcs = flashtop.hostMemWriteClient;
   MemServer#(PhysAddrWidth,DataBusWidth,1) hostMemServer <- mkMemServer(rcs,wcs,vec(algoMMU,backingMMU), hostMemServerIndicationProxy.ifc);

   // flash memory read server
   MemServerIndicationProxy flashMemServerIndicationProxy <- mkMemServerIndicationProxy(IfcNames_NandMemServerIndicationH2S);
   MemServer#(FlashAddrWidth,FlashDataWidth,1) flashMemServer <- mkMemServer(strstr.haystack_read_client, nil, vec(nandMMU),
									     flashMemServerIndicationProxy.ifc);
   mkConnection(flashMemServer.masters[0], flashtop.memSlave);
   
   Vector#(12,StdPortal) portals;

   portals[0] = strstrRequestWrapper.portalIfc;
   portals[1] = strstrIndicationProxy.portalIfc; 

   portals[2] = algoMMURequestWrapper.portalIfc;
   portals[3] = algoMMUIndicationProxy.portalIfc;
   
   portals[4] = nandMMURequestWrapper.portalIfc;
   portals[5] = nandMMUIndicationProxy.portalIfc; 
   
   portals[6] = flashRequestWrapper.portalIfc;
   portals[7] = flashIndicationProxy.portalIfc;
   
   portals[8] = hostMemServerIndicationProxy.portalIfc;
   //portals[9] = hostMemServerRequestWrapper.portalIfc;
   portals[9] = flashMemServerIndicationProxy.portalIfc;
   
   portals[10] = backingMMURequestWrapper.portalIfc;
   portals[11] = backingMMUIndicationProxy.portalIfc;


   let ctrl_mux <- mkSlaveMux(portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = hostMemServer.masters;
   interface Top_Pins pins;
      interface Aurora_Pins aurora_fmc1 = flashtop.aurora_fmc1;
      interface Aurora_Clock_Pins aurora_clk_fmc1 = flashtop.aurora_clk_fmc1;
   endinterface
endmodule : mkConnectalTop
