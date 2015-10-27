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
import ConnectalConfig::*;
`include "ConnectalProjectConfig.bsv"

typedef 32 BeatCountSize;

typedef 9 MMU_PIPELINE_DEPTH;

interface DmaDbg;
   method ActionValue#(Bit#(64)) getMemoryTraffic();
   method ActionValue#(DmaDbgRec) dbg();
endinterface

interface MemWriteInternal#(numeric type addrWidth, numeric type busWidth, numeric type numTags, numeric type numServers);
   interface DmaDbg dbg;
   interface Put#(TileControl) tileControl;
   interface PhysMemWriteClient#(addrWidth,busWidth) client;
   interface Vector#(numServers, MemWriteServer#(busWidth)) servers;
endinterface

interface MemReadInternal#(numeric type addrWidth, numeric type busWidth, numeric type numTags, numeric type numServers);
   interface DmaDbg dbg;
   interface Put#(TileControl) tileControl;
   interface PhysMemReadClient#(addrWidth,busWidth) client;
   interface Vector#(numServers, MemReadServer#(busWidth)) servers;
endinterface

function Bool sglid_outofrange(SGLId p);
   return ((p[15:0]) >= fromInteger(valueOf(MaxNumSGLists)));
endfunction

import RegFile::*;

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
			  Vector#(numMMUs,Server#(AddrTransRequest,Bit#(addrWidth))) mmus) 
   (MemReadInternal#(addrWidth, busWidth, numTags, numServers))
   provisos(Log#(busWidthBytes,beatShift)
	    ,Div#(busWidth,8,busWidthBytes)
	    ,Add#(beatShift, a__, 8)
	    ,Add#(b__, TLog#(numTags), 6)
	    ,Add#(beatShift, c__, BurstLenSize)
	    );
   
   // stopping/killing infra
   Vector#(4,Reg#(Bool)) killv <- replicateM(mkReg(False));
   Vector#(4,Reg#(Bool)) stopv <- replicateM(mkReg(False));
   
   // stage 0: address translation (latency = MMU_PIPELINE_DEPTH)
   FIFO#(LRec#(numServers,addrWidth)) clientRequest <- mkSizedFIFO(valueOf(MMU_PIPELINE_DEPTH));
   // stage 1: address validation (latency = 1)
   FIFO#(RRec#(numServers,addrWidth))  serverRequest <- mkFIFO;
   // stage 2: read commands
   BRAM_Configure bramConfig = defaultValue;
   if (mainClockPeriod < 8)
      bramConfig.latency = 2;
   BRAM2Port#(Bit#(TLog#(numTags)), DRec#(numServers,addrWidth)) serverProcessing <- mkBRAM2Server(bramConfig);
   BRAM2Port#(Bit#(TAdd#(TLog#(numTags),TSub#(BurstLenSize,beatShift))), MemData#(busWidth)) clientData <- mkBRAM2Server(bramConfig);
   // stage 3: read data 
   FIFO#(MemData#(busWidth)) serverData <- mkFIFO;
   
   let verbose = False;
   
   RegFile#(Bit#(TLog#(numTags)),Tuple2#(Bool,Bit#(BurstLenSize))) clientBurstLen <- mkRegFileFull();
   Reg#(Bit#(BurstLenSize)) burstReg <- mkReg(0);
   Reg#(Bool)               firstReg <- mkReg(True);
         
   Reg#(Bit#(32))  beatCount <- mkReg(0);
   let beat_shift = fromInteger(valueOf(beatShift));
   TagGen#(numTags) tag_gen <- mkTagGen;

   Reg#(Bit#(BurstLenSize))      compCountReg <- mkReg(0);
   Reg#(Bit#(TLog#(numTags)))    compTagReg <- mkReg(0);
   Reg#(Bit#(TLog#(TMax#(1,numServers)))) compClientReg <- mkReg(0);
   Reg#(Bit#(2))                 compTileReg <- mkReg(0);
   FIFO#(Bit#(TAdd#(1,TLog#(TMax#(1,numServers))))) clientSelect <- mkFIFO;
   FIFO#(Bit#(TLog#(numTags)))   serverTag <- mkFIFO;
   
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
         
   rule checkMmuResp;
      let request <- toGet(clientRequest).get();
      let physAddr <- mmus[request.req.sglId[31:16]].response.get;
      let rename_tag <- tag_gen.getTag;
      let burstLenBeats = request.req.burstLen >> beat_shift;
      clientBurstLen.upd(truncate(rename_tag), tuple2(burstLenBeats == 1, burstLenBeats));
      
      serverRequest.enq(RRec{req:request.req, pa:physAddr, client:request.client, rename_tag:extend(rename_tag)});
      if (verbose) $display("mkMemReadInternal::checkMmuResp: client=%d, tag=%d rename_tag=%d burstLen=%d", request.client, request.req.tag, rename_tag, burstLenBeats);
      if (verbose) $display("mkMemReadInternal::mmuResp %d %d", request.client, cycle_cnt-last_mmuResp);
      last_mmuResp <= cycle_cnt;
   endrule
   
   rule read_data;
      let response <- toGet(serverData).get();
      let drq <- serverProcessing.portA.response.get;
      let tag = drq.req_tag;
      match { .last, .burstLen } = clientBurstLen.sub(truncate(response.tag));
      let first   = firstReg;
      if (first) begin
	 dynamicAssert(last == (burstLen==1), "Last incorrect");
      end
      if (last && burstLen != 1)
	 $display("rename_tag=%d tag=%d burstLen=%d last=%d", response.tag, tag, burstLen, last);
      Bit#(TLog#(numTags)) tt = truncate(response.tag);
      clientData.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, datain:MemData{data: response.data, tag: tag, last: last},
					       address:{tt,truncate(burstLen)}});
      if (last) begin
	 tag_gen.returnTag(truncate(response.tag));
      end
      last_readData <= cycle_cnt;
      if (verbose) $display("mkMemReadInternal::read_data cyclediff %d", cycle_cnt-last_readData);
      clientBurstLen.upd(truncate(response.tag), tuple2((burstLen-1 == 1),burstLen-1));
      firstReg <= response.last;
   endrule

   rule tag_completed;
      let tag <- tag_gen.complete;
      serverProcessing.portB.request.put(BRAMRequest{write:False, address:tag, datain: ?, responseOnWrite: ?});
      serverTag.enq(tag);
      if(verbose) $display("mkMemReadInternal::complete_burst0 %h", tag);
   endrule
   
   rule complete_burst1a if (compCountReg==0);
      let drq <- serverProcessing.portB.response.get;
      let req_burstLen = drq.req_burstLen;
      let client = drq.client;
      let cnt = req_burstLen >> beat_shift;
      let tag <- toGet(serverTag).get;
      if(killv[drq.req_tag[5:4]] == False) begin
	 clientSelect.enq(extend(client));
	 clientData.portB.request.put(BRAMRequest{write:False, address:{tag,truncate(cnt)}, datain: ?, responseOnWrite: ?});
      end
      compCountReg <= cnt-1;
      compTagReg <= tag;
      compClientReg <= client;
      compTileReg <= drq.req_tag[5:4];
      if(verbose) $display("mkMemReadInternal::complete_burst1a %h", client);
   endrule

   rule burst_remainder if (compCountReg > 0);
      let cnt = compCountReg;
      let tag = compTagReg;
      let client = compClientReg;
      if(killv[compTileReg] == False) begin
	 clientSelect.enq(extend(client));
	 clientData.portB.request.put(BRAMRequest{write:False, address:{tag,truncate(cnt)}, datain: ?, responseOnWrite: ?});
      end
      compCountReg <= cnt-1;
      if(verbose) $display("mkMemReadInternal::complete_burst1b count %h", compCountReg);
   endrule
   
   Vector#(numServers, MemReadServer#(busWidth)) sv = newVector;
   for(Integer i = 0; i < valueOf(numServers); i=i+1) 
      sv[i] = (interface MemReadServer;
		  interface Put readReq;
		     method Action put(MemRequest req);
			last_loadClient <= cycle_cnt;
			let mmusel = req.sglId[31:16];
      			if (verbose) $display("mkMemReadInternal::loadClient server %d mmusel %d burstLen %d tag %d cycle %d",
			   i, mmusel, req.burstLen >> beat_shift, req.tag, cycle_cnt-last_loadClient);
			if (mmusel >= fromInteger(valueOf(numMMUs)))
			   dmaErrorFifo.enq(DmaError { errorType: DmaErrorMMUOutOfRange_r, pref: req.sglId });
   			else if (sglid_outofrange(req.sglId))
			   dmaErrorFifo.enq(DmaError { errorType: DmaErrorSGLIdOutOfRange_r, pref: req.sglId });
   			else if (stopv[req.tag[5:4]] == False) begin
   			   clientRequest.enq(LRec{req:req, client:fromInteger(i)});
   			   mmus[mmusel].request.put(AddrTransRequest{id:truncate(req.sglId),off:req.offset});
   			end
		     endmethod
		  endinterface
		  interface Get readData;
		     method ActionValue#(MemData#(busWidth)) get if (clientSelect.first == fromInteger(i));
			clientSelect.deq;
			let data <- clientData.portB.response.get;
			if (verbose) $display("mkMemReadInternal::comp server %d data %x cycle %d", i, data.data, cycle_cnt-last_comp);
			last_comp <= cycle_cnt;
			return data;
		     endmethod
		  endinterface
	       endinterface);
   
   interface servers = sv;
   interface PhysMemReadClient client;
      interface Get readReq;
	 method ActionValue#(PhysMemRequest#(addrWidth,dataWidth)) get();
	    let request <- toGet(serverRequest).get;
	    let req = request.req;
	    if (False && request.pa[31:24] != 0)
	       $display("mkMemReadInternal::req_ar: funny physAddr req.sglId=%d req.offset=%h physAddr=%h", req.sglId, req.offset, request.pa);
	    serverProcessing.portB.request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(request.rename_tag),
						   datain:DRec{req_tag:req.tag, req_burstLen: req.burstLen, client:request.client, rename_tag:request.rename_tag, last:(req.burstLen == fromInteger(valueOf(busWidthBytes)))}});
	    //$display("mkMemReadInternal::readReq: client=%d, rename_tag=%d, physAddr=%h req.burstLen=%d beat_shift=%d last=%d", request.client,request.rename_tag,request.pa, req.burstLen, beat_shift, req.burstLen == beat_shift);
	    if (verbose) $display("mkMemReadInternal::read_client.readReq %d", cycle_cnt-last_readReq);
	    last_readReq <= cycle_cnt;
	    return PhysMemRequest{addr:request.pa, burstLen:req.burstLen, tag:request.rename_tag
`ifdef BYTE_ENABLES
				  , firstbe: request.req.firstbe, lastbe: request.req.lastbe
`endif
	       };
	 endmethod
      endinterface
      interface Put readData;
	 method Action put(MemData#(busWidth) response);
	    serverData.enq(response);
	    serverProcessing.portA.request.put(BRAMRequest{write:False, address:truncate(response.tag), datain: ?, responseOnWrite: ?});
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
			   Vector#(numMMUs,Server#(AddrTransRequest,Bit#(addrWidth))) mmus)
   (MemWriteInternal#(addrWidth, busWidth, numTags, numServers))
   provisos(Log#(busWidthBytes,beatShift)
	    ,Div#(busWidth,8,busWidthBytes)
	    ,Add#(beatShift, a__, 8)
	    ,Add#(b__, TLog#(numTags), 6)
	    ,Add#(beatShift, c__, BurstLenSize)
	    );
   
   let verbose = False;

   // stopping/killing infra
   Vector#(4,Reg#(Bool)) killv <- replicateM(mkReg(False));
   Vector#(4,Reg#(Bool)) stopv <- replicateM(mkReg(False));

   // stage 0: address translation (latency = MMU_PIPELINE_DEPTH)
   FIFO#(LRec#(numServers,addrWidth)) clientRequest <- mkSizedFIFO(valueOf(MMU_PIPELINE_DEPTH));
   // stage 1: address validation (latency = 1)
   FIFO#(RRec#(numServers,addrWidth))  serverRequest <- mkFIFO;
   // stage 2: write commands
   FIFO#(DRec#(numServers, addrWidth)) serverProcessing <- mkSizedFIFO(valueOf(numTags));
   // stage 3: write data 
   BRAM2Port#(Bit#(TLog#(numTags)), RResp#(numServers,addrWidth)) respFifos <- mkBRAM2Server(defaultValue);
   TagGen#(numTags) tag_gen <- mkTagGen;
   FIFO#(RResp#(numServers,addrWidth)) clientResponse <- mkFIFO;

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
      let request <- toGet(clientRequest).get;
      let req = request.req;
      let client = request.client;
      let physAddr <- mmus[req.sglId[31:16]].response.get;
      let rename_tag <- tag_gen.getTag;
      serverRequest.enq(RRec{req:req, pa:physAddr, client:client, rename_tag:extend(rename_tag)});
      //if (verbose) $display("mkMemWriteInternal::checkMmuResp: client=%d, rename_tag=%d", client,rename_tag);
      if (verbose) $display("mkMemWriteInternal::mmuResp %d %d", client, cycle_cnt-last_mmuResp);
      last_mmuResp <= cycle_cnt;
   endrule
   
   rule writeDoneComp0;
      let tag <- tag_gen.complete;
      respFifos.portB.request.put(BRAMRequest{write:False, address:tag, datain: ?, responseOnWrite: ?});
   endrule
      
   FIFO#(MemData#(busWidth)) memDataFifo <- mkFIFO();
   Vector#(numServers, FIFO#(MemData#(busWidth))) clientWriteData <- replicateM(mkFIFO);
   
   if(valueOf(numServers) > 0)
      rule memdata;
	 let drq = serverProcessing.first;
	 let req_tag = drq.req_tag;
	 let req_burstLen = drq.req_burstLen;
	 let rename_tag = drq.rename_tag;
	 let client = drq.client;
	 MemData#(busWidth) tagdata = unpack(0);
	 if (killv[req_tag[5:4]] == False) begin
	    tagdata = clientWriteData[client].first;
	    clientWriteData[client].deq;
	 end
	 let burstLen = burstReg;
	 let first    = firstReg;
	 let last     = lastReg;
	 if (first) begin
	    burstLen = req_burstLen >> beat_shift;
	    last     = serverProcessing.first.last;
	    respFifos.portA.request.put(BRAMRequest{write:True,responseOnWrite:False, address:truncate(rename_tag), datain:RResp{orig_tag:req_tag, client:client}});
	 end
	 burstReg <= burstLen-1;
	 firstReg <= (burstLen-1 == 0);
	 lastReg  <= (burstLen-1 == 1);
	 beatCount <= beatCount+1;
	 if (last)
	    serverProcessing.deq();
	 //$display("mkMemWriteInternal::writeData: client=%d, rename_tag=%d", client, rename_tag);
	 memDataFifo.enq(MemData { data: tagdata.data,  tag:extend(rename_tag), last: last });
      endrule
   
   rule fill_clientResponse;
      let rv <- respFifos.portB.response.get;
      clientResponse.enq(rv);
   endrule
   
   Vector#(numServers, MemWriteServer#(busWidth)) sv = newVector;
   for(Integer i = 0; i < valueOf(numServers); i=i+1) 
      sv[i] = (interface MemWriteServer;
		  interface Put writeReq;
		     method Action put(MemRequest req);
      			if (verbose) $display("mkMemWriteInternal::loadClient %d %d", i, cycle_cnt-last_loadClient);
			last_loadClient <= cycle_cnt;
			let mmusel = req.sglId[31:16];
			if (mmusel >= fromInteger(valueOf(numMMUs)))
			   dmaErrorFifo.enq(DmaError { errorType: DmaErrorMMUOutOfRange_w, pref: req.sglId });
   			else if (sglid_outofrange(req.sglId))
			   dmaErrorFifo.enq(DmaError { errorType: DmaErrorSGLIdOutOfRange_w, pref: req.sglId });
   			else if (stopv[req.tag[5:4]] == False) begin
   			   clientRequest.enq(LRec{req:req, client:fromInteger(i)});
   			   mmus[mmusel].request.put(AddrTransRequest{id:truncate(req.sglId),off:req.offset});
   			end
		     endmethod
		  endinterface
		  interface Put writeData = toPut(clientWriteData[i]);
		  interface Get writeDone;
		     method ActionValue#(Bit#(MemTagSize)) get if (clientResponse.first.client == fromInteger(i));
			clientResponse.deq;
			return clientResponse.first.orig_tag;
		     endmethod
		  endinterface
	       endinterface);
   
   interface servers = sv;
   interface PhysMemWriteClient client;
      interface Get writeReq;
	 method ActionValue#(PhysMemRequest#(addrWidth,dataWidth)) get();
	    let request <- toGet(serverRequest).get();
	    let req = request.req;
	    let physAddr = request.pa;
	    let client = request.client;
	    let rename_tag = request.rename_tag;
	    serverProcessing.enq(DRec{req_tag:req.tag, req_burstLen: req.burstLen, client:client, rename_tag:rename_tag, last: (req.burstLen == fromInteger(valueOf(busWidthBytes))) });
	    //$display("mkMemWriteInternal::writeReq: client=%d, rename_tag=%d", client,rename_tag);
	    return PhysMemRequest{addr:physAddr, burstLen:req.burstLen, tag:extend(rename_tag)
`ifdef BYTE_ENABLES
				  , firstbe: req.firstbe, lastbe: req.lastbe
`endif
};
	 endmethod
      endinterface
      interface Get writeData = toGet(memDataFifo);
      interface Put writeDone;
	 method Action put(Bit#(MemTagSize) resp);
	    tag_gen.returnTag(truncate(resp));
	    if (verbose) $display("mkMemWriteInternal::writeDone: resp=%d", resp);
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


