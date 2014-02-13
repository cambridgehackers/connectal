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
import FIFOF::*;
import SpecialFIFOs :: *;
import Vector::*;
import GetPut::*;
import GetPutF::*;
import ClientServer::*;

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
endinterface

interface AxiDmaReadInternal#(numeric type addrWidth, numeric type dsz);
   interface DmaDbg dbg;
   interface Axi3Master#(addrWidth,dsz,6) m_axi;
endinterface

typedef enum {Idle, Translate, Address, Data, Done} InternalState deriving(Eq,Bits);
		 
module mkAxiDmaReadInternal#(Integer numRequests, 
			     Vector#(numReadClients, DmaReadClient#(dsz)) readClients, 
			     DmaIndication dmaIndication,
			     Server#(Tuple2#(SGListId,Bit#(DmaOffsetSize)),Bit#(addrWidth)) sgl) 
   (AxiDmaReadInternal#(addrWidth, dsz))

   provisos(Add#(1,a__,dsz), Add#(b__, addrWidth, 64), Add#(c__, 12, addrWidth), Add#(1, c__, d__));
   
   FIFO#(DmaRequest)    lreqFifo <- mkPipelineFIFO();
   FIFO#(DmaRequest)     reqFifo <- mkPipelineFIFO();
   FIFO#(Bit#(addrWidth)) paFifo <- mkPipelineFIFO();

   FIFO#(DmaChannelId)  chanFifo <- mkSizedFIFO(numRequests);
   FIFO#(DmaRequest)    dreqFifo <- mkSizedFIFO(numRequests);

   Reg#(DmaChannelId)  selectReg <- mkReg(0);
   Reg#(Bit#(8))        burstReg <- mkReg(0);   
   
   Reg#(Bit#(64)) beatCount <- mkReg(0);

   (* descending_urgency = "loadChannel,incSelectReg" *)
   rule incSelectReg;
      let s = selectReg+1;
      if (s == fromInteger(valueOf(numReadClients)))
	 s = 0;
      selectReg <= s;
   endrule
   
   rule loadChannel if (valueOf(numReadClients) > 0  && readClients[selectReg].readData.notFull());
      DmaRequest req = unpack(0);
      if (valueOf(numReadClients) > 0)
	 req <- readClients[selectReg].readReq.get();
      //$display("dmaread.loadChannel activeChan=%d handle=%h addr=%h burst=%h", selectReg, req.pointer, req.offset, req.burstLen);

      if (req.pointer > fromInteger(valueOf(MaxNumSGLists)))
	 dmaIndication.badPointer(req.pointer);
      else begin
	 lreqFifo.enq(req);
	 chanFifo.enq(selectReg);
	 sgl.request.put(tuple2(truncate(req.pointer),req.offset));
      end
   endrule
   
   rule checkSglResp;
      let physAddr <- sgl.response.get;
      let req = lreqFifo.first();
      lreqFifo.deq();
      if (physAddr <= (1 << valueOf(SGListPageShift0))) begin
	 // squash request
	 $display("dmaRead: badAddr handle=%d addr=%h physAddr=%h", req.pointer, req.offset, physAddr);
	 dmaIndication.badAddr(req.pointer, extend(req.offset), extend(physAddr));
      end
      else begin
	 reqFifo.enq(req);
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

	    dreqFifo.enq(req);
	    return Axi3ReadRequest{address:physAddr, len:truncate(req.burstLen-1), id:req.tag,
				   size: axiBusSize(valueOf(dsz)), burst: 1, prot: 0, cache: 3, lock:0, qos:0};
	 endmethod
      endinterface
      interface Put resp_read;
	 method Action put(Axi3ReadResponse#(dsz,6) response);
	    let activeChan = chanFifo.first();
	    let resp = dreqFifo.first();
	    if (valueOf(numReadClients) > 0)
	       readClients[activeChan].readData.put(DmaData { data: response.data, tag: resp.tag});

	    let burstLen = burstReg;
	    if (burstLen == 0)
	       burstLen = resp.burstLen;

	    if (burstLen == 1) begin
	       dreqFifo.deq();
	       chanFifo.deq();
	    end

	    burstReg <= burstLen-1;
	    beatCount <= beatCount+1;
	 endmethod
      endinterface
      interface Get req_aw = ?;
      interface Get resp_write = ?;
      interface Put resp_b = ?;
   endinterface
endmodule


module mkAxiDmaWriteInternal#(Integer numRequests, 
			      Vector#(numWriteClients, DmaWriteClient#(dsz)) writeClients,
			      DmaIndication dmaIndication, 
			      Server#(Tuple2#(SGListId,Bit#(DmaOffsetSize)),Bit#(addrWidth)) sgl)

   (AxiDmaWriteInternal#(addrWidth, dsz))
   
   provisos(Add#(1,a__,dsz), Add#(b__, addrWidth, 64), Add#(c__, 12, addrWidth), Add#(1, c__, d__));
   
   FIFO#(DmaRequest) lreqFifo <- mkPipelineFIFO();
   FIFO#(DmaRequest) reqFifo <- mkFIFO();
   FIFO#(DmaRequest) dreqFifo <- mkSizedFIFO(numRequests);
   FIFO#(Bit#(addrWidth))        paFifo     <- mkFIFO();
   FIFO#(DmaChannelId)    chanFifo <- mkSizedFIFO(numRequests);
   FIFO#(DmaChannelId)    respFifo <- mkSizedFIFO(numRequests);

   Reg#(DmaChannelId)    selectReg <- mkReg(0);
   Reg#(Bit#(8))         burstReg <- mkReg(0);   

   Reg#(Bit#(64)) beatCount <- mkReg(0);

  (* descending_urgency = "loadChannel,incSelectReg" *)
   rule incSelectReg;
      let s = selectReg+1;
      if (s == fromInteger(valueOf(numWriteClients)))
	 s = 0;
      selectReg <= s;
   endrule
   
   rule loadChannel if (valueOf(numWriteClients) > 0 && writeClients[selectReg].writeData.notEmpty());
      DmaRequest req = unpack(0);
      if (valueOf(numWriteClients) > 0)
	 req <- writeClients[selectReg].writeReq.get();
      //$display("dmawrite.loadChannel activeChan=%d handle=%h addr=%h burst=%h debugReq=%d", selectReg, req.pointer, req.offset, req.burstLen, debugReg);

      lreqFifo.enq(req);
      chanFifo.enq(selectReg);
      sgl.request.put(tuple2(truncate(req.pointer),req.offset));
   endrule
   
   rule checkSglResp;
      let physAddr <- sgl.response.get;
      let req = lreqFifo.first();
      lreqFifo.deq();
      if (physAddr <= (1 << valueOf(SGListPageShift0))) begin
	 // squash request
	 $display("dmaWrite: badAddr handle=%d addr=%h physAddr=%h", req.pointer, req.offset, physAddr);
	 dmaIndication.badAddr(req.pointer, extend(req.offset), extend(physAddr));
      end
      else begin
	 reqFifo.enq(req);
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
	    let resp = dreqFifo.first();
	    DmaData#(dsz) tagdata = unpack(0);
	    if (valueOf(numWriteClients) > 0)
	       tagdata <- writeClients[activeChan].writeData.get();
	    let burstLen = burstReg;
	    if (burstLen == 0)
	       burstLen = resp.burstLen;

	    if (burstLen == 1) begin
	       dreqFifo.deq();
	       chanFifo.deq();
	       respFifo.enq(activeChan);
	    end

	    //$display("dmaWrite data data=%h burstLen=%d", tagdata.data, burstLen);

	    burstReg <= burstLen-1;
	    beatCount <= beatCount+1;
	    
	    Bit#(1) last = burstLen == 1 ? 1'b1 : 1'b0;

	    return Axi3WriteData { data: tagdata.data, byteEnable: maxBound, last: last, id: tagdata.tag };
	 endmethod
      endinterface
      interface Put resp_b;
	 method Action put(Axi3WriteResponse#(6) resp);
	    let activeChan = respFifo.first();
	    respFifo.deq();
	    if (valueOf(numWriteClients) > 0)
	       writeClients[activeChan].writeDone.put(extend(resp.id));
	 endmethod
      endinterface
   endinterface
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
   
   SGListMMU#(addrWidth) sgl <- mkSGListMMU();
   FIFO#(void)   addrReqFifo <- mkFIFO;

   AxiDmaReadInternal#(addrWidth, dsz) reader <- mkAxiDmaReadInternal(numRequests, readClients, dmaIndication, sgl.addr[0]);
   AxiDmaWriteInternal#(addrWidth, dsz) writer <- mkAxiDmaWriteInternal(numRequests, writeClients, dmaIndication, sgl.addr[1]);
   
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
	 dmaIndication.configResp(pref);
	 if (pref == 0 || pref > fromInteger(valueOf(MaxNumSGLists))) begin
	    dmaIndication.badPointer(pref);
	 end
`ifdef BSIM
	 let va <- pareff(pref, len);
         addr[39:32] = truncate(pref);
`endif
	 if (addr == 0 && len > 0) begin
	    dmaIndication.badAddr(pref, addr, zeroExtend(len));
	 end
	 sgl.sglist(pref, addr, len);
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

