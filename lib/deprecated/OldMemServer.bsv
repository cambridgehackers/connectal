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
`include "ConnectalProjectConfig.bsv"
import FIFO::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import Assert::*;

// CONNECTAL Libraries
import ConnectalMemTypes::*;
import ConnectalMemory::*;
import ConnectalMMU::*;

`ifdef SIMULATION
import "BDPI" function ActionValue#(Bit#(32)) pareff(Bit#(32) handle, Bit#(32) size);
`endif

interface MemServer#(numeric type addrWidth, numeric type dataWidth);
   interface DmaConfig request;
   interface MemMaster#(addrWidth, dataWidth) master;
endinterface

interface MemWriteInternal#(numeric type addrWidth, numeric type dataWidth);
   interface DmaDbg dbg;
   interface MemWriteClient#(addrWidth,dataWidth) write_client;
   interface Get#(Tuple2#(Bit#(6),Bit#(6))) tagMismatch;
endinterface

interface MemReadInternal#(numeric type addrWidth, numeric type dataWidth);
   interface DmaDbg dbg;
   interface MemReadClient#(addrWidth,dataWidth) read_client;
   interface Get#(Tuple2#(Bit#(6),Bit#(6))) tagMismatch;
endinterface

function Bool bad_pointer(SGLId p);
   return (p > fromInteger(valueOf(MaxNumSGLists)) || p == 0);
endfunction

typedef struct {MemRequest req;
		Bit#(6) rename_tag;
		Bit#(addrWidth) pa;
		DmaChannelId chan; } IRec#(type addrWidth) deriving(Bits);
		 
module mkMemReadInternal#(Vector#(numReadClients, MemReadClient#(dataWidth)) readClients, 
			     DmaIndication dmaIndication,
			     Server#(Tuple2#(SGListId,Bit#(MemOffsetSize)),Bit#(addrWidth)) sgl) 
   (MemReadInternal#(addrWidth, dataWidth))

   provisos(Add#(b__, addrWidth, 64), 
	    Add#(c__, 12, addrWidth), 
	    Add#(1, c__, d__),
	    Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift));
   
   FIFO#(IRec#(addrWidth)) lreqFifo <- mkSizedFIFO(1);
   FIFO#(IRec#(addrWidth))  reqFifo <- mkSizedFIFO(1);
   FIFO#(IRec#(addrWidth)) dreqFifo <- mkSizedFIFO(32);

   Reg#(Bit#(8))           burstReg <- mkReg(0);
   Vector#(numReadClients, Reg#(Bit#(64))) beatCounts <- replicateM(mkReg(0));
   let beat_shift = fromInteger(valueOf(beatShift));

   // report a tag mismatch for oo completions (in which 
   // case we will need to introduce completion buffers)
   FIFO#(Tuple2#(Bit#(6),Bit#(6))) tag_mismatch <- mkSizedFIFO(32);

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
      rule loadChannel;
	 MemRequest req <- readClients[selectReg].readReq.get();
	 //$display("dmaread.loadChannel activeChan=%d handle=%h addr=%h burst=%h", selectReg, req.sglId, req.offset, req.burstLen);
	 if (bad_pointer(req.sglId))
	    dmaIndication.badPointer(req.sglId);
	 else begin
	    lreqFifo.enq(IRec{req:req, rename_tag:?, pa:?, chan:fromInteger(selectReg)});
	    sgl.request.put(tuple2(truncate(req.sglId),req.offset));
	 end
      endrule
   
   rule checkSglResp;
      let physAddr <- sgl.response.get;
      let req = lreqFifo.first.req;
      let chan = lreqFifo.first.chan;
      lreqFifo.deq();
      if (physAddr <= (1 << valueOf(SGListPageShift0))) begin
	 // squash request
	 $display("dmaRead: badAddr pointer=%d offset=%h physAddr=%h", req.sglId, req.offset, physAddr);
	 dmaIndication.badAddr(req.sglId, extend(req.offset), extend(physAddr));
      end
      else begin
	 if (False && physAddr[31:24] != 0)
	    $display("checkSglResp: funny physAddr req.sglId=%d req.offset=%h physAddr=%h", req.sglId, req.offset, physAddr);
	 reqFifo.enq(IRec{req:req, rename_tag:truncate(chan), pa:physAddr, chan:chan});
      end
   endrule

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

   interface MemReadClient read_client;
      interface Get readReq;
	 method ActionValue#(PhysMemRequest#(addrWidth)) get;
	    let req = reqFifo.first.req;
	    let physAddr = reqFifo.first.pa;
	    let rename_tag = reqFifo.first.rename_tag;
	    reqFifo.deq;
	    //$display("mkMemReadInternal::req_ar tag=%d rename_tag=%d len=%d activeChan=%d", req.tag, rename_tag, req.burstLen, reqFifo.first.chan);
	    if (False && physAddr[31:24] != 0)
	       $display("req_ar: funny physAddr req.sglId=%d req.offset=%h physAddr=%h", req.sglId, req.offset, physAddr);
	    dreqFifo.enq(reqFifo.first);
	    return PhysMemRequest{addr:physAddr, burstLen:req.burstLen, tag:rename_tag};
	 endmethod
      endinterface
      interface Put readData;
	 method Action put(MemData#(dataWidth) response);
	    let activeChan = dreqFifo.first.chan;
	    let req = dreqFifo.first.req;
	    let rename_tag = dreqFifo.first.rename_tag;
	    if (valueOf(numReadClients) > 0)
	       readClients[activeChan].readData.put(MemData { data: response.data, tag: req.tag});

	    let burstLen = burstReg;
	    if (burstLen == 0)
	       burstLen = req.burstLen >> beat_shift;

	    if (burstLen == 1)
	       dreqFifo.deq();
   
	    if (response.tag != rename_tag) begin
	       tag_mismatch.enq(tuple2(response.tag,rename_tag));
	       $display("mkMemReadInternal::tag_mismatch %d %d", response.tag, rename_tag);
	    end
	    //$display("mkMemReadInternal::resp_read rename_tag=%d response.tag=%d burstLen=%d activeChan=%d", rename_tag, response.tag, burstLen, activeChan);
	    burstReg <= burstLen-1;

	    if(valueOf(numReadClients) > 0)
	       beatCounts[activeChan] <= beatCounts[activeChan]+1;
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
   interface Get tagMismatch = fifoToGet(tag_mismatch);
endmodule


module mkMemWriteInternal#(Vector#(numWriteClients, MemWriteClient#(dataWidth)) writeClients,
			      DmaIndication dmaIndication, 
			      Server#(Tuple2#(SGListId,Bit#(MemOffsetSize)),Bit#(addrWidth)) sgl)

   (MemWriteInternal#(addrWidth, dataWidth))
   
   provisos(Add#(b__, addrWidth, 64), 
	    Add#(c__, 12, addrWidth), 
	    Add#(1, c__, d__),
	    Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift));
   
   FIFO#(IRec#(addrWidth)) lreqFifo <- mkSizedFIFO(1);
   FIFO#(IRec#(addrWidth))  reqFifo <- mkSizedFIFO(1);
   FIFO#(IRec#(addrWidth)) dreqFifo <- mkSizedFIFO(32);
   FIFO#(IRec#(addrWidth)) respFifo <- mkSizedFIFO(32);

   Reg#(Bit#(8))         burstReg <- mkReg(0);   
   Vector#(numWriteClients, Reg#(Bit#(64))) beatCounts <- replicateM(mkReg(0));
   let beat_shift = fromInteger(valueOf(beatShift));
   
   // report a tag mismatch for oo completions (in which 
   // case we will need to introduce completion buffers)
   FIFO#(Tuple2#(Bit#(6),Bit#(6))) tag_mismatch <- mkSizedFIFO(32);

   for (Integer selectReg = 0; selectReg < valueOf(numWriteClients); selectReg = selectReg + 1)
       rule loadChannel;
	  MemRequest req <- writeClients[selectReg].writeReq.get();
	  //$display("dmawrite.loadChannel activeChan=%d handle=%h addr=%h burst=%h debugReq=%d", selectReg, req.sglId, req.offset, req.burstLen, debugReg);
	  if (bad_pointer(req.sglId))
	     dmaIndication.badPointer(req.sglId);
	  else begin
	     lreqFifo.enq(IRec{req:req, rename_tag:?, pa:?, chan:fromInteger(selectReg)});
	     sgl.request.put(tuple2(truncate(req.sglId),req.offset));
	  end
       endrule
   
   rule checkSglResp;
      let physAddr <- sgl.response.get;
      let req = lreqFifo.first.req;
      let chan = lreqFifo.first.chan;
      lreqFifo.deq();
      if (physAddr <= (1 << valueOf(SGListPageShift0))) begin
	 // squash request
	 $display("dmaWrite: badAddr handle=%d addr=%h physAddr=%h", req.sglId, req.offset, physAddr);
	 dmaIndication.badAddr(req.sglId, extend(req.offset), extend(physAddr));
      end
      else begin
	 reqFifo.enq(IRec{req:req, rename_tag:truncate(chan), pa:physAddr, chan:chan});
      end
   endrule

   interface DmaDbg dbg;
      method ActionValue#(DmaDbgRec) dbg();
	 return DmaDbgRec{x:fromInteger(valueOf(numWriteClients)), y:?, z:?, w:?};
      endmethod
      method ActionValue#(Bit#(64)) getMemoryTraffic(Bit#(32) client);
	 return (valueOf(numWriteClients) > 0 && client < fromInteger(valueOf(numWriteClients))) ? beatCounts[client] : 0;
      endmethod
   endinterface
   
   interface MemWriteClient write_client;
      interface Get writeReq;
	 method ActionValue#(PhysMemRequest#(addrWidth)) get();
	    let req = reqFifo.first.req;
	    let physAddr = reqFifo.first.pa;
	    let rename_tag = reqFifo.first.rename_tag;
	    reqFifo.deq;
	    //$display("dmaWrite addr physAddr=%h burstReg=%d", physAddr, req.burstLen);
   
	    dreqFifo.enq(reqFifo.first);
	    return PhysMemRequest{addr:physAddr, burstLen:req.burstLen, tag:rename_tag};
	 endmethod
      endinterface
      interface Get writeData;
	 method ActionValue#(MemData#(dataWidth)) get();
	    let activeChan = dreqFifo.first.chan;
	    let req = dreqFifo.first.req;
	    let rename_tag = dreqFifo.first.rename_tag;
	    MemData#(dataWidth) tagdata = unpack(0);
	    if (valueOf(numWriteClients) > 0)
	       tagdata <- writeClients[activeChan].writeData.get();
	    let burstLen = burstReg;
	    if (burstLen == 0)
	       burstLen = req.burstLen >> beat_shift;

	    if (burstLen == 1) begin
	       dreqFifo.deq();
	       respFifo.enq(dreqFifo.first);
	    end

	    //$display("dmaWrite data data=%h burstLen=%d", tagdata.data, burstLen);
	    burstReg <= burstLen-1;
	    if(valueOf(numWriteClients) > 0)
	       beatCounts[activeChan] <= beatCounts[activeChan]+1;
	    
	    return MemData { data: tagdata.data,  tag: rename_tag };
	 endmethod
      endinterface
      interface Put writeDone;
	 method Action put(Bit#(6) resp);
	    let activeChan = respFifo.first.chan;
	    let rename_tag = respFifo.first.rename_tag;
	    let orig_tag = respFifo.first.req.tag;
	    if (resp != rename_tag) begin
	       tag_mismatch.enq(tuple2(resp,rename_tag));
	       $display("mkMemWriteInternal::tag_mismatch %d %d", resp, rename_tag);
	    end
	    respFifo.deq();
	    if (valueOf(numWriteClients) > 0) begin
	       writeClients[activeChan].writeDone.put(orig_tag);
	    end
	 endmethod
      endinterface
   endinterface
   interface Get tagMismatch = fifoToGet(tag_mismatch);
endmodule

//
// @brief Creates a Dma controller for Dma read and write clients
//
// @param dmaIndication Interface for notifying software
// @param readClients The read clients.
// @param writeClients The writeclients.
//
module mkMemServer#(DmaIndication dmaIndication,
		    Vector#(numReadClients, MemReadClient#(dataWidth)) readClients,
		    Vector#(numWriteClients, MemWriteClient#(dataWidth)) writeClients)

   (MemServer#(addrWidth, dataWidth))
   
   provisos (Add#(1,a__,dataWidth),
	     Add#(b__, TSub#(addrWidth, 12), 32),
	     Add#(c__, 12, addrWidth),
	     Add#(d__, addrWidth, 64),
	     Add#(e__, TSub#(addrWidth, 12), MemOffsetSize),
	     Add#(f__, c__, MemOffsetSize),
	     Add#(g__, addrWidth, 40),
	     Mul#(TDiv#(dataWidth, 8), 8, dataWidth));
   
   MMU#(addrWidth) sgl <- mkMMU(dmaIndication);
   FIFO#(void)   addrReqFifo <- mkFIFO;

   MemReadInternal#(addrWidth, dataWidth) reader <- mkMemReadInternal(readClients, dmaIndication, sgl.addr[0]);
   MemWriteInternal#(addrWidth, dataWidth) writer <- mkMemWriteInternal(writeClients, dmaIndication, sgl.addr[1]);
   
   rule tag_mismatch_read;
      let rv <- reader.tagMismatch.get;
      dmaIndication.tagMismatch(ChannelType_Read, extend(tpl_1(rv)), extend(tpl_2(rv)));
   endrule
   
   rule tag_mismatch_write;
      let rv <- writer.tagMismatch.get;
      dmaIndication.tagMismatch(ChannelType_Write, extend(tpl_1(rv)), extend(tpl_2(rv)));
   endrule

   rule sglistEntry;
      addrReqFifo.deq;
      let physAddr <- sgl.addr[0].response.get;
      dmaIndication.addrResponse(zeroExtend(physAddr));
   endrule
   
   interface DmaConfig request;
      method Action getStateDbg(ChannelType rc);
	 let rv = ?;
	 if (rc == ChannelType_Read)
	    rv <- reader.dbg.dbg;
	 else
	    rv <- writer.dbg.dbg;
	 dmaIndication.reportStateDbg(rv);
      endmethod
      method Action getMemoryTraffic(ChannelType rc, Bit#(32) client);
	 if (rc == ChannelType_Read) begin
	    let rv <- reader.dbg.getMemoryTraffic(client);
	    dmaIndication.reportMemoryTraffic(rv);
	 end
	 else begin
	    let rv <- writer.dbg.getMemoryTraffic(client);
	    dmaIndication.reportMemoryTraffic(rv);
	 end
      endmethod
      method Action sglist(Bit#(32) pref, Bit#(MemOffsetSize) addr, Bit#(32) len);
	 if (bad_pointer(pref))
	    dmaIndication.badPointer(pref);
`ifdef SIMULATION
	 let va <- pareff(pref, len);
         addr[39:32] = truncate(pref);
`endif
	 sgl.sglist(pref, addr, len);
      endmethod
      method Action region(Bit#(32) pointer, Bit#(40) barr8, Bit#(8) off8, Bit#(40) barr4, Bit#(8) off4, Bit#(40) barr0, Bit#(8) off0);
	 sgl.region(pointer,barr8,off8,barr4,off4,barr0,off0);
      endmethod
      method Action addrRequest(Bit#(32) pointer, Bit#(32) offset);
	 addrReqFifo.enq(?);
	 sgl.addr[0].request.put(tuple2(truncate(pointer), extend(offset)));
      endmethod
   endinterface

   interface MemMaster master;
      interface MemReadClient read_client = reader.read_client;
      interface MemWriteClient write_client = writer.write_client;
   endinterface
endmodule

