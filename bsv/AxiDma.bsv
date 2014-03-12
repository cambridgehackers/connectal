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
import GetPutF::*;
import ClientServer::*;
import Assert::*;

// XBSV Libraries
import AxiMasterSlave::*;
import Dma::*;
import PortalMemory::*;
import Adapter::*;
import SGList::*;

`ifdef BSIM
import "BDPI" function ActionValue#(Bit#(32)) pareff(Bit#(32) handle, Bit#(32) size);
`endif

//
// @brief AxiDma provides the configuration and AXI bus interface for Dma
//
// @param dsz Number of bits in the data bus
//

interface AxiDmaServer#(numeric type addrWidth, numeric type dsz);
   interface DmaConfig request;
   interface Axi3Master#(addrWidth,dsz,6) m_axi;
endinterface

interface AxiDmaWriteInternal#(numeric type addrWidth, numeric type dsz);
   interface DmaDbg dbg;
   interface Axi3Master#(addrWidth,dsz,6) m_axi;
   interface Get#(Bool) tagMismatch;
endinterface

interface AxiDmaReadInternal#(numeric type addrWidth, numeric type dsz);
   interface DmaDbg dbg;
   interface Axi3Master#(addrWidth,dsz,6) m_axi;
   interface Get#(Bool) tagMismatch;
endinterface

function Bool bad_pointer(DmaPointer p);
   return (p > fromInteger(valueOf(MaxNumSGLists)) || p == 0);
endfunction

typedef enum {Idle, Translate, Address, Data, Done} InternalState deriving(Eq,Bits);
		 
		 
module mkAxiDmaReadInternal#(Integer numRequests, 
			     Vector#(numReadClients, DmaReadClient#(dsz)) readClients, 
			     DmaIndication dmaIndication,
			     Server#(Tuple2#(SGListId,Bit#(DmaOffsetSize)),Bit#(addrWidth)) sgl) 
   (AxiDmaReadInternal#(addrWidth, dsz))

   provisos(Add#(1,a__,dsz), Add#(b__, addrWidth, 64), Add#(c__, 12, addrWidth), Add#(1, c__, d__));
   
   FIFO#(DmaRequest)    lreqFifo <- mkSizedFIFO(1);
   FIFO#(DmaRequest)     reqFifo <- mkSizedFIFO(1);
   FIFO#(Bit#(addrWidth)) paFifo <- mkSizedFIFO(1);

   FIFO#(DmaChannelId)  chanFifo <- mkSizedFIFO(numRequests);
   FIFO#(DmaRequest)    dreqFifo <- mkSizedFIFO(numRequests);

   Reg#(Bit#(8))        burstReg <- mkReg(0);   
   Reg#(Bit#(64))      beatCount <- mkReg(0);
   
   // the choice of 5 is based on PCIE limitations
   Vector#(numReadClients, Reg#(Bit#(5)))  tag_gen   <- replicateM(mkReg(0)); 
   // a depth of 32 will guarantee per/client uniqueness of outstanding requests
   Vector#(numReadClients, FIFO#(Bit#(6))) tag_store <- replicateM(mkSizedFIFO(32)); 
   // report a tag mismatch for oo write completions (in which case we will need to introduce completion buffers)
   FIFO#(Bool) tag_mismatch <- mkSizedFIFO(32);
   
   for (Integer selectReg = 0; selectReg < valueOf(numReadClients); selectReg = selectReg + 1)
       rule loadChannel;
	  DmaRequest req <- readClients[selectReg].readReq.get();
	  //$display("dmaread.loadChannel activeChan=%d handle=%h addr=%h burst=%h", selectReg, req.pointer, req.offset, req.burstLen);
	  if (bad_pointer(req.pointer))
	     dmaIndication.badPointer(req.pointer);
	  else begin
	     lreqFifo.enq(req);
	     chanFifo.enq(fromInteger(selectReg));
	     sgl.request.put(tuple2(truncate(req.pointer),req.offset));
	  end
       endrule
   
   rule checkSglResp;
      let physAddr <- sgl.response.get;
      let req = lreqFifo.first();
      lreqFifo.deq();
      if (physAddr <= (1 << valueOf(SGListPageShift0))) begin
	 // squash request
	 $display("dmaRead: badAddr pointer=%d offset=%h physAddr=%h", req.pointer, req.offset, physAddr);
	 dmaIndication.badAddr(req.pointer, extend(req.offset), extend(physAddr));
	 chanFifo.deq;
      end
      else begin
	 let chan = chanFifo.first;
	 if (False && physAddr[31:24] != 0)
	    $display("checkSglResp: funny physAddr req.pointer=%d req.offset=%h physAddr=%h", req.pointer, req.offset, physAddr);
	 // overwrite user-supplied tag and store the original for the responses
	 reqFifo.enq(DmaRequest{pointer:req.pointer, offset:req.offset, burstLen:req.burstLen, tag:{0,tag_gen[chan]}});
	 tag_gen[chan] <= tag_gen[chan]+1;
	 tag_store[chan].enq(req.tag);
	 paFifo.enq(physAddr);
      end
   endrule

   interface DmaDbg dbg;
      method ActionValue#(DmaDbgRec) dbg();
	 return ?;
      endmethod
      method ActionValue#(Bit#(64)) getMemoryTraffic();
	 return beatCount;
      endmethod
   endinterface

   interface Axi3Master m_axi;
      interface Get req_ar;
	 method ActionValue#(Axi3ReadRequest#(addrWidth,6)) get();
	    let req = reqFifo.first();
	    reqFifo.deq();
	    let physAddr = paFifo.first();
	    paFifo.deq();

	    if (False && physAddr[31:24] != 0)
	       $display("req_ar: funny physAddr req.pointer=%d req.offset=%h physAddr=%h", req.pointer, req.offset, physAddr);

	    dreqFifo.enq(req);
	    return Axi3ReadRequest{address:physAddr, len:truncate(req.burstLen-1), id:req.tag,
				   size: axiBusSize(valueOf(dsz)), burst: 1, prot: 0, cache: 3, lock:0, qos:0};
	 endmethod
      endinterface
      interface Put resp_read;
	 method Action put(Axi3ReadResponse#(dsz,6) response);
	    let activeChan = chanFifo.first();
	    let req = dreqFifo.first();
	    if (valueOf(numReadClients) > 0)
	       readClients[activeChan].readData.put(DmaData { data: response.data, tag: tag_store[activeChan].first});

	    let burstLen = burstReg;
	    if (burstLen == 0)
	       burstLen = req.burstLen;

	    if (burstLen == 1) begin
	       dreqFifo.deq();
	       chanFifo.deq();
	       tag_store[activeChan].deq;
	    end
   
	    if (response.id != req.tag)
	       tag_mismatch.enq(True);

	    burstReg <= burstLen-1;
	    beatCount <= beatCount+1;
	 endmethod
      endinterface
      interface Get req_aw = ?;
      interface Get resp_write = ?;
      interface Put resp_b = ?;
   endinterface
   interface Get tagMismatch = fifoToGet(tag_mismatch);
endmodule


module mkAxiDmaWriteInternal#(Integer numRequests, 
			      Vector#(numWriteClients, DmaWriteClient#(dsz)) writeClients,
			      DmaIndication dmaIndication, 
			      Server#(Tuple2#(SGListId,Bit#(DmaOffsetSize)),Bit#(addrWidth)) sgl)

   (AxiDmaWriteInternal#(addrWidth, dsz))
   
   provisos(Add#(1,a__,dsz), Add#(b__, addrWidth, 64), Add#(c__, 12, addrWidth), Add#(1, c__, d__));
   
   FIFO#(DmaRequest)      lreqFifo <- mkSizedFIFO(1);
   FIFO#(DmaRequest)       reqFifo <- mkSizedFIFO(1);
   FIFO#(Bit#(addrWidth))   paFifo <- mkSizedFIFO(1);

   FIFO#(DmaRequest)      dreqFifo <- mkSizedFIFO(numRequests);
   FIFO#(DmaChannelId)    chanFifo <- mkSizedFIFO(numRequests);
   FIFO#(Tuple2#(DmaChannelId,Bit#(6))) respFifo <- mkSizedFIFO(numRequests);

   Reg#(Bit#(8))         burstReg <- mkReg(0);   
   Reg#(Bit#(64))       beatCount <- mkReg(0);

   // the choice of 5 is based on PCIE limitations
   Vector#(numWriteClients, Reg#(Bit#(5)))  tag_gen   <- replicateM(mkReg(0)); 
   // a depth of 32 will guarantee per/client uniqueness of outstanding requests
   Vector#(numWriteClients, FIFO#(Bit#(6))) tag_store <- replicateM(mkSizedFIFO(32)); 
   // report a tag mismatch for oo write completions (in which case we will need to introduce completion buffers)
   FIFO#(Bool) tag_mismatch <- mkSizedFIFO(32);

   for (Integer selectReg = 0; selectReg < valueOf(numWriteClients); selectReg = selectReg + 1)
       rule loadChannel;
	  DmaRequest req <- writeClients[selectReg].writeReq.get();
	  //$display("dmawrite.loadChannel activeChan=%d handle=%h addr=%h burst=%h debugReq=%d", selectReg, req.pointer, req.offset, req.burstLen, debugReg);
	  if (bad_pointer(req.pointer))
	     dmaIndication.badPointer(req.pointer);
	  else begin
	     lreqFifo.enq(req);
	     chanFifo.enq(fromInteger(selectReg));
	     sgl.request.put(tuple2(truncate(req.pointer),req.offset));
	  end
       endrule
   
   rule checkSglResp;
      let physAddr <- sgl.response.get;
      let req = lreqFifo.first();
      lreqFifo.deq();
      if (physAddr <= (1 << valueOf(SGListPageShift0))) begin
	 // squash request
	 $display("dmaWrite: badAddr handle=%d addr=%h physAddr=%h", req.pointer, req.offset, physAddr);
	 dmaIndication.badAddr(req.pointer, extend(req.offset), extend(physAddr));
	 chanFifo.deq;
      end
      else begin
	 let chan = chanFifo.first;
	 // overwrite user-supplied tag and store the original for the responses
	 reqFifo.enq(DmaRequest{pointer:req.pointer, offset:req.offset, burstLen:req.burstLen, tag:{0,tag_gen[chan]}});
	 tag_gen[chan] <= tag_gen[chan]+1;
	 tag_store[chan].enq(req.tag);
	 paFifo.enq(physAddr);
      end
   endrule

   interface DmaDbg dbg;
      method ActionValue#(DmaDbgRec) dbg();
	 return ?;
      endmethod
      method ActionValue#(Bit#(64)) getMemoryTraffic();
	 return beatCount;
      endmethod
   endinterface

   interface Axi3Master m_axi;
   interface Get req_ar = ?;
   interface Put resp_read = ?;
   interface Get req_aw;
      method ActionValue#(Axi3WriteRequest#(addrWidth,6)) get();
	 let req = reqFifo.first();
	 reqFifo.deq();
	 let physAddr = paFifo.first();
	 paFifo.deq();
	 //$display("dmaWrite addr physAddr=%h burstReg=%d", physAddr, req.burstLen);

	 dreqFifo.enq(req);
	 return Axi3WriteRequest{address:physAddr, len:truncate(req.burstLen-1), id:req.tag,
				 size: axiBusSize(valueOf(dsz)), burst: 1, prot: 0, cache: 3, lock:0, qos:0};
      endmethod
   endinterface
   interface Get resp_write;
	 method ActionValue#(Axi3WriteData#(dsz,6)) get();
	    let activeChan = chanFifo.first();
	    let req = dreqFifo.first();
	    DmaData#(dsz) tagdata = unpack(0);
	    if (valueOf(numWriteClients) > 0)
	       tagdata <- writeClients[activeChan].writeData.get();
	    let burstLen = burstReg;
	    if (burstLen == 0)
	       burstLen = req.burstLen;

	    if (burstLen == 1) begin
	       dreqFifo.deq();
	       chanFifo.deq();
	       respFifo.enq(tuple2(activeChan,req.tag));
	    end

	    //$display("dmaWrite data data=%h burstLen=%d", tagdata.data, burstLen);
	    burstReg <= burstLen-1;
	    beatCount <= beatCount+1;
	    
	    Bit#(1) last = burstLen == 1 ? 1'b1 : 1'b0;
	    dynamicAssert(tagdata.tag == tag_store[activeChan].first, "mkAxiDmaWriteInternal badness");

	    return Axi3WriteData { data: tagdata.data, byteEnable: maxBound, last: last, id: req.tag };
	 endmethod
      endinterface
      interface Put resp_b;
	 method Action put(Axi3WriteResponse#(6) resp);
	    let activeChan = tpl_1(respFifo.first);
	    let tag = tpl_2(respFifo.first);
	    if (resp.id != tag)
	       tag_mismatch.enq(True);
	    respFifo.deq();
	    tag_store[activeChan].deq;
	    if (valueOf(numWriteClients) > 0)
	       writeClients[activeChan].writeDone.put(extend(tag_store[activeChan].first));
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
module mkAxiDmaServer#(DmaIndication dmaIndication,
		       Integer numRequests,
		       Vector#(numReadClients, DmaReadClient#(dsz)) readClients,
		       Vector#(numWriteClients, DmaWriteClient#(dsz)) writeClients)

   (AxiDmaServer#(addrWidth, dsz))
   
   provisos (Add#(1,a__,dsz),
        Add#(b__, TSub#(addrWidth, 12), 32),
        Add#(c__, 12, addrWidth),
        Add#(d__, addrWidth, 64),
        Add#(e__, TSub#(addrWidth, 12), DmaOffsetSize),
        Add#(f__, c__, DmaOffsetSize),
	Add#(g__, addrWidth, 40));
   
   SGListMMU#(addrWidth) sgl <- mkSGListMMU(dmaIndication);
   FIFO#(void)   addrReqFifo <- mkFIFO;

   AxiDmaReadInternal#(addrWidth, dsz) reader <- mkAxiDmaReadInternal(numRequests, readClients, dmaIndication, sgl.addr[0]);
   AxiDmaWriteInternal#(addrWidth, dsz) writer <- mkAxiDmaWriteInternal(numRequests, writeClients, dmaIndication, sgl.addr[1]);
   
   rule tag_mismatch_read;
      let rv <- reader.tagMismatch.get;
      dmaIndication.tagMismatch(Read);
   endrule
   
   rule tag_mismatch_write;
      let rv <- writer.tagMismatch.get;
      dmaIndication.tagMismatch(Write);
   endrule

   rule sglistEntry;
      addrReqFifo.deq;
      let physAddr <- sgl.addr[0].response.get;
      dmaIndication.addrResponse(zeroExtend(physAddr));
   endrule
   
   interface DmaConfig request;
      method Action getStateDbg(ChannelType rc);
	 let rv = ?;
	 if (rc == Read)
	    rv <- reader.dbg.dbg;
	 else
	    rv <- writer.dbg.dbg;
	 dmaIndication.reportStateDbg(rv);
      endmethod
      method Action getMemoryTraffic(ChannelType rc);
	 if (rc == Read) begin
	    let rv <- reader.dbg.getMemoryTraffic;
	    dmaIndication.reportMemoryTraffic(rv);
	 end
	 else begin
	    let rv <- writer.dbg.getMemoryTraffic;
	    dmaIndication.reportMemoryTraffic(rv);
	 end
      endmethod
      method Action sglist(Bit#(32) pref, Bit#(DmaOffsetSize) addr, Bit#(32) len);
	 if (bad_pointer(pref))
	    dmaIndication.badPointer(pref);
`ifdef BSIM
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
   interface Axi3Master m_axi;
      interface Get req_ar = reader.m_axi.req_ar;
      interface Put resp_read = reader.m_axi.resp_read;

      interface Get req_aw = writer.m_axi.req_aw;
      interface Get resp_write = writer.m_axi.resp_write;
      interface Put resp_b = writer.m_axi.resp_b;
   endinterface
endmodule

