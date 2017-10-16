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
import CtrlMux::*;
import Portal::*;
import HostInterface::*;
import ConnectalMemory::*;
import DmaUtils::*;
import ConnectalMemTypes::*;
import MemServer::*;
import ConnectalMMU::*;
import PerfRequest::*;
import MemServerRequest::*;
import MMURequest::*;
import PerfIndication::*;
import MemServerIndication::*;
import MMUIndication::*;
import Perf::*;

typedef enum {IfcNames_PerfIndication, IfcNames_PerfRequest, IfcNames_HostMemServerIndication, IfcNames_HostMemServerRequest, IfcNames_HostMMURequest, IfcNames_HostMMUIndication} IfcNames deriving (Eq,Bits);

module mkConnectalTop(StdConnectalDmaTop#(PhysAddrWidth));

   DmaReadBuffer#(64,8)   dma_stream_read_chan <- mkDmaReadBuffer();
   DmaWriteBuffer#(64,8) dma_stream_write_chan <- mkDmaWriteBuffer();
   DmaReadBuffer#(64,8)     dma_word_read_chan <- mkDmaReadBuffer();
   DmaWriteBuffer#(64,8)  dma_debug_write_chan <- mkDmaWriteBuffer();

   Vector#(2,  MemReadClient#(64))   readClients = newVector();
   readClients[0] = dma_stream_read_chan.dmaClient;
   readClients[1] = dma_word_read_chan.dmaClient;

   Vector#(2, MemWriteClient#(64)) writeClients = newVector();
   writeClients[0] = dma_stream_write_chan.dmaClient;
   writeClients[1] = dma_debug_write_chan.dmaClient;

   MMUIndicationProxy hostMMUIndicationProxy <- mkMMUIndicationProxy(IfcNames_HostMMUIndication);
   MMU#(PhysAddrWidth) hostMMU <- mkMMU(0, True, hostMMUIndicationProxy.ifc);
   MMURequestWrapper hostMMURequestWrapper <- mkMMURequestWrapper(IfcNames_HostMMURequest, hostMMU.request);

   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(IfcNames_HostMemServerIndication);
   MemServer#(PhysAddrWidth,64,1) dma <- mkMemServer(readClients, writeClients, cons(hostMMU,nil), hostMemServerIndicationProxy.ifc);
   MemServerRequestWrapper hostMemServerRequestWrapper <- mkMemServerRequestWrapper(IfcNames_HostMemServerRequest, dma.request);

   PerfIndicationProxy perfIndicationProxy <- mkPerfIndicationProxy(IfcNames_PerfIndication);
   PerfRequest perfRequest <- mkPerfRequest(perfIndicationProxy.ifc, dma_stream_read_chan.dmaServer,
						  dma_stream_write_chan.dmaServer, dma_word_read_chan.dmaServer);
   PerfRequestWrapper perfRequestWrapper <- mkPerfRequestWrapper(IfcNames_PerfRequest,perfRequest);

   Vector#(6,StdPortal) portals;
   portals[0] = perfRequestWrapper.portalIfc;
   portals[1] = perfIndicationProxy.portalIfc; 
   portals[2] = hostMemServerRequestWrapper.portalIfc;
   portals[3] = hostMemServerIndicationProxy.portalIfc; 
   portals[4] = hostMMURequestWrapper.portalIfc;
   portals[5] = hostMMUIndicationProxy.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = dma.masters;
endmodule


