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
		 		 
interface TagGen#(numeric type numTags);
   method ActionValue#(Bit#(TLog#(numTags))) get_tag(ClientId client, Bit#(6) client_tag);
   method Action return_tag(Bit#(TLog#(numTags)) tag);
endinterface

module mkTagGenOO(TagGen#(numTags));
   
   Vector#(numTags, Reg#(Bit#(4))) tag_regs <- replicateM(mkReg(0));
   Vector#(numTags, Reg#(Maybe#(ClientId))) client_map <- replicateM(mkReg(tagged Invalid));
   Maybe#(UInt#(TLog#(numTags))) next_free = findElem(0, readVReg(tag_regs));
   
   method ActionValue#(Bit#(TLog#(numTags))) get_tag(ClientId client, Bit#(6) client_tag);
      let rv = case (findElem(tagged Valid client, readVReg(client_map))) matches
		  tagged Valid .tag: return (_when_(tag_regs[tag] < maxBound) (tag));
		  tagged Invalid: return (_when_(isValid(next_free)) (fromMaybe(?, next_free)));
	       endcase;
      client_map[rv] <= tagged Valid client;
      tag_regs[rv] <= tag_regs[rv]+1;
      return pack(rv);
   endmethod      
   
   method Action return_tag(Bit#(TLog#(numTags)) tag);
      tag_regs[tag] <= tag_regs[tag]-1;
   endmethod
   
endmodule

typedef struct {ObjectRequest req;
		ClientId client; } LRec#(numeric type addrWidth) deriving(Bits);

typedef struct {ObjectRequest req;
		Bit#(addrWidth) pa;
		Bit#(6) rename_tag;
		ClientId client; } RRec#(numeric type addrWidth) deriving(Bits);

typedef struct {ObjectRequest req;
		Bit#(6) rename_tag;
		ClientId client; } DRec#(numeric type addrWidth) deriving(Bits);

typedef struct {Bit#(6) orig_tag;
		ClientId client; } RResp#(numeric type addrWidth) deriving(Bits);

typedef 32 NumTags;

instance MemServerInternals#(OutOfOrderCompletion, addrWidth, dataWidth)	 
provisos(Add#(b__, addrWidth, 64), 
	 Add#(c__, 12, addrWidth), 
	 Add#(1, c__, d__),
	 Div#(dataWidth,8,dataWidthBytes),
	 Mul#(dataWidthBytes,8,dataWidth),
	 Log#(dataWidthBytes,beatShift));

module mkMemReadInternal#(Vector#(numReadClients, ObjectReadClient#(dataWidth)) readClients, 
			  DmaIndication dmaIndication,
			  Server#(Tuple2#(SGListId,Bit#(ObjectOffsetSize)),Bit#(addrWidth)) sgl) 
   (MemReadInternal#(OutOfOrderCompletion, addrWidth, dataWidth));
   
   FIFO#(LRec#(addrWidth)) lreqFifo <- mkSizedFIFO(1);
   FIFO#(RRec#(addrWidth))  reqFifo <- mkSizedFIFO(1);
   Vector#(NumTags, FIFO#(DRec#(addrWidth))) dreqFifos <- replicateM(mkSizedFIFO(4));
   Vector#(NumTags, Reg#(Bit#(8)))           burstRegs <- replicateM(mkReg(0));
   Vector#(numReadClients, Reg#(Bit#(64)))  beatCounts <- replicateM(mkReg(0));
   let beat_shift = fromInteger(valueOf(beatShift));
   TagGen#(NumTags) tag_gen <- mkTagGenOO;
      
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
	    lreqFifo.enq(LRec{req:req, client:fromInteger(selectReg)});
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
	 let rename_tag <- tag_gen.get_tag(client, req.tag);
	 reqFifo.enq(RRec{req:req, pa:physAddr, client:client, rename_tag:extend(rename_tag)});
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
	       let rename_tag = reqFifo.first.rename_tag;
	       if (False && physAddr[31:24] != 0)
		  $display("req_ar: funny physAddr req.pointer=%d req.offset=%h physAddr=%h", req.pointer, req.offset, physAddr);
	       dreqFifos[rename_tag].enq(DRec{req:req, client:client, rename_tag:rename_tag});
	       rv = MemRequest{addr:physAddr, burstLen:req.burstLen, tag:rename_tag};
	    end
	    return rv;
	 endmethod
      endinterface
      interface Put readData;
	 method Action put(MemData#(dataWidth) response);
	    if (valueOf(numReadClients) > 0) begin
	       dynamicAssert(response.tag == dreqFifos[response.tag].first.rename_tag, "mkMemReadInternal");
	       let client = dreqFifos[response.tag].first.client;
	       let req = dreqFifos[response.tag].first.req;
	       let burstLen = burstRegs[response.tag];
	       readClients[client].readData.put(ObjectData { data: response.data, tag: req.tag});
	       if (burstLen == 0)
		  burstLen = req.burstLen >> beat_shift;
	       if (burstLen == 1) begin
		  dreqFifos[client].deq();
		  tag_gen.return_tag(truncate(response.tag));
	       end
	       burstRegs[response.tag] <= burstLen-1;
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
   (MemWriteInternal#(OutOfOrderCompletion, addrWidth, dataWidth));
   
   FIFO#(LRec#(addrWidth)) lreqFifo <- mkSizedFIFO(1);
   FIFO#(RRec#(addrWidth))  reqFifo <- mkSizedFIFO(1);
   FIFO#(DRec#(addrWidth)) dreqFifo <- mkSizedFIFO(32);
   Vector#(NumTags, FIFO#(RResp#(addrWidth))) respFifos <- replicateM(mkSizedFIFO(4));
   Reg#(Bit#(8)) burstReg <- mkReg(0);   
   Vector#(numWriteClients, Reg#(Bit#(64))) beatCounts <- replicateM(mkReg(0));
   let beat_shift = fromInteger(valueOf(beatShift));
   TagGen#(NumTags) tag_gen <- mkTagGenOO;
   
   for (Integer selectReg = 0; selectReg < valueOf(numWriteClients); selectReg = selectReg + 1)
       rule loadClient;
	  ObjectRequest req <- writeClients[selectReg].writeReq.get();
	  if (bad_pointer(req.pointer))
	     dmaIndication.badPointer(req.pointer);
	  else begin
	     lreqFifo.enq(LRec{req:req, client:fromInteger(selectReg)});
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
	 let rename_tag <- tag_gen.get_tag(client, req.tag);
	 reqFifo.enq(RRec{req:req, pa:physAddr, client:client, rename_tag:extend(rename_tag)});
      end
   endrule

   interface MemWriteClient write_client;
      interface Get writeReq;
	 method ActionValue#(MemRequest#(addrWidth)) get();
	    let req = reqFifo.first.req;
	    let physAddr = reqFifo.first.pa;
	    let client = reqFifo.first.client;
	    let rename_tag = reqFifo.first.rename_tag;
	    reqFifo.deq;
	    dreqFifo.enq(DRec{req:req, client:client, rename_tag:rename_tag});
	    return MemRequest{addr:physAddr, burstLen:req.burstLen, tag:rename_tag};
	 endmethod
      endinterface
      interface Get writeData;
	 method ActionValue#(MemData#(dataWidth)) get() if (valueOf(numWriteClients) > 0);
	    let rv = ?;
	    if (valueOf(numWriteClients) > 0) begin
	       let client = dreqFifo.first.client;
	       let req = dreqFifo.first.req;
	       let rename_tag =dreqFifo.first.rename_tag;
	       ObjectData#(dataWidth) tagdata <- writeClients[client].writeData.get();
	       let burstLen = burstReg;
	       if (burstLen == 0)
		  burstLen = req.burstLen >> beat_shift;
	       burstReg <= burstLen-1;
	       beatCounts[client] <= beatCounts[client]+1;
	       if (burstLen == 1) begin
		  dreqFifo.deq();
		  respFifos[rename_tag].enq(RResp{orig_tag:req.tag, client:client});
	       end
	       rv = MemData { data: tagdata.data,  tag:rename_tag };
	    end
	    return rv;
	 endmethod
      endinterface
      interface Put writeDone;
	 method Action put(Bit#(6) resp);
	    if (valueOf(numWriteClients) > 0) begin
	       let client = respFifos[resp].first.client;
	       let orig_tag = respFifos[resp].first.orig_tag;
	       respFifos[resp].deq;
	       writeClients[client].writeDone.put(orig_tag);
	       tag_gen.return_tag(truncate(resp));
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
