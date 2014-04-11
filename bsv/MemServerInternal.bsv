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

interface MemWriteInternal#(numeric type addrWidth, numeric type dataWidth);
   interface DmaDbg dbg;
   interface MemWriteClient#(addrWidth,dataWidth) write_client;
endinterface

interface MemReadInternal#(numeric type addrWidth, numeric type dataWidth);
   interface DmaDbg dbg;
   interface MemReadClient#(addrWidth,dataWidth) read_client;
endinterface

function Bool bad_pointer(ObjectPointer p);
   return (p > fromInteger(valueOf(MaxNumSGLists)) || p == 0);
endfunction

interface TagGen#(numeric type numClients, numeric type numTags);
   method ActionValue#(Bit#(TLog#(numTags))) get_tag(Bit#(TLog#(numClients)) client, Bit#(6) orig_tag);
   method Action return_tag(Bit#(TLog#(numTags)) tag);
endinterface

module mkTagGenOO(TagGen#(numClients,numTags))
   provisos(Log#(numTags,tagWidth),
	    Log#(numClients,clientWidth));

   Vector#(numTags, Reg#(Bit#(tagWidth))) tag_regs <- replicateM(mkReg(0));
   Vector#(numTags, Reg#(Maybe#(Tuple2#(Bit#(clientWidth),Bit#(6))))) client_map <- replicateM(mkReg(tagged Invalid));
   Maybe#(UInt#(tagWidth)) next_free = findElem(0, readVReg(tag_regs));

   method ActionValue#(Bit#(tagWidth)) get_tag(Bit#(clientWidth) client, Bit#(6) orig_tag);
      let rv = case (findElem(tagged Valid tuple2(client,orig_tag), readVReg(client_map))) matches
		  tagged Valid .tag: return (_when_(tag_regs[tag] < maxBound) (tag));
		  tagged Invalid: return (_when_(isValid(next_free)) (fromMaybe(?, next_free)));
	       endcase;
      client_map[rv] <= tagged Valid tuple2(client,orig_tag);
      tag_regs[rv] <= tag_regs[rv]+1;
      return extend(pack(rv));
   endmethod      

   method Action return_tag(Bit#(tagWidth) tag);
      tag_regs[tag] <= tag_regs[tag]-1;
      if (tag_regs[tag]==1)
	 client_map[tag] <= tagged Invalid;
   endmethod

endmodule

module mkTagGenIO(TagGen#(numClients,numTags))
   provisos(Log#(numTags,tagWidth),
	    Log#(numClients,clientWidth),
	    Bits#(Bit#(clientWidth), tagWidth));

   method ActionValue#(Bit#(tagWidth)) get_tag(Bit#(clientWidth) client, Bit#(6) client_tag);
      return pack(client);
   endmethod      

   method Action return_tag(Bit#(tagWidth) tag);
      noAction;
   endmethod

endmodule

typedef struct {ObjectRequest req;
		Bit#(TLog#(numClients)) client; } LRec#(numeric type numClients, numeric type numTags, numeric type addrWidth) deriving(Bits);

typedef struct {ObjectRequest req;
		Bit#(addrWidth) pa;
		Bit#(TLog#(numTags)) rename_tag;
		Bit#(TLog#(numClients)) client; } RRec#(numeric type numClients, numeric type numTags, numeric type addrWidth) deriving(Bits);

typedef struct {ObjectRequest req;
		Bit#(TLog#(numTags)) rename_tag;
		Bit#(TLog#(numClients)) client; } DRec#(numeric type numClients, numeric type numTags, numeric type addrWidth) deriving(Bits);

typedef struct {Bit#(6) orig_tag;
		Bit#(TLog#(numClients)) client; } RResp#(numeric type numClients, numeric type numTags, numeric type addrWidth) deriving(Bits);

module mkMemReadInternal#(Vector#(numClients, ObjectReadClient#(dataWidth)) readClients, 
			  DmaIndication dmaIndication,
			  Server#(Tuple2#(SGListId,Bit#(ObjectOffsetSize)),Bit#(addrWidth)) sgl,
			  TagGen#(numClients, numTags) tag_gen) 
   (MemReadInternal#(addrWidth, dataWidth))

   provisos(Add#(b__, addrWidth, 64), 
	    Add#(c__, 12, addrWidth), 
	    Add#(1, c__, d__),
	    Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift),
	    Add#(a__, TLog#(numTags), 6));

   FIFO#(Tuple2#(DRec#(numClients,numTags,addrWidth),MemData#(dataWidth))) readDataPipelineFifo <- mkFIFO;
   
   FIFO#(LRec#(numClients,numTags,addrWidth)) lreqFifo <- mkSizedFIFO(1);
   FIFO#(RRec#(numClients,numTags,addrWidth))  reqFifo <- mkSizedFIFO(1);
   Vector#(numTags, FIFO#(DRec#(numClients,numTags,addrWidth))) dreqFifos <- replicateM(mkSizedFIFO(4));
   Vector#(numTags, Reg#(Bit#(8)))           burstRegs <- replicateM(mkReg(0));
   Vector#(numClients, Reg#(Bit#(64)))  beatCounts <- replicateM(mkReg(0));
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
      
   for (Integer selectReg = 0; selectReg < valueOf(numClients); selectReg = selectReg + 1)
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
	 //$display("checkSglResp: client=%d, rename_tag=%d", client,rename_tag);
      end
   endrule

   rule readDataComp;
      readDataPipelineFifo.deq;
      let drq = tpl_1(readDataPipelineFifo.first);
      let response = tpl_2(readDataPipelineFifo.first);
      let client = drq.client;
      let req = drq.req;
      readClients[client].readData.put(ObjectData { data: response.data, tag: req.tag});
      beatCounts[client] <= beatCounts[client]+1;
   endrule

   interface MemReadClient read_client;
      interface Get readReq;
	 method ActionValue#(MemRequest#(addrWidth)) get();
	    reqFifo.deq;
	    let req = reqFifo.first.req;
	    let physAddr = reqFifo.first.pa;
	    let client = reqFifo.first.client;
	    let rename_tag = reqFifo.first.rename_tag;
	    if (False && physAddr[31:24] != 0)
	       $display("req_ar: funny physAddr req.pointer=%d req.offset=%h physAddr=%h", req.pointer, req.offset, physAddr);
	    dreqFifos[rename_tag].enq(DRec{req:req, client:client, rename_tag:rename_tag});
	    //$display("readReq: client=%d, rename_tag=%d", client,rename_tag);
	    return MemRequest{addr:physAddr, burstLen:req.burstLen, tag:extend(rename_tag)};
	 endmethod
      endinterface
      interface Put readData;
	 method Action put(MemData#(dataWidth) response);
	    Bit#(6) response_tag = response.tag;
	    let dreqFifo = dreqFifos[response_tag];
	    dynamicAssert(truncate(response_tag) == dreqFifo.first.rename_tag, "mkMemReadInternal");
	    readDataPipelineFifo.enq(tuple2(dreqFifo.first, response));
	    let burstLen = burstRegs[response_tag];
	    if (burstLen == 0)
	       burstLen = dreqFifo.first.req.burstLen >> beat_shift;
	    if (burstLen == 1) begin
	       //$display("eob");
	       dreqFifo.deq();
	       tag_gen.return_tag(truncate(response_tag));
	    end
	    burstRegs[response_tag] <= burstLen-1;
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
	 return DmaDbgRec{x:fromInteger(valueOf(numClients)), y:bin1, z:bin4, w:binx};
`else
	 return DmaDbgRec{x:fromInteger(valueOf(numClients)), y:0, z:0, w:0};
`endif
      endmethod
      method ActionValue#(Bit#(64)) getMemoryTraffic(Bit#(32) client);
	 return beatCounts[client];
      endmethod
   endinterface
endmodule

module mkMemWriteInternal#(Vector#(numClients, ObjectWriteClient#(dataWidth)) writeClients,
			   DmaIndication dmaIndication, 
			   Server#(Tuple2#(SGListId,Bit#(ObjectOffsetSize)),Bit#(addrWidth)) sgl,
			   TagGen#(numClients, numTags) tag_gen)
   (MemWriteInternal#(addrWidth, dataWidth))
   
   provisos(Add#(b__, addrWidth, 64), 
	    Add#(c__, 12, addrWidth), 
	    Add#(1, c__, d__),
	    Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift),
	    Add#(a__, TLog#(numTags), 6));
   
   FIFO#(Tuple2#(RResp#(numClients,numTags,addrWidth),Bit#(6))) writeDonePipelineFifo <- mkFIFO;
   
   FIFO#(LRec#(numClients,numTags,addrWidth)) lreqFifo <- mkSizedFIFO(1);
   FIFO#(RRec#(numClients,numTags,addrWidth))  reqFifo <- mkSizedFIFO(1);
   FIFO#(DRec#(numClients,numTags,addrWidth)) dreqFifo <- mkSizedFIFO(32);
   Vector#(numTags, FIFO#(RResp#(numClients,numTags,addrWidth))) respFifos <- replicateM(mkSizedFIFO(4));
   Reg#(Bit#(8)) burstReg <- mkReg(0);   
   Vector#(numClients, Reg#(Bit#(64))) beatCounts <- replicateM(mkReg(0));
   let beat_shift = fromInteger(valueOf(beatShift));
   
   for (Integer selectReg = 0; selectReg < valueOf(numClients); selectReg = selectReg + 1)
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
	 //$display("checkSglResp: client=%d, rename_tag=%d", client,rename_tag);
      end
   endrule
   
   rule writeDoneComp;
      writeDonePipelineFifo.deq;
      let client = tpl_1(writeDonePipelineFifo.first).client;
      let orig_tag = tpl_1(writeDonePipelineFifo.first).orig_tag;
      let response_tag = tpl_2(writeDonePipelineFifo.first);
      writeClients[client].writeDone.put(orig_tag);
      tag_gen.return_tag(truncate(response_tag));
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
	    //$display("writeReq: client=%d, rename_tag=%d", client,rename_tag);
	    return MemRequest{addr:physAddr, burstLen:req.burstLen, tag:extend(rename_tag)};
	 endmethod
      endinterface
      interface Get writeData;
	 method ActionValue#(MemData#(dataWidth)) get();
	    let client = dreqFifo.first.client;
	    let req = dreqFifo.first.req;
	    let rename_tag =dreqFifo.first.rename_tag;
	    ObjectData#(dataWidth) tagdata <- writeClients[client].writeData.get();
	    let burstLen = burstReg;
	    if (burstLen == 0) begin
	       burstLen = req.burstLen >> beat_shift;
	       respFifos[rename_tag].enq(RResp{orig_tag:req.tag, client:client});
	    end
	    burstReg <= burstLen-1;
	    beatCounts[client] <= beatCounts[client]+1;
	    if (burstLen == 1) 
	       dreqFifo.deq();
	    //$display("writeData: client=%d, rename_tag=%d", client, rename_tag);
	    return MemData { data: tagdata.data,  tag:extend(rename_tag) };
	 endmethod
      endinterface
      interface Put writeDone;
	 method Action put(Bit#(6) resp);
	    let response_tag = resp;
	    let respFifo = respFifos[response_tag];
	    writeDonePipelineFifo.enq(tuple2(respFifo.first,resp));
	    respFifo.deq;
	 endmethod
      endinterface
   endinterface
   interface DmaDbg dbg;
      method ActionValue#(DmaDbgRec) dbg();
	 return DmaDbgRec{x:fromInteger(valueOf(numClients)), y:?, z:?, w:?};
      endmethod
      method ActionValue#(Bit#(64)) getMemoryTraffic(Bit#(32) client);
	 return beatCounts[client];
      endmethod
   endinterface
endmodule
