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
import GetPut::*;
import ClientServer::*;
import Connectable::*;
import PCIE::*;
import CtrlMux::*;
import Portal::*;
import ConnectalMemory::*;
import MemTypes::*;
import MemServer::*;
import MMU::*;
import HostInterface::*;
import MemSlaveEngine::*;
import MemwriteRequest::*;
import MemServerRequest::*;
import MMURequest::*;
import MemwriteIndication::*;
import MemServerIndication::*;
import MMUIndication::*;
import Memwrite::*;

typedef enum {MemServerIndicationH2S, MemServerRequestS2H, MMURequestS2H, MMUIndicationH2S, MemwriteIndicationH2S, MemwriteRequestS2H} IfcNames deriving (Eq,Bits);

module mkConnectalTop(ConnectalTop#(PhysAddrWidth,DataBusWidth,Empty,1));

   MemwriteIndicationProxy memwriteIndicationProxy <- mkMemwriteIndicationProxy(MemwriteIndicationH2S);
   Memwrite memwrite <- mkMemwrite(memwriteIndicationProxy.ifc);
   MemwriteRequestWrapper memwriteRequestWrapper <- mkMemwriteRequestWrapper(MemwriteRequestS2H,memwrite.request);

   MMUIndicationProxy hostMMUIndicationProxy <- mkMMUIndicationProxy(MMUIndicationH2S);
   MMU#(PhysAddrWidth) hostMMU <- mkMMU(0, True, hostMMUIndicationProxy.ifc);
   MMURequestWrapper hostMMURequestWrapper <- mkMMURequestWrapper(MMURequestS2H, hostMMU.request);

   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(MemServerIndicationH2S);
   MemServer#(PhysAddrWidth,DataBusWidth,1) dma <- mkMemServer(nil, memwrite.dmaClient, cons(hostMMU,nil), hostMemServerIndicationProxy.ifc);
   MemServerRequestWrapper hostMemServerRequestWrapper <- mkMemServerRequestWrapper(MemServerRequestS2H, dma.request);

   PhysMemMaster#(PhysAddrWidth,DataBusWidth) dma1 = (interface PhysMemMaster;
	  interface PhysMemReadClient read_client;
	     interface Get readReq;
		method ActionValue#(PhysMemRequest#(PhysAddrWidth)) get() if (False);
		   return ?;
	        endmethod
	     endinterface
	  endinterface
	  interface PhysMemWriteClient write_client;
	     interface Get writeReq;
		method ActionValue#(PhysMemRequest#(PhysAddrWidth)) get() if (False);
		   return ?;
	        endmethod
	     endinterface
	  endinterface
      endinterface);

   Reg#(Bit#(32)) cycles <- mkReg(0);
   Reg#(Bit#(32)) reqCycles <- mkReg(0);
   Reg#(Bit#(32)) dataCycles <- mkReg(0);
   rule count;
      cycles <= cycles + 1;
   endrule

   rule startdump if (cycles == 1);
      $dumpvars();
   endrule

   rule finish if (reqCycles == 10000);
      $dumpoff();
   endrule

   MemSlaveEngine#(DataBusWidth) memSlaveEngine <- mkMemSlaveEngine(PciId {bus: 4, dev: 2, func: 0});
   mkConnection(dma.masters[0], memSlaveEngine.slave);

   rule displayTlp;
      let tlp <- memSlaveEngine.tlp.request.get();
      TLPMemory4DWHeader hdr4dw = unpack(tlp.data);
      TLPMemoryIO3DWHeader hdr3dw = unpack(tlp.data);
      let newReqCycles = reqCycles;
      if (tlp.sof && hdr4dw.format == MEM_WRITE_4DW_DATA) begin
	 $display("%d 4dw req %h %d", cycles-reqCycles, hdr4dw.addr<<2, fromInteger(valueOf(DataBusWidth)));
	 newReqCycles = cycles;
      end
      else if (tlp.sof && hdr3dw.format == MEM_WRITE_3DW_DATA) begin
	 $display("%d 3dw req %h %d", cycles-reqCycles, hdr4dw.addr<<2, fromInteger(valueOf(DataBusWidth)));
	 newReqCycles = cycles;
      end
      else if (tlp.sof) begin
	 $display("%d sof %h", cycles-reqCycles, tlp.data);
	 newReqCycles = cycles;
      end
      else begin
	 $display("%d data %h", cycles-reqCycles, tlp.data);
	 dataCycles <= cycles;
	 newReqCycles = cycles;
      end
      reqCycles <= newReqCycles;
   endrule

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
   interface masters = cons(dma1,nil);
endmodule
