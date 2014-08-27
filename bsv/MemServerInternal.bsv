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

interface TagGen#(numeric type numTags);
   method Action tag_request();
   method ActionValue#(Bit#(TLog#(numTags))) tag_response;
   method Action return_tag(Bit#(TLog#(numTags)) tag);
endinterface

module mkTagGen(TagGen#(numTags));

   Vector#(numTags,Reg#(Bool)) tags <- replicateM(mkReg(False));
   FIFO#(Bit#(TLog#(numTags))) resp_fifo <- mkFIFO;
   Reg#(Bit#(TLog#(numTags)))  ptr <- mkReg(0);

   method Action tag_request() if (!tags[ptr]);
      tags[ptr] <= True;
      resp_fifo.enq(ptr);
      ptr <= ptr+1;
   endmethod

   method ActionValue#(Bit#(TLog#(numTags))) tag_response;
      resp_fifo.deq;
      return resp_fifo.first;
   endmethod

   method Action return_tag(Bit#(TLog#(numTags)) tag);
      tags[tag] <= False;
   endmethod
endmodule

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

typedef struct {ObjectRequest req;
		Bit#(TLog#(numClients)) client; } LRec#(numeric type numClients, numeric type addrWidth) deriving(Bits);

typedef struct {ObjectRequest req;
		Bit#(addrWidth) pa;
		Bit#(6) rename_tag;
		Bit#(TLog#(numClients)) client; } RRec#(numeric type numClients, numeric type addrWidth) deriving(Bits);

typedef struct {ObjectRequest req;
		Bit#(6) rename_tag;
		Bit#(TLog#(numClients)) client;
		Bool last; } DRec#(numeric type numClients, numeric type addrWidth) deriving(Bits);

typedef struct {Bit#(6) orig_tag;
		Bit#(TLog#(numClients)) client; } RResp#(numeric type numClients, numeric type addrWidth) deriving(Bits);

typedef struct {DmaErrorType errorType;
		Bit#(32) pref; } DmaError deriving (Bits);

typedef 4 NumTags;

module mkMemReadInternal#(Integer id,
			  Vector#(numClients, ObjectReadClient#(dataWidth)) readClients,
			  DmaIndication dmaIndication,
			  Server#(ReqTup,Bit#(addrWidth)) sgl) 
   (MemReadInternal#(addrWidth, dataWidth))

   provisos(Add#(b__, addrWidth, 64), 
	    Add#(c__, 12, addrWidth), 
	    Add#(1, c__, d__),
	    Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift),
	    Add#(a__, TLog#(numClients), 6)
      );
   
   // stage 0: address translation (latency = SGL_PIPELINE_DEPTH)
   FIFO#(LRec#(numClients,addrWidth)) lreqFifo <- mkSizedFIFO(valueOf(SGL_PIPELINE_DEPTH));
   // stage 1: address validation (latency = 1)
   FIFO#(RRec#(numClients,addrWidth))  reqFifo <- mkFIFO;
   // stage 2: read commands (maximum buffering to handle high latency read response times)
   Vector#(NumTags, FIFOF#(DRec#(numClients,addrWidth))) dreqFifos <- replicateM(mkSizedFIFOF(1));
   // stage 3: read data (minimal buffering required) 
   Vector#(numClients, FIFO#(MemData#(dataWidth))) readDataPipelineFifo <- replicateM(mkFIFO);

   Vector#(NumTags, Reg#(Bit#(8)))           burstRegs <- replicateM(mkReg(0));
   Vector#(NumTags, Reg#(Bool))              firstRegs <- replicateM(mkReg(True));
   Vector#(NumTags, Reg#(Bool))               lastRegs <- replicateM(mkReg(False));
   Reg#(Bit#(64))  beatCount <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));
   TagGen#(NumTags) tag_gen <- mkTagGen;
   
   // performance analytics 
   Reg#(Bit#(64)) cycle_cnt <- mkReg(0);
   Reg#(Bit#(64)) last_loadClient <- mkReg(0);
   Reg#(Bit#(64)) last_sglResp <- mkReg(0);
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
	    tag_gen.tag_request;
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
   
   for (Integer client = 0; client < valueOf(numClients); client = client + 1)
       rule read_client_response;
	  let response <- toGet(readDataPipelineFifo[client]).get();
	  Bit#(6) response_tag = response.tag;
	  
	  let dreqFifo = dreqFifos[response_tag];
	  let drq = dreqFifo.first;
	  let req = drq.req;
	  let burstLen = burstRegs[response_tag];
	  let first =    firstRegs[response_tag];
	  let last  =    lastRegs[response_tag];
	  if (first) begin
	     burstLen = dreqFifo.first.req.burstLen >> beat_shift;
	     last = dreqFifo.first.last;
	     dynamicAssert(last == (burstLen==1), "Last incorrect");
	     //$display("burstLen=%d dreqFifo.first.last=%d last=%d\n", burstLen, dreqFifo.first.last, last);
	  end

	  readClients[client].readData.put(ObjectData { data: response.data, tag: req.tag, last: last});
	  if (last) begin
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
	    return MemRequest{addr:physAddr, burstLen:req.burstLen, tag:rename_tag};
	 endmethod
      endinterface
      interface Put readData;
	 method Action put(MemData#(dataWidth) response);
	    let client = dreqFifos[response.tag].first.client;
	    readDataPipelineFifo[client].enq(response);
	    beatCount <= beatCount+1;
	 endmethod
      endinterface
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
			   Server#(ReqTup,Bit#(addrWidth)) sgl)
   (MemWriteInternal#(addrWidth, dataWidth))
   
   provisos(Add#(b__, addrWidth, 64), 
	    Add#(c__, 12, addrWidth), 
	    Add#(1, c__, d__),
	    Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift),
	    Add#(a__, TLog#(numClients), 6));
   
   
   // stage 0: address translation (latency = SGL_PIPELINE_DEPTH)
   FIFO#(LRec#(numClients,addrWidth)) lreqFifo <- mkSizedFIFO(valueOf(SGL_PIPELINE_DEPTH));
   // stage 1: address validation (latency = 1)
   FIFO#(RRec#(numClients,addrWidth))  reqFifo <- mkFIFO;
   // stage 2: write commands (maximum buffering to handle high latency writes)
   FIFO#(DRec#(numClients, addrWidth)) mwDreqFifo <- mkSizedBRAMFIFO(valueOf(TMul#(numClients,NumTags)));
   // stage 3: write data 
   Vector#(NumTags, FIFO#(RResp#(numClients,addrWidth))) respFifos <- replicateM(mkSizedFIFO(4));
   // stage 4: write done (minimal buffering required)
   FIFO#(RResp#(numClients,addrWidth)) writeDonePipelineFifo <- mkFIFO;
   TagGen#(NumTags) tag_gen <- mkTagGen;

   Reg#(Bit#(8)) burstReg <- mkReg(0);   
   Reg#(Bool)    firstReg <- mkReg(True);
   Reg#(Bool)     lastReg <- mkReg(False);
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
   	     lreqFifo.enq(LRec{req:req, client:fromInteger(selectReg)});
   	     sgl.request.put(ReqTup{id:truncate(req.pointer),off:req.offset});
	     tag_gen.tag_request;
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
      let rv <- toGet(writeDonePipelineFifo).get;
      let client = rv.client;
      let orig_tag = rv.orig_tag;
      writeClients[client].writeDone.put(orig_tag);
   endrule
   
   FIFO#(MemData#(dataWidth)) memDataFifo <- mkFIFO();
   Vector#(numClients, FIFO#(ObjectData#(dataWidth))) clientWriteData <- replicateM(mkFIFO);
   // Pipeline client data:
   // The .get() operation seems to be long latency, so get it into a local FIFO
   for (Integer client = 0; client < valueOf(numClients); client = client + 1)
      rule clientdata;
	 let d <- writeClients[client].writeData.get();
	 clientWriteData[client].enq(d);
      endrule
   
   rule memdata;
      let client = mwDreqFifo.first.client;
      let req = mwDreqFifo.first.req;
      let rename_tag = mwDreqFifo.first.rename_tag;
      ObjectData#(dataWidth) tagdata <- toGet(clientWriteData[client]).get();
      let burstLen = burstReg;
      let first    = firstReg;
      let last     = lastReg;
      if (first) begin
	 burstLen = req.burstLen >> beat_shift;
	 last     = mwDreqFifo.first.last;
	 respFifos[rename_tag].enq(RResp{orig_tag:req.tag, client:client});
      end
      burstReg <= burstLen-1;
      firstReg <= (burstLen-1 == 0);
      lastReg  <= (burstLen-1 == 1);
      beatCount <= beatCount+1;
      if (last)
	 mwDreqFifo.deq();
      //$display("writeData: client=%d, rename_tag=%d", client, rename_tag);
      memDataFifo.enq(MemData { data: tagdata.data,  tag:extend(rename_tag), last: False });
   endrule

   interface MemWriteClient write_client;
      interface Get writeReq;
	 method ActionValue#(MemRequest#(addrWidth)) get();
	    let req = reqFifo.first.req;
	    let physAddr = reqFifo.first.pa;
	    let client = reqFifo.first.client;
	    let rename_tag = reqFifo.first.rename_tag;
	    reqFifo.deq;
	    mwDreqFifo.enq(DRec{req:req, client:client, rename_tag:rename_tag, last: (req.burstLen == fromInteger(valueOf(dataWidthBytes))) });
	    //$display("writeReq: client=%d, rename_tag=%d", client,rename_tag);
	    return MemRequest{addr:physAddr, burstLen:req.burstLen, tag:extend(rename_tag)};
	 endmethod
      endinterface
      interface Get writeData;
	 method ActionValue#(MemData#(dataWidth)) get();
            let d <- toGet(memDataFifo).get();
            return d;
	 endmethod
      endinterface
      interface Put writeDone;
	 method Action put(Bit#(6) resp);
	    let r <- toGet(respFifos[resp]).get;
	    writeDonePipelineFifo.enq(r);
	    tag_gen.return_tag(truncate(resp));
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


