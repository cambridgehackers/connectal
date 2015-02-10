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
import BRAM::*;

// CONNECTAL Libraries
import MemTypes::*;
import ConnectalMemory::*;
import MMU::*;
import ConnectalCompletionBuffer::*;

typedef 9 MMU_PIPELINE_DEPTH;

interface MemWriteInternal#(numeric type addrWidth, numeric type dataWidth, numeric type numTags);
   interface DmaDbg dbg;
   interface PhysMemWriteClient#(addrWidth,dataWidth) write_client;
endinterface

interface MemReadInternal#(numeric type addrWidth, numeric type dataWidth, numeric type numTags);
   interface DmaDbg dbg;
   interface PhysMemReadClient#(addrWidth,dataWidth) read_client;
endinterface

function Bool sglid_outofrange(SGLId p);
   return ((p[15:0]) >= fromInteger(valueOf(MaxNumSGLists)));
endfunction

typedef struct {MemRequest req;
		Bit#(TLog#(numClients)) client; } LRec#(numeric type numClients, numeric type addrWidth) deriving(Bits);

typedef struct {MemRequest req;
		Bit#(addrWidth) pa;
		Bit#(MemTagSize) rename_tag;
		Bit#(TLog#(numClients)) client; } RRec#(numeric type numClients, numeric type addrWidth) deriving(Bits);

typedef struct {MemRequest req;
		Bit#(MemTagSize) rename_tag;
		Bit#(TLog#(numClients)) client;
		Bool last; } DRec#(numeric type numClients, numeric type addrWidth) deriving(Bits);

typedef struct {Bit#(MemTagSize) orig_tag;
		Bit#(TLog#(numClients)) client; } RResp#(numeric type numClients, numeric type addrWidth) deriving(Bits);

typedef struct {DmaErrorType errorType;
		Bit#(32) pref; } DmaError deriving (Bits);

module mkMemReadInternal#(Vector#(numClients, MemReadClient#(dataWidth)) readClients,
			  MemServerIndication ind,
			  Vector#(numMMUs,Server#(ReqTup,Bit#(addrWidth))) mmus) 
   (MemReadInternal#(addrWidth, dataWidth, numTags))

   provisos(Add#(b__, addrWidth, 64), 
	    Add#(c__, 12, addrWidth), 
	    Add#(1, c__, d__),
	    Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift),
	    Add#(a__, TLog#(numClients), 6),
	    Add#(beatShift, e__, BurstLenSize),
	    Add#(g__, TLog#(numTags), 6)
      );
   
   // stage 0: address translation (latency = MMU_PIPELINE_DEPTH)
   FIFO#(LRec#(numClients,addrWidth)) lreqFifo <- mkSizedFIFO(valueOf(MMU_PIPELINE_DEPTH));
   // stage 1: address validation (latency = 1)
   FIFO#(RRec#(numClients,addrWidth))  reqFifo <- mkFIFO;
   // stage 2: read commands
   BRAM2Port#(Bit#(TLog#(numTags)), DRec#(numClients,addrWidth)) dreqFifos <- mkBRAM2Server(defaultValue);
   BRAM2Port#(Bit#(TAdd#(TLog#(numTags),TSub#(BurstLenSize,beatShift))), MemData#(dataWidth)) read_buffer <- mkBRAM2Server(defaultValue);
   // stage 3: read data 
   FIFO#(MemData#(dataWidth)) readDataPipelineFifo <- mkFIFO;
   
   let debug = False;
   
   Reg#(Bit#(BurstLenSize)) burstReg <- mkReg(0);
   Reg#(Bool)               firstReg <- mkReg(True);
   Reg#(Bool)                lastReg <- mkReg(False);
         
   Reg#(Bit#(64))  beatCount <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));
   TagGen#(numTags) tag_gen <- mkTagGen;

   Reg#(Bit#(BurstLenSize))      compReg0 <- mkReg(0);
   Reg#(Bit#(TLog#(numTags)))    compReg1 <- mkReg(0);
   Reg#(Bit#(TLog#(numClients))) compReg2 <- mkReg(0);
   FIFO#(Bit#(TLog#(numClients)))compFifo0 <- mkFIFO;
   FIFO#(Bit#(TLog#(numTags)))   compFifo1 <- mkFIFO;
   
   // performance analytics 
   Reg#(Bit#(64)) cycle_cnt <- mkReg(0);
   Reg#(Bit#(64)) last_loadClient <- mkReg(0);
   Reg#(Bit#(64)) last_mmuResp <- mkReg(0);
   Reg#(Bit#(64)) last_comp <- mkReg(0);
   Reg#(Bit#(64)) last_readReq <- mkReg(0);
   Reg#(Bit#(64)) last_readData <- mkReg(0);
   (* fire_when_enabled *)
   rule cycle;
      cycle_cnt <= cycle_cnt+1;
   endrule
         
   FIFO#(DmaError) dmaErrorFifo <- mkFIFO();
   rule dmaError;
      let error <- toGet(dmaErrorFifo).get();
      ind.error(extend(pack(error.errorType)), error.pref, 0, 0);
   endrule

   rule complete_burst0;
      let tag <- tag_gen.complete;
      dreqFifos.portB.request.put(BRAMRequest{write:False, address:tag, datain: ?, responseOnWrite: ?});      
      compFifo1.enq(tag);
   endrule
   
   rule complete_burst1a if (compReg0==0);
      let drq <- dreqFifos.portB.response.get;
      let cnt = drq.req.burstLen >> beat_shift;
      let cli = drq.client;
      let tag <- toGet(compFifo1).get;
      compFifo0.enq(cli);
      read_buffer.portB.request.put(BRAMRequest{write:False, address:{tag,truncate(cnt)}, datain: ?, responseOnWrite: ?});
      compReg0 <= cnt-1;
      compReg1 <= tag;
      compReg2 <= cli;
   endrule

   rule complete_burst1b if (compReg0 > 0);
      let cnt = compReg0;
      let tag = compReg1;
      let cli = compReg2;
      compFifo0.enq(cli);
      read_buffer.portB.request.put(BRAMRequest{write:False, address:{tag,truncate(cnt)}, datain: ?, responseOnWrite: ?});
      compReg0 <= cnt-1;
   endrule
   
   rule complete_burst2;
      let client <- toGet(compFifo0).get;
      let data <- read_buffer.portB.response.get;
      readClients[client].readData.put(data);
      if (debug) $display("mkMemReadInternal::comp %d  %x %d", client, data.data, cycle_cnt-last_comp);
      last_comp <= cycle_cnt;
   endrule

   for (Integer selectReg = 0; selectReg < valueOf(numClients); selectReg = selectReg + 1) 
      rule loadClient;
	 last_loadClient <= cycle_cnt;
   	 MemRequest req <- readClients[selectReg].readReq.get();
	 let mmusel = req.sglId[31:16];
      	 if (debug) $display("mkMemReadInternal::loadClient %d %d %d", selectReg, mmusel, cycle_cnt-last_loadClient);
	 if (mmusel >= fromInteger(valueOf(numMMUs)))
	    dmaErrorFifo.enq(DmaError { errorType: DmaErrorMMUOutOfRange_r, pref: req.sglId });
   	 else if (sglid_outofrange(req.sglId))
	    dmaErrorFifo.enq(DmaError { errorType: DmaErrorSGLIdOutOfRange_r, pref: req.sglId });
   	 else begin
   	    lreqFifo.enq(LRec{req:req, client:fromInteger(selectReg)});
   	    mmus[mmusel].request.put(ReqTup{id:truncate(req.sglId),off:req.offset});
   	 end
      endrule
      
   rule checkMmuResp;
      let req = lreqFifo.first.req;
      let client = lreqFifo.first.client;
      let physAddr <- mmus[req.sglId[31:16]].response.get;
      let rename_tag <- tag_gen.getTag;
      lreqFifo.deq();
      reqFifo.enq(RRec{req:req, pa:physAddr, client:client, rename_tag:extend(rename_tag)});
      if (debug) $display("checkMmuResp: client=%d, rename_tag=%d", client,rename_tag);
      if (debug) $display("mkMemReadInternal::mmuResp %d %d", client, cycle_cnt-last_mmuResp);
      last_mmuResp <= cycle_cnt;
   endrule
   
   rule read_data;
      let response <- toGet(readDataPipelineFifo).get();
      Bit#(MemTagSize) response_tag = response.tag;
      let drq <- dreqFifos.portA.response.get;
      let otag = drq.req.tag;
      let burstLen = burstReg;
      let first =    firstReg;
      let last  =    lastReg;
      if (first) begin
	 burstLen = drq.req.burstLen >> beat_shift;
	 last = drq.last;
	 dynamicAssert(last == (burstLen==1), "Last incorrect");
	 //$display("burstLen=%d dreqFifo.first.last=%d last=%d\n", burstLen, dreqFifo.first.last, last);
      end
      Bit#(TLog#(numTags)) tt = truncate(response_tag);
      read_buffer.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, datain:MemData{data: response.data, tag: otag, last: last}, address:{tt,truncate(burstLen)}});
      if (last) begin
	 tag_gen.returnTag(truncate(response_tag));
      end
      last_readData <= cycle_cnt;
      if (debug) $display("read_data %d", cycle_cnt-last_readData);
      burstReg <= burstLen-1;
      firstReg <= burstLen-1 == 0;
      lastReg  <= burstLen-1 == 1;
   endrule

   interface PhysMemReadClient read_client;
      interface Get readReq;
	 method ActionValue#(PhysMemRequest#(addrWidth)) get();
	    reqFifo.deq;
	    let req = reqFifo.first.req;
	    let physAddr = reqFifo.first.pa;
	    let client = reqFifo.first.client;
	    let rename_tag = reqFifo.first.rename_tag;
	    if (False && physAddr[31:24] != 0)
	       $display("req_ar: funny physAddr req.sglId=%d req.offset=%h physAddr=%h", req.sglId, req.offset, physAddr);
	    dreqFifos.portB.request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(rename_tag), datain:DRec{req:req, client:client, rename_tag:rename_tag, last:(req.burstLen == fromInteger(valueOf(dataWidthBytes)))}});
	    //$display("readReq: client=%d, rename_tag=%d, physAddr=%h req.burstLen=%d beat_shift=%d last=%d", client,rename_tag,physAddr, req.burstLen, beat_shift, req.burstLen == beat_shift);
	    if (debug) $display("read_client.readReq %d", cycle_cnt-last_readReq);
	    last_readReq <= cycle_cnt;
	    return PhysMemRequest{addr:physAddr, burstLen:req.burstLen, tag:rename_tag};
	 endmethod
      endinterface
      interface Put readData;
	 method Action put(MemData#(dataWidth) response);
	    readDataPipelineFifo.enq(response);
	    dreqFifos.portA.request.put(BRAMRequest{write:False, address:truncate(response.tag), datain: ?, responseOnWrite: ?});
	    beatCount <= beatCount+1;
	 endmethod
      endinterface
   endinterface
   interface DmaDbg dbg;
      method ActionValue#(DmaDbgRec) dbg();
	 return DmaDbgRec{x:0, y:0, z:0, w:0};
      endmethod
      method ActionValue#(Bit#(64)) getMemoryTraffic();
	 return beatCount;
      endmethod
   endinterface
endmodule

module mkMemWriteInternal#(Vector#(numClients, MemWriteClient#(dataWidth)) writeClients,
			   MemServerIndication ind, 
			   Vector#(numMMUs,Server#(ReqTup,Bit#(addrWidth))) mmus)
   (MemWriteInternal#(addrWidth, dataWidth, numTags))
   
   provisos(Add#(b__, addrWidth, 64), 
	    Add#(c__, 12, addrWidth), 
	    Add#(1, c__, d__),
	    Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift),
	    Add#(a__, TLog#(numClients), 6),
	    Add#(e__, TLog#(numTags), 6));
   
   let debug = False;

   // stage 0: address translation (latency = MMU_PIPELINE_DEPTH)
   FIFO#(LRec#(numClients,addrWidth)) lreqFifo <- mkSizedFIFO(valueOf(MMU_PIPELINE_DEPTH));
   // stage 1: address validation (latency = 1)
   FIFO#(RRec#(numClients,addrWidth))  reqFifo <- mkFIFO;
   // stage 2: write commands
   FIFO#(DRec#(numClients, addrWidth)) dreqFifo <- mkSizedBRAMFIFO(valueOf(numTags));
   // stage 3: write data 
   BRAM2Port#(Bit#(TLog#(numTags)), RResp#(numClients,addrWidth)) respFifos <- mkBRAM2Server(defaultValue);
   TagGen#(numTags) tag_gen <- mkTagGen;

   Reg#(Bit#(BurstLenSize)) burstReg <- mkReg(0);
   Reg#(Bool)               firstReg <- mkReg(True);
   Reg#(Bool)               lastReg <- mkReg(False);
   Reg#(Bit#(64))           beatCount <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));

   Reg#(Bit#(64)) cycle_cnt <- mkReg(0);
   Reg#(Bit#(64)) last_loadClient <- mkReg(0);
   Reg#(Bit#(64)) last_mmuResp <- mkReg(0);

   (* fire_when_enabled *)
   rule cycle;
      cycle_cnt <= cycle_cnt+1;
   endrule
   
   FIFO#(DmaError) dmaErrorFifo <- mkFIFO();
   rule dmaError;
      let error <- toGet(dmaErrorFifo).get();
      ind.error(extend(pack(error.errorType)), error.pref, 0, 0);
   endrule

   for (Integer selectReg = 0; selectReg < valueOf(numClients); selectReg = selectReg + 1)
       rule loadClient;
      	  if (debug) $display("mkMemWriteInternal::loadClient %d %d", selectReg, cycle_cnt-last_loadClient);
	  last_loadClient <= cycle_cnt;
   	  MemRequest req <- writeClients[selectReg].writeReq.get();
	  let mmusel = req.sglId[31:16];
	  if (mmusel >= fromInteger(valueOf(numMMUs)))
	     dmaErrorFifo.enq(DmaError { errorType: DmaErrorMMUOutOfRange_w, pref: req.sglId });
   	  else if (sglid_outofrange(req.sglId))
	     dmaErrorFifo.enq(DmaError { errorType: DmaErrorSGLIdOutOfRange_w, pref: req.sglId });
   	  else begin
   	     lreqFifo.enq(LRec{req:req, client:fromInteger(selectReg)});
   	     mmus[mmusel].request.put(ReqTup{id:truncate(req.sglId),off:req.offset});
   	  end
       endrule
   
   rule checkMmuResp;
      let req = lreqFifo.first.req;
      let client = lreqFifo.first.client;
      let physAddr <- mmus[req.sglId[31:16]].response.get;
      let rename_tag <- tag_gen.getTag;
      lreqFifo.deq();
      reqFifo.enq(RRec{req:req, pa:physAddr, client:client, rename_tag:extend(rename_tag)});
      //if (debug) $display("checkMmuResp: client=%d, rename_tag=%d", client,rename_tag);
      if (debug) $display("mkMemWriteInternal::mmuResp %d %d", client, cycle_cnt-last_mmuResp);
      last_mmuResp <= cycle_cnt;
   endrule
   
   rule writeDoneComp0;
      let tag <- tag_gen.complete;
      respFifos.portB.request.put(BRAMRequest{write:False, address:tag, datain: ?, responseOnWrite: ?});
   endrule
   
   rule writeDoneComp1;
      let rv <- respFifos.portB.response.get;
      let client = rv.client;
      let orig_tag = rv.orig_tag;
      writeClients[client].writeDone.put(orig_tag);
   endrule
   
   FIFO#(MemData#(dataWidth)) memDataFifo <- mkFIFO();
   Vector#(numClients, FIFO#(MemData#(dataWidth))) clientWriteData <- replicateM(mkFIFO);
   // Pipeline client data:
   // The .get() operation seems to be long latency, so get it into a local FIFO
   for (Integer client = 0; client < valueOf(numClients); client = client + 1)
      rule clientdata;
	 let d <- writeClients[client].writeData.get();
	 clientWriteData[client].enq(d);
      endrule
   
   rule memdata;
      let client = dreqFifo.first.client;
      let req = dreqFifo.first.req;
      let rename_tag = dreqFifo.first.rename_tag;
      MemData#(dataWidth) tagdata <- toGet(clientWriteData[client]).get();
      let burstLen = burstReg;
      let first    = firstReg;
      let last     = lastReg;
      if (first) begin
	 burstLen = req.burstLen >> beat_shift;
	 last     = dreqFifo.first.last;
	 respFifos.portA.request.put(BRAMRequest{write:True,responseOnWrite:False, address:truncate(rename_tag), datain:RResp{orig_tag:req.tag, client:client}});
      end
      burstReg <= burstLen-1;
      firstReg <= (burstLen-1 == 0);
      lastReg  <= (burstLen-1 == 1);
      beatCount <= beatCount+1;
      if (last)
	 dreqFifo.deq();
      //$display("writeData: client=%d, rename_tag=%d", client, rename_tag);
      memDataFifo.enq(MemData { data: tagdata.data,  tag:extend(rename_tag), last: last });
   endrule

   interface PhysMemWriteClient write_client;
      interface Get writeReq;
	 method ActionValue#(PhysMemRequest#(addrWidth)) get();
	    let req = reqFifo.first.req;
	    let physAddr = reqFifo.first.pa;
	    let client = reqFifo.first.client;
	    let rename_tag = reqFifo.first.rename_tag;
	    reqFifo.deq;
	    dreqFifo.enq(DRec{req:req, client:client, rename_tag:rename_tag, last: (req.burstLen == fromInteger(valueOf(dataWidthBytes))) });
	    //$display("writeReq: client=%d, rename_tag=%d", client,rename_tag);
	    return PhysMemRequest{addr:physAddr, burstLen:req.burstLen, tag:extend(rename_tag)};
	 endmethod
      endinterface
      interface Get writeData = toGet(memDataFifo);
      interface Put writeDone;
	 method Action put(Bit#(MemTagSize) resp);
	    tag_gen.returnTag(truncate(resp));
	    if (debug) $display("writeDone: resp=%d", resp);
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


