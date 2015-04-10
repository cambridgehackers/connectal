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
import DefaultValue::*;

// CONNECTAL Libraries
import MemTypes::*;
import ConnectalMemory::*;
import ConnectalClocks::*;
import MMU::*;
import ConnectalCompletionBuffer::*;

typedef 32 BeatCountSize;

typedef 9 MMU_PIPELINE_DEPTH;

interface DmaDbg;
   method ActionValue#(Bit#(64)) getMemoryTraffic();
   method ActionValue#(DmaDbgRec) dbg();
endinterface

interface MemWriteInternal#(numeric type addrWidth, numeric type dataWidth, numeric type numTags, numeric type numServers);
   interface DmaDbg dbg;
   interface Put#(TileControl) tileControl;
   interface PhysMemWriteClient#(addrWidth,dataWidth) client;
   interface Vector#(numServers, MemWriteServer#(dataWidth)) servers;
endinterface

interface MemReadInternal#(numeric type addrWidth, numeric type dataWidth, numeric type numTags, numeric type numServers);
   interface DmaDbg dbg;
   interface Put#(TileControl) tileControl;
   interface PhysMemReadClient#(addrWidth,dataWidth) client;
   interface Vector#(numServers, MemReadServer#(dataWidth)) servers;
endinterface

function Bool sglid_outofrange(SGLId p);
   return ((p[15:0]) >= fromInteger(valueOf(MaxNumSGLists)));
endfunction

typedef struct {MemRequest req;
		Bit#(TLog#(TMax#(1,numClients))) client; } LRec#(numeric type numClients, numeric type addrWidth) deriving(Bits);

typedef struct {MemRequest req;
		Bit#(addrWidth) pa;
		Bit#(MemTagSize) rename_tag;
		Bit#(TLog#(TMax#(1,numClients))) client; } RRec#(numeric type numClients, numeric type addrWidth) deriving(Bits);

typedef struct {Bit#(MemTagSize) req_tag;
		Bit#(BurstLenSize) req_burstLen;
		Bit#(MemTagSize) rename_tag;
		Bit#(TLog#(TMax#(1,numClients))) client;
		Bool last;
   } DRec#(numeric type numClients, numeric type addrWidth) deriving(Bits);

typedef struct {Bit#(MemTagSize) orig_tag;
		Bit#(TLog#(TMax#(1,numClients))) client; } RResp#(numeric type numClients, numeric type addrWidth) deriving(Bits);

typedef struct {DmaErrorType errorType;
		Bit#(32) pref; } DmaError deriving (Bits);

module mkMemReadInternal#(MemServerIndication ind,
			  Vector#(numMMUs,Server#(ReqTup,Bit#(addrWidth))) mmus) 
   (MemReadInternal#(addrWidth, dataWidth, numTags, numServers))
   provisos(Log#(dataWidthBytes,beatShift)
	    ,Div#(dataWidth,8,dataWidthBytes)
	    ,Add#(beatShift, a__, 8)
	    ,Add#(b__, TLog#(numTags), 6)
	    );
   
   
   // stopping/killing infra
   Vector#(4,Reg#(Bool)) killv <- replicateM(mkReg(False));
   Vector#(4,Reg#(Bool)) stopv <- replicateM(mkReg(False));
   
   // stage 0: address translation (latency = MMU_PIPELINE_DEPTH)
   FIFO#(LRec#(numServers,addrWidth)) lreqFifo <- mkSizedFIFO(valueOf(MMU_PIPELINE_DEPTH));
   // stage 1: address validation (latency = 1)
   FIFO#(RRec#(numServers,addrWidth))  reqFifo <- mkFIFO;
   // stage 2: read commands
   BRAM_Configure bramConfig = defaultValue;
   if (mainClockPeriod < 8)
      bramConfig.latency = 2;
   BRAM2Port#(Bit#(TLog#(numTags)), DRec#(numServers,addrWidth)) dreqBram <- mkBRAM2Server(bramConfig);
   BRAM2Port#(Bit#(TAdd#(TLog#(numTags),TSub#(BurstLenSize,beatShift))), MemData#(dataWidth)) readBufferBram <- mkBRAM2Server(bramConfig);
   // stage 3: read data 
   FIFO#(MemData#(dataWidth)) readDataPipelineFifo <- mkFIFO;
   
   let debug = False;
   
   Reg#(Bit#(BurstLenSize)) burstReg <- mkReg(0);
   Reg#(Bool)               firstReg <- mkReg(True);
   Reg#(Bool)                lastReg <- mkReg(False);
         
   Reg#(Bit#(32))  beatCount <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));
   TagGen#(numTags) tag_gen <- mkTagGen;

   Reg#(Bit#(BurstLenSize))      compCountReg <- mkReg(0);
   Reg#(Bit#(TLog#(numTags)))    compTagReg <- mkReg(0);
   Reg#(Bit#(TLog#(TMax#(1,numServers)))) compClientReg <- mkReg(0);
   Reg#(Bit#(2))                 compTileReg <- mkReg(0);
   FIFO#(Bit#(TAdd#(1,TLog#(TMax#(1,numServers))))) compFifo0 <- mkFIFO;
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
      dreqBram.portB.request.put(BRAMRequest{write:False, address:tag, datain: ?, responseOnWrite: ?});
      compFifo1.enq(tag);
      if(debug) $display("mkMemReadInternal::complete_burst0 %h", tag);
   endrule
   
   rule complete_burst1a if (compCountReg==0);
      let drq <- dreqBram.portB.response.get;
      let req_burstLen = drq.req_burstLen;
      let client = drq.client;
      let cnt = req_burstLen >> beat_shift;
      let tag <- toGet(compFifo1).get;
      if(killv[drq.req_tag[5:4]] == False) begin
	 compFifo0.enq(extend(client));
	 readBufferBram.portB.request.put(BRAMRequest{write:False, address:{tag,truncate(cnt)}, datain: ?, responseOnWrite: ?});
      end
      compCountReg <= cnt-1;
      compTagReg <= tag;
      compClientReg <= client;
      compTileReg <= drq.req_tag[5:4];
      if(debug) $display("mkMemReadInternal::complete_burst1a %h", client);
   endrule

   rule complete_burst1b if (compCountReg > 0);
      let cnt = compCountReg;
      let tag = compTagReg;
      let cli = compClientReg;
      if(killv[compTileReg] == False) begin
	 compFifo0.enq(extend(cli));
	 readBufferBram.portB.request.put(BRAMRequest{write:False, address:{tag,truncate(cnt)}, datain: ?, responseOnWrite: ?});
      end
      compCountReg <= cnt-1;
      if(debug) $display("mkMemReadInternal::complete_burst1b count %h", compCountReg);
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
      let drq <- dreqBram.portA.response.get;
      let otag = drq.req_tag;
      let burstLen = burstReg;
      let first =    firstReg;
      let last  =    lastReg;
      if (first) begin
	 burstLen = drq.req_burstLen >> beat_shift;
	 last = drq.last;
	 dynamicAssert(last == (burstLen==1), "Last incorrect");
	 //$display("burstLen=%d dreqFifo.first.last=%d last=%d\n", burstLen, dreqFifo.first.last, last);
      end
      Bit#(TLog#(numTags)) tt = truncate(response_tag);
      readBufferBram.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, datain:MemData{data: response.data, tag: otag, last: last}, address:{tt,truncate(burstLen)}});
      if (last) begin
	 tag_gen.returnTag(truncate(response_tag));
      end
      last_readData <= cycle_cnt;
      if (debug) $display("read_data %d", cycle_cnt-last_readData);
      burstReg <= burstLen-1;
      firstReg <= burstLen-1 == 0;
      lastReg  <= burstLen-1 == 1;
   endrule
   
   Vector#(numServers, MemReadServer#(dataWidth)) sv = newVector;
   for(Integer i = 0; i < valueOf(numServers); i=i+1) 
      sv[i] = (interface MemReadServer;
		  interface Put readReq;
		     method Action put(MemRequest req);
			last_loadClient <= cycle_cnt;
			let mmusel = req.sglId[31:16];
      			if (debug) $display("mkMemReadInternal::loadClient %d %d %d", i, mmusel, cycle_cnt-last_loadClient);
			if (mmusel >= fromInteger(valueOf(numMMUs)))
			   dmaErrorFifo.enq(DmaError { errorType: DmaErrorMMUOutOfRange_r, pref: req.sglId });
   			else if (sglid_outofrange(req.sglId))
			   dmaErrorFifo.enq(DmaError { errorType: DmaErrorSGLIdOutOfRange_r, pref: req.sglId });
   			else if (stopv[req.tag[5:4]] == False) begin
   			   lreqFifo.enq(LRec{req:req, client:fromInteger(i)});
   			   mmus[mmusel].request.put(ReqTup{id:truncate(req.sglId),off:req.offset});
   			end
		     endmethod
		  endinterface
		  interface Get readData;
		     method ActionValue#(MemData#(dataWidth)) get if (compFifo0.first == fromInteger(i));
			compFifo0.deq;
			let data <- readBufferBram.portB.response.get;
			if (debug) $display("mkMemReadInternal::comp %d  %x %d", i, data.data, cycle_cnt-last_comp);
			last_comp <= cycle_cnt;
			return data;
		     endmethod
		  endinterface
	       endinterface);
   
   interface servers = sv;
   interface PhysMemReadClient client;
      interface Get readReq;
	 method ActionValue#(PhysMemRequest#(addrWidth)) get();
	    reqFifo.deq;
	    let req = reqFifo.first.req;
	    let physAddr = reqFifo.first.pa;
	    let client = reqFifo.first.client;
	    let rename_tag = reqFifo.first.rename_tag;
	    if (False && physAddr[31:24] != 0)
	       $display("req_ar: funny physAddr req.sglId=%d req.offset=%h physAddr=%h", req.sglId, req.offset, physAddr);
	    dreqBram.portB.request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(rename_tag),
						   datain:DRec{req_tag:req.tag, req_burstLen: req.burstLen, client:client, rename_tag:rename_tag, last:(req.burstLen == fromInteger(valueOf(dataWidthBytes)))}});
	    //$display("readReq: client=%d, rename_tag=%d, physAddr=%h req.burstLen=%d beat_shift=%d last=%d", client,rename_tag,physAddr, req.burstLen, beat_shift, req.burstLen == beat_shift);
	    if (debug) $display("read_client.readReq %d", cycle_cnt-last_readReq);
	    last_readReq <= cycle_cnt;
	    return PhysMemRequest{addr:physAddr, burstLen:req.burstLen, tag:rename_tag};
	 endmethod
      endinterface
      interface Put readData;
	 method Action put(MemData#(dataWidth) response);
	    readDataPipelineFifo.enq(response);
	    dreqBram.portA.request.put(BRAMRequest{write:False, address:truncate(response.tag), datain: ?, responseOnWrite: ?});
	    beatCount <= beatCount+1;
	 endmethod
      endinterface
   endinterface
   interface Put tileControl;
      method Action put(TileControl tc);
	 let tile = tc.tile;
	 let kv = True;
	 let sv = True;
	 if (tc.state == Running || tc.state == Stopped)
	    kv = False;
	 if (tc.state == Running)
	    sv = False;
	 killv[tile] <= kv;
	 stopv[tile] <= sv;
      endmethod
   endinterface
   interface DmaDbg dbg;
      method ActionValue#(DmaDbgRec) dbg();
	 return DmaDbgRec{x:0, y:0, z:0, w:0};
      endmethod
      method ActionValue#(Bit#(64)) getMemoryTraffic();
	 return extend(beatCount);
      endmethod
   endinterface
endmodule

module mkMemWriteInternal#(MemServerIndication ind, 
			   Vector#(numMMUs,Server#(ReqTup,Bit#(addrWidth))) mmus)
   (MemWriteInternal#(addrWidth, dataWidth, numTags, numServers))
   provisos(Log#(dataWidthBytes,beatShift)
	    ,Div#(dataWidth,8,dataWidthBytes)
	    ,Add#(beatShift, a__, 8)
	    ,Add#(b__, TLog#(numTags), 6)
	    );
   
   let debug = False;

   // stopping/killing infra
   Vector#(4,Reg#(Bool)) killv <- replicateM(mkReg(False));
   Vector#(4,Reg#(Bool)) stopv <- replicateM(mkReg(False));

   // stage 0: address translation (latency = MMU_PIPELINE_DEPTH)
   FIFO#(LRec#(numServers,addrWidth)) lreqFifo <- mkSizedFIFO(valueOf(MMU_PIPELINE_DEPTH));
   // stage 1: address validation (latency = 1)
   FIFO#(RRec#(numServers,addrWidth))  reqFifo <- mkFIFO;
   // stage 2: write commands
   FIFO#(DRec#(numServers, addrWidth)) dreqFifo <- mkSizedFIFO(valueOf(numTags));
   // stage 3: write data 
   BRAM2Port#(Bit#(TLog#(numTags)), RResp#(numServers,addrWidth)) respFifos <- mkBRAM2Server(defaultValue);
   TagGen#(numTags) tag_gen <- mkTagGen;
   FIFO#(RResp#(numServers,addrWidth)) respFifos_buff <- mkFIFO;

   Reg#(Bit#(BurstLenSize)) burstReg <- mkReg(0);
   Reg#(Bool)               firstReg <- mkReg(True);
   Reg#(Bool)               lastReg <- mkReg(False);
   Reg#(Bit#(BeatCountSize)) beatCount <- mkReg(0);
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
      
   FIFO#(MemData#(dataWidth)) memDataFifo <- mkFIFO();
   Vector#(numServers, FIFO#(MemData#(dataWidth))) clientWriteData <- replicateM(mkFIFO);
   
   if(valueOf(numServers) > 0)
      rule memdata;
	 let drq = dreqFifo.first;
	 let req_tag = drq.req_tag;
	 let req_burstLen = drq.req_burstLen;
	 let rename_tag = drq.rename_tag;
	 let client = drq.client;
	 MemData#(dataWidth) tagdata = unpack(0);
	 if (killv[req_tag[5:4]] == False) begin
	    tagdata = clientWriteData[client].first;
	    clientWriteData[client].deq;
	 end
	 let burstLen = burstReg;
	 let first    = firstReg;
	 let last     = lastReg;
	 if (first) begin
	    burstLen = req_burstLen >> beat_shift;
	    last     = dreqFifo.first.last;
	    respFifos.portA.request.put(BRAMRequest{write:True,responseOnWrite:False, address:truncate(rename_tag), datain:RResp{orig_tag:req_tag, client:client}});
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
   
   rule fill_respFifos_buff;
      let rv <- respFifos.portB.response.get;
      respFifos_buff.enq(rv);
   endrule
   
   Vector#(numServers, MemWriteServer#(dataWidth)) sv = newVector;
   for(Integer i = 0; i < valueOf(numServers); i=i+1) 
      sv[i] = (interface MemWriteServer;
		  interface Put writeReq;
		     method Action put(MemRequest req);
      			if (debug) $display("mkMemWriteInternal::loadClient %d %d", i, cycle_cnt-last_loadClient);
			last_loadClient <= cycle_cnt;
			let mmusel = req.sglId[31:16];
			if (mmusel >= fromInteger(valueOf(numMMUs)))
			   dmaErrorFifo.enq(DmaError { errorType: DmaErrorMMUOutOfRange_w, pref: req.sglId });
   			else if (sglid_outofrange(req.sglId))
			   dmaErrorFifo.enq(DmaError { errorType: DmaErrorSGLIdOutOfRange_w, pref: req.sglId });
   			else if (stopv[req.tag[5:4]] == False) begin
   			   lreqFifo.enq(LRec{req:req, client:fromInteger(i)});
   			   mmus[mmusel].request.put(ReqTup{id:truncate(req.sglId),off:req.offset});
   			end
		     endmethod
		  endinterface
		  interface Put writeData = toPut(clientWriteData[i]);
		  interface Get writeDone;
		     method ActionValue#(Bit#(MemTagSize)) get if (respFifos_buff.first.client == fromInteger(i));
			respFifos_buff.deq;
			return respFifos_buff.first.orig_tag;
		     endmethod
		  endinterface
	       endinterface);
   
   interface servers = sv;
   interface PhysMemWriteClient client;
      interface Get writeReq;
	 method ActionValue#(PhysMemRequest#(addrWidth)) get();
	    let req = reqFifo.first.req;
	    let physAddr = reqFifo.first.pa;
	    let client = reqFifo.first.client;
	    let rename_tag = reqFifo.first.rename_tag;
	    reqFifo.deq;
	    dreqFifo.enq(DRec{req_tag:req.tag, req_burstLen: req.burstLen, client:client, rename_tag:rename_tag, last: (req.burstLen == fromInteger(valueOf(dataWidthBytes))) });
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
   interface Put tileControl;
      method Action put(TileControl tc);
	 let tile = tc.tile;
	 let kv = True;
	 let sv = True;
	 if (tc.state == Running || tc.state == Stopped)
	    kv = False;
	 if (tc.state == Running)
	    sv = False;
	 killv[tile] <= kv;
	 stopv[tile] <= sv;
      endmethod
   endinterface
   interface DmaDbg dbg;
      method ActionValue#(DmaDbgRec) dbg();
	 return DmaDbgRec{x:fromInteger(valueOf(numServers)), y:?, z:?, w:?};
      endmethod
      method ActionValue#(Bit#(64)) getMemoryTraffic();
	 return extend(beatCount);
      endmethod
   endinterface
endmodule


