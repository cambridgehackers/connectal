// Copyright (c) 2013 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// BSV Libraries
import FIFO::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import Assert::*;

// XBSV Libraries
import Dma::*;
import PortalMemory::*;
import SGList::*;
import MemServerInternal::*;
		 		 
typedef struct {ObjectRequest req;
		Bit#(addrWidth) pa;
		ClientId client; } IRec#(numeric type addrWidth) deriving(Bits);

instance MemServerInternals#(InOrderCompletion, addrWidth, dataWidth)	 
provisos(Add#(b__, addrWidth, 64), 
	 Add#(c__, 12, addrWidth), 
	 Add#(1, c__, d__),
	 Div#(dataWidth,8,dataWidthBytes),
	 Mul#(dataWidthBytes,8,dataWidth),
	 Log#(dataWidthBytes,beatShift));
   
module mkMemReadInternal#(Vector#(numReadClients, ObjectReadClient#(dataWidth)) readClients, 
			  DmaIndication dmaIndication,
			  Server#(Tuple2#(SGListId,Bit#(ObjectOffsetSize)),Bit#(addrWidth)) sgl) 
   (MemReadInternal#(InOrderCompletion, addrWidth, dataWidth));
   
   FIFO#(IRec#(addrWidth)) lreqFifo <- mkSizedFIFO(1);
   FIFO#(IRec#(addrWidth))  reqFifo <- mkSizedFIFO(1);
   Vector#(numReadClients, FIFO#(ObjectRequest)) dreqFifos <- replicateM(mkSizedFIFO(32)); // too big? (mdk)
   Vector#(numReadClients, Reg#(Bit#(8)))        burstRegs <- replicateM(mkReg(0));
   Vector#(numReadClients, Reg#(Bit#(64)))      beatCounts <- replicateM(mkReg(0));
   let beat_shift = fromInteger(valueOf(beatShift));

`ifdef	INTERVAL_ANAlYSIS
   Reg#(Bit#(32)) bin1 <- mkReg(0);
   Reg#(Bit#(32)) bin4 <- mkReg(0);
   Reg#(Bit#(32)) binx <- mkReg(0);
   Reg#(Bit#(64)) cycle_cnt <- mkReg(0);
   Reg#(Bit#(64)) last_resp_read <- mkReg(0);
   (* fire_when_enabled *)
   rule cycle;
      cycle_cnt <= cycle_cnt+1;
   endrule
`endif
      
   for (Integer selectReg = 0; selectReg < valueOf(numReadClients); selectReg = selectReg + 1)
      rule loadClient;
	 ObjectRequest req <- readClients[selectReg].readReq.get();
	 if (bad_pointer(req.pointer))
	    dmaIndication.badPointer(req.pointer);
	 else begin
	    lreqFifo.enq(IRec{req:req, pa:?, client:fromInteger(selectReg)});
	    sgl.request.put(tuple2(truncate(req.pointer),req.offset));
	 end
      endrule
   
   rule checkSglResp;
      let physAddr <- sgl.response.get;
      let req = lreqFifo.first.req;
      let client = lreqFifo.first.client;
      lreqFifo.deq();
      if (physAddr <= (1 << valueOf(SGListPageShift0))) begin
	 // squash request
	 $display("dmaRead: badAddr pointer=%d offset=%h physAddr=%h", req.pointer, req.offset, physAddr);
	 dmaIndication.badAddr(req.pointer, extend(req.offset), extend(physAddr));
      end
      else begin
	 if (False && physAddr[31:24] != 0)
	    $display("checkSglResp: funny physAddr req.pointer=%d req.offset=%h physAddr=%h", req.pointer, req.offset, physAddr);
	 reqFifo.enq(IRec{req:req, pa:physAddr, client:client});
      end
   endrule

   interface MemReadClient read_client;
      interface Get readReq;
	 method ActionValue#(MemRequest#(addrWidth)) get() if (valueOf(numReadClients) > 0);
	    let rv = ?;
	    if (valueOf(numReadClients) > 0) begin
	       reqFifo.deq;
	       let req = reqFifo.first.req;
	       let physAddr = reqFifo.first.pa;
	       let client = reqFifo.first.client;
	       if (False && physAddr[31:24] != 0)
		  $display("req_ar: funny physAddr req.pointer=%d req.offset=%h physAddr=%h", req.pointer, req.offset, physAddr);
	       dreqFifos[client].enq(req);
	       rv = MemRequest{addr:physAddr, burstLen:req.burstLen, tag:extend(client)};
	    end
	    return rv;
	 endmethod
      endinterface
      interface Put readData;
	 method Action put(MemData#(dataWidth) response);
	    if (valueOf(numReadClients) > 0) begin
	       let client = response.tag;
	       let req = dreqFifos[client].first;
	       let burstLen = burstRegs[client];
	       readClients[client].readData.put(ObjectData { data: response.data, tag: req.tag});
	       if (burstLen == 0)
		  burstLen = req.burstLen >> beat_shift;
	       if (burstLen == 1)
		  dreqFifos[client].deq();
	       burstRegs[client] <= burstLen-1;
	       beatCounts[client] <= beatCounts[client]+1;
	    end
`ifdef INTERVAL_ANAlYSIS
	    last_resp_read <= cycle_cnt;
	    let interval = cycle_cnt - last_resp_read;
	    if (interval <= 1)
	       bin1 <= bin1+1;
	    else if (interval <= 4)
	       bin4 <= bin4+1;
	    else
	       binx <= binx+1;
`endif
	 endmethod
      endinterface
   endinterface
   interface DmaDbg dbg;
      method ActionValue#(DmaDbgRec) dbg();
`ifdef INTERVAL_ANAlYSIS
	 return DmaDbgRec{x:fromInteger(valueOf(numReadClients)), y:bin1, z:bin4, w:binx};
`else
	 return DmaDbgRec{x:fromInteger(valueOf(numReadClients)), y:0, z:0, w:0};
`endif
      endmethod
      method ActionValue#(Bit#(64)) getMemoryTraffic(Bit#(32) client);
	 return (valueOf(numReadClients) > 0 && client < fromInteger(valueOf(numReadClients))) ? beatCounts[client] : 0;
      endmethod
   endinterface
endmodule


module mkMemWriteInternal#(Vector#(numWriteClients, ObjectWriteClient#(dataWidth)) writeClients,
			   DmaIndication dmaIndication, 
			   Server#(Tuple2#(SGListId,Bit#(ObjectOffsetSize)),Bit#(addrWidth)) sgl)
   (MemWriteInternal#(InOrderCompletion, addrWidth, dataWidth));
   
   FIFO#(IRec#(addrWidth)) lreqFifo <- mkSizedFIFO(1);
   FIFO#(IRec#(addrWidth))  reqFifo <- mkSizedFIFO(1);
   FIFO#(IRec#(addrWidth)) dreqFifo <- mkSizedFIFO(32);
   Vector#(numWriteClients, FIFO#(Bit#(6))) respFifos <- replicateM(mkSizedFIFO(32)); // too big? (mdk)
   Reg#(Bit#(8)) burstReg <- mkReg(0);   
   Vector#(numWriteClients, Reg#(Bit#(64))) beatCounts <- replicateM(mkReg(0));
   let beat_shift = fromInteger(valueOf(beatShift));
   
   for (Integer selectReg = 0; selectReg < valueOf(numWriteClients); selectReg = selectReg + 1)
       rule loadClient;
	  ObjectRequest req <- writeClients[selectReg].writeReq.get();
	  if (bad_pointer(req.pointer))
	     dmaIndication.badPointer(req.pointer);
	  else begin
	     lreqFifo.enq(IRec{req:req, pa:?, client:fromInteger(selectReg)});
	     sgl.request.put(tuple2(truncate(req.pointer),req.offset));
	  end
       endrule
   
   rule checkSglResp;
      let physAddr <- sgl.response.get;
      let req = lreqFifo.first.req;
      let client = lreqFifo.first.client;
      lreqFifo.deq();
      if (physAddr <= (1 << valueOf(SGListPageShift0))) begin
	 // squash request
	 $display("dmaWrite: badAddr handle=%d addr=%h physAddr=%h", req.pointer, req.offset, physAddr);
	 dmaIndication.badAddr(req.pointer, extend(req.offset), extend(physAddr));
      end
      else begin
	 reqFifo.enq(IRec{req:req, pa:physAddr, client:client});
      end
   endrule

   interface MemWriteClient write_client;
      interface Get writeReq;
	 method ActionValue#(MemRequest#(addrWidth)) get();
	    let req = reqFifo.first.req;
	    let physAddr = reqFifo.first.pa;
	    let client = reqFifo.first.client;
	    reqFifo.deq;
	    dreqFifo.enq(reqFifo.first);
	    return MemRequest{addr:physAddr, burstLen:req.burstLen, tag:extend(client)};
	 endmethod
      endinterface
      interface Get writeData;
	 method ActionValue#(MemData#(dataWidth)) get() if (valueOf(numWriteClients) > 0);
	    let rv = ?;
	    if (valueOf(numWriteClients) > 0) begin
	       let client = dreqFifo.first.client;
	       let req = dreqFifo.first.req;
	       ObjectData#(dataWidth) tagdata <- writeClients[client].writeData.get();
	       let burstLen = burstReg;
	       if (burstLen == 0)
		  burstLen = req.burstLen >> beat_shift;
	       burstReg <= burstLen-1;
	       beatCounts[client] <= beatCounts[client]+1;
	       if (burstLen == 1) begin
		  dreqFifo.deq();
		  respFifos[client].enq(req.tag);
	       end
	       rv = MemData { data: tagdata.data,  tag:extend(client) };
	    end
	    return rv;
	 endmethod
      endinterface
      interface Put writeDone;
	 method Action put(Bit#(6) resp);
	    if (valueOf(numWriteClients) > 0) begin
	       let client = resp;
	       let orig_tag = respFifos[resp].first;
	       respFifos[client].deq;
	       writeClients[client].writeDone.put(orig_tag);
	    end
	 endmethod
      endinterface
   endinterface
   interface DmaDbg dbg;
      method ActionValue#(DmaDbgRec) dbg();
	 return DmaDbgRec{x:fromInteger(valueOf(numWriteClients)), y:?, z:?, w:?};
      endmethod
      method ActionValue#(Bit#(64)) getMemoryTraffic(Bit#(32) client);
	 return (valueOf(numWriteClients) > 0 && client < fromInteger(valueOf(numWriteClients))) ? beatCounts[client] : 0;
      endmethod
   endinterface
endmodule
endinstance   
