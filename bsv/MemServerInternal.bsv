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
import BRAMFIFO::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import Assert::*;

// XBSV Libraries
import MemTypes::*;
import PortalMemory::*;
import SGList::*;

typedef 9 SGL_PIPELINE_DEPTH;
typedef 32 TAG_DEPTH;		 

interface MemWriteInternal#(numeric type addrWidth, numeric type dataWidth);
   interface DmaDbg dbg;
   interface MemWriteClient#(addrWidth,dataWidth) write_client;
endinterface

interface MemReadInternal#(numeric type addrWidth, numeric type dataWidth);
   interface DmaDbg dbg;
   interface MemReadClient#(addrWidth,dataWidth) read_client;
endinterface

function Bool bad_pointer(ObjectPointer p);
   return ((p >>8) > fromInteger(valueOf(MaxNumSGLists)));
endfunction

interface TagGen#(numeric type numClients, numeric type numTags);
   method Action tag_request(Bit#(TLog#(numClients)) client, Bit#(6) orig_tag);
   method ActionValue#(Bit#(TLog#(numTags)))  tag_response;
   method Action return_tag(Bit#(TLog#(numTags)) tag);
endinterface

module mkTagGenOO(TagGen#(numClients,numTags))
   provisos(Log#(numTags,tagWidth),
	    Log#(numClients,clientWidth));
   
   let request_fifo0 <- mkSizedFIFOF(valueOf(SGL_PIPELINE_DEPTH));
   let request_fifo1 <- mkSizedFIFOF(valueOf(SGL_PIPELINE_DEPTH));
   let return_fifo <- mkFIFO;
   Vector#(numTags, Reg#(Bit#(TLog#(TAG_DEPTH)))) tag_regs <- replicateM(mkReg(0));
   Vector#(numTags, Reg#(Maybe#(Tuple2#(Bit#(clientWidth),Bit#(6))))) client_map <- replicateM(mkReg(tagged Invalid));
   Maybe#(UInt#(tagWidth)) next_free = findElem(0, readVReg(tag_regs));

   rule return_tag_rule;
      return_fifo.deq;
      let tag = return_fifo.first;
      tag_regs[tag] <= tag_regs[tag]-1;
      if (tag_regs[tag]==1)
	 client_map[tag] <= tagged Invalid;
   endrule

   rule tag_request_rule;
      request_fifo0.deq;
      let client = tpl_2(request_fifo0.first);
      let orig_tag = tpl_3(request_fifo0.first);
      let rv = case  (tpl_1(request_fifo0.first)) matches
		  tagged Valid .tag: return (_when_(tag_regs[tag] < maxBound) (tag));
		  tagged Invalid: return (_when_(isValid(next_free)) (fromMaybe(?, next_free)));
	       endcase;
      request_fifo1.enq(tuple3(rv,client,orig_tag));
   endrule
   
   method Action tag_request(Bit#(clientWidth) client, Bit#(6) orig_tag) if (request_fifo0.notFull);
      let rv = findElem(tagged Valid tuple2(client,orig_tag), readVReg(client_map));
      request_fifo0.enq(tuple3(rv,client,orig_tag));
   endmethod      
   
   method ActionValue#(Bit#(tagWidth)) tag_response;
      request_fifo1.deq;
      let rv = tpl_1(request_fifo1.first);
      let client = tpl_2(request_fifo1.first);
      let orig_tag = tpl_3(request_fifo1.first);
      client_map[rv] <= tagged Valid tuple2(client,orig_tag);
      tag_regs[rv] <= tag_regs[rv]+1;
      return extend(pack(rv));
   endmethod      

   method Action return_tag(Bit#(tagWidth) tag);
      return_fifo.enq(tag);
   endmethod

endmodule

module mkTagGenIO(TagGen#(numClients,numTags))
   provisos(Log#(numTags,tagWidth),
	    Log#(numClients,clientWidth),
	    Bits#(Bit#(clientWidth), tagWidth));
   
   let request_fifo <- mkSizedFIFO(valueOf(SGL_PIPELINE_DEPTH));
   
   method Action tag_request(Bit#(clientWidth) client, Bit#(6) client_tag);
      request_fifo.enq(client);
   endmethod      
   
   method ActionValue#(Bit#(tagWidth)) tag_response;
      request_fifo.deq;
      let client = request_fifo.first;
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
		Bit#(TLog#(numClients)) client;
		Bool last; } DRec#(numeric type numClients, numeric type numTags, numeric type addrWidth) deriving(Bits);

typedef struct {Bit#(6) orig_tag;
		Bit#(TLog#(numClients)) client; } RResp#(numeric type numClients, numeric type numTags, numeric type addrWidth) deriving(Bits);

typedef struct {DmaErrorType errorType;
		Bit#(32) pref; } DmaError deriving (Bits);

module mkMemReadInternal#(Integer id,
			  Vector#(numClients, ObjectReadClient#(dataWidth)) readClients, 
			  DmaIndication dmaIndication,
			  Server#(ReqTup,Bit#(addrWidth)) sgl,
			  TagGen#(numClients, numTags) tag_gen) 
   (MemReadInternal#(addrWidth, dataWidth))

   provisos(Add#(b__, addrWidth, 64), 
	    Add#(c__, 12, addrWidth), 
	    Add#(1, c__, d__),
	    Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift),
	    Add#(a__, TLog#(numTags), 6));
   
   // stage 0: address translation (latency = SGL_PIPELINE_DEPTH)
   FIFO#(LRec#(numClients,numTags,addrWidth)) lreqFifo <- mkSizedFIFO(valueOf(SGL_PIPELINE_DEPTH));
   // stage 1: address validation (latency = 1)
   FIFO#(RRec#(numClients,numTags,addrWidth))  reqFifo <- mkFIFO;
   // stage 2: read commands (maximum buffering to handle high latency read response times)
   Vector#(numTags, FIFOF#(DRec#(numClients,numTags,addrWidth))) dreqFifos <- replicateM(mkSizedBRAMFIFOF(valueOf(TAG_DEPTH)));
   // stage 3: read data (minimal buffering required) 
   FIFO#(Tuple2#(DRec#(numClients,numTags,addrWidth),MemData#(dataWidth))) readDataPipelineFifo <- mkFIFO;
   FIFO#(MemData#(dataWidth)) responseFifo <- mkFIFO;
   Vector#(numTags, Reg#(Bit#(8)))           burstRegs <- replicateM(mkReg(0));
   Vector#(numTags, Reg#(Bool))              firstRegs <- replicateM(mkReg(True));
   Vector#(numTags, Reg#(Bool))               lastRegs <- replicateM(mkReg(False));
   Reg#(Bit#(64))  beatCount <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));
   
   // performance analytics 
   Reg#(Bit#(64)) cycle_cnt <- mkReg(0);
   Reg#(Bit#(64)) last_loadClient <- mkReg(0);
   Reg#(Bit#(64)) last_sglResp <- mkReg(0);
   Reg#(Bit#(64)) last_eob <- mkReg(0);
   (* fire_when_enabled *)
   rule cycle;
      cycle_cnt <= cycle_cnt+1;
   endrule
         
   FIFO#(DmaError) dmaErrorFifo <- mkFIFO();
   rule dmaError;
      let error <- toGet(dmaErrorFifo).get();
      dmaIndication.dmaError(extend(pack(error.errorType)), error.pref, 0, 0);
   endrule

   for (Integer selectReg = 0; selectReg < valueOf(numClients); selectReg = selectReg + 1) 
      rule loadClient;
      	 //$display("mkMemReadInternal::loadClient %d %d", selectReg, cycle_cnt-last_loadClient);
	 //last_loadClient <= cycle_cnt;
   	 ObjectRequest req <- readClients[selectReg].readReq.get();
   	 if (bad_pointer(req.pointer))
	    dmaErrorFifo.enq(DmaError { errorType: DmaErrorBadPointer4, pref: req.pointer });
   	 else begin
	    tag_gen.tag_request(fromInteger(selectReg), req.tag);
   	    lreqFifo.enq(LRec{req:req, client:fromInteger(selectReg)});
   	    sgl.request.put(ReqTup{id:truncate(req.pointer),off:req.offset});
   	 end
      endrule
   
   rule checkSglResp;
      let physAddr <- sgl.response.get;
      let req = lreqFifo.first.req;
      let client = lreqFifo.first.client;
      let rename_tag <- tag_gen.tag_response;
      lreqFifo.deq();
      reqFifo.enq(RRec{req:req, pa:physAddr, client:client, rename_tag:extend(rename_tag)});
      //$display("checkSglResp: client=%d, rename_tag=%d", client,rename_tag);
      //$display("mkMemReadInternal::sglResp %d %d", client, cycle_cnt-last_sglResp);
      //last_sglResp <= cycle_cnt;
   endrule

   rule readDataComp;
      readDataPipelineFifo.deq;
      let drq = tpl_1(readDataPipelineFifo.first);
      let response = tpl_2(readDataPipelineFifo.first);
      let client = drq.client;
      let req = drq.req;
      readClients[client].readData.put(ObjectData { data: response.data, tag: req.tag, last: False});
      //$display("readDataComp: %d %h", client, response.data);
      beatCount <= beatCount+1;
   endrule

   rule read_client_response;
      let response <- toGet(responseFifo).get();
      Bit#(6) response_tag = response.tag;
      let dreqFifo = dreqFifos[response_tag];
      dynamicAssert(truncate(response_tag) == dreqFifo.first.rename_tag, "mkMemReadInternal");
      readDataPipelineFifo.enq(tuple2(dreqFifo.first, response));
      let burstLen = burstRegs[response_tag];
      let first =    firstRegs[response_tag];
      let last  =    lastRegs[response_tag];
      if (first) begin
	 burstLen = dreqFifo.first.req.burstLen >> beat_shift;
	 last = dreqFifo.first.last;
	 dynamicAssert(last == (burstLen==1), "Last incorrect");
	 //$display("burstLen=%d dreqFifo.first.last=%d last=%d\n", burstLen, dreqFifo.first.last, last);
      end
      if (last) begin
	 //$display("mkMemReadInternal::eob %d", cycle_cnt-last_eob);
	 last_eob <= cycle_cnt;
	 dreqFifo.deq();
	 tag_gen.return_tag(truncate(response_tag));
      end
      burstRegs[response_tag] <= burstLen-1;
      firstRegs[response_tag] <= (burstLen-1 == 0);
      lastRegs[response_tag] <= (burstLen-1 == 1);
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
	    dreqFifos[rename_tag].enq(DRec{req:req, client:client, rename_tag:rename_tag, last:(req.burstLen == fromInteger(valueOf(dataWidthBytes)))});
	    //$display("readReq: client=%d, rename_tag=%d, physAddr=%h req.burstLen=%d beat_shift=%d last=%d", client,rename_tag,physAddr, req.burstLen, beat_shift, req.burstLen == beat_shift);
	    return MemRequest{addr:physAddr, burstLen:req.burstLen, tag:extend(rename_tag)};
	 endmethod
      endinterface
      interface Put readData = toPut(responseFifo);
   endinterface
   interface DmaDbg dbg;
      method ActionValue#(DmaDbgRec) dbg();
	 // Bit#(1) ne0 = pack(dreqFifos[0].notEmpty);
	 // Bit#(1) ne1 = pack(dreqFifos[1].notEmpty);
	 // return DmaDbgRec{x:extend(burstRegs[0]), y:extend(burstRegs[1]), z:extend(ne0), w:extend(ne1)};
	 return DmaDbgRec{x:0, y:0, z:0, w:0};
      endmethod
      method ActionValue#(Bit#(64)) getMemoryTraffic();
	 return beatCount;
      endmethod
   endinterface
endmodule

module mkMemWriteInternal#(Integer iid,
			   Vector#(numClients, ObjectWriteClient#(dataWidth)) writeClients,
			   DmaIndication dmaIndication, 
			   Server#(ReqTup,Bit#(addrWidth)) sgl,
			   TagGen#(numClients, numTags) tag_gen)
   (MemWriteInternal#(addrWidth, dataWidth))
   
   provisos(Add#(b__, addrWidth, 64), 
	    Add#(c__, 12, addrWidth), 
	    Add#(1, c__, d__),
	    Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift),
	    Add#(a__, TLog#(numTags), 6));
   
   
   // stage 0: address translation (latency = SGL_PIPELINE_DEPTH)
   FIFO#(LRec#(numClients,numTags,addrWidth)) lreqFifo <- mkSizedFIFO(valueOf(SGL_PIPELINE_DEPTH));
   // stage 1: address validation (latency = 1)
   FIFO#(RRec#(numClients,numTags,addrWidth))  reqFifo <- mkFIFO;
   // stage 2: write commands (maximum buffering to handle high latency writes)
   FIFO#(DRec#(numClients,numTags,addrWidth)) dreqFifo <- mkSizedBRAMFIFO(valueOf(TMul#(TAG_DEPTH,numTags)));
   // stage 3: write data (maximum buffering, though I have no idea if any hosts will begin the next data transfer before sending the write ack)
   Vector#(numTags, FIFO#(RResp#(numClients,numTags,addrWidth))) respFifos <- replicateM(mkSizedBRAMFIFO(valueOf(TAG_DEPTH)));
   // stage 4: write done (minimal buffering required)
   FIFO#(Tuple2#(RResp#(numClients,numTags,addrWidth),Bit#(6))) writeDonePipelineFifo <- mkFIFO;

   Reg#(Bit#(8)) burstReg <- mkReg(0);   
   Reg#(Bit#(64)) beatCount <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));

   Reg#(Bit#(64)) cycle_cnt <- mkReg(0);
   Reg#(Bit#(64)) last_loadClient <- mkReg(0);
   Reg#(Bit#(64)) last_sglResp <- mkReg(0);
   Reg#(Bit#(64)) last_eob <- mkReg(0);
   (* fire_when_enabled *)
   rule cycle;
      cycle_cnt <= cycle_cnt+1;
   endrule
   
   FIFO#(DmaError) dmaErrorFifo <- mkFIFO();
   rule dmaError;
      let error <- toGet(dmaErrorFifo).get();
      dmaIndication.dmaError(extend(pack(error.errorType)), error.pref, 0, 0);
   endrule

   for (Integer selectReg = 0; selectReg < valueOf(numClients); selectReg = selectReg + 1)
       rule loadClient;
      	  //$display("mkMemWriteInternal::loadClient %d %d", selectReg, cycle_cnt-last_loadClient);
	  //last_loadClient <= cycle_cnt;
   	  ObjectRequest req <- writeClients[selectReg].writeReq.get();
   	  if (bad_pointer(req.pointer)) 
	     dmaErrorFifo.enq(DmaError { errorType: DmaErrorBadPointer5, pref: req.pointer });
   	  else begin
	     tag_gen.tag_request(fromInteger(selectReg), req.tag);
   	     lreqFifo.enq(LRec{req:req, client:fromInteger(selectReg)});
   	     sgl.request.put(ReqTup{id:truncate(req.pointer),off:req.offset});
   	  end
       endrule
   
   rule checkSglResp;
      let physAddr <- sgl.response.get;
      let req = lreqFifo.first.req;
      let client = lreqFifo.first.client;
      let rename_tag <- tag_gen.tag_response;
      lreqFifo.deq();
      reqFifo.enq(RRec{req:req, pa:physAddr, client:client, rename_tag:extend(rename_tag)});
      //$display("checkSglResp: client=%d, rename_tag=%d", client,rename_tag);
      //$display("mkMemWriteInternal::sglResp %d %d", client, cycle_cnt-last_sglResp);
      //last_sglResp <= cycle_cnt;
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
	    dreqFifo.enq(DRec{req:req, client:client, rename_tag:rename_tag, last: False });
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
	    beatCount <= beatCount+1;
	    if (burstLen == 1) 
	       dreqFifo.deq();
	    //$display("writeData: client=%d, rename_tag=%d", client, rename_tag);
	    return MemData { data: tagdata.data,  tag:extend(rename_tag), last: False };
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
      method ActionValue#(Bit#(64)) getMemoryTraffic();
	 return beatCount;
      endmethod
   endinterface
endmodule
