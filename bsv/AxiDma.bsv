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
   interface Get#(Tuple2#(Bit#(6),Bit#(6))) tagMismatch;
endinterface

interface AxiDmaReadInternal#(numeric type addrWidth, numeric type dsz);
   interface DmaDbg dbg;
   interface Axi3Master#(addrWidth,dsz,6) m_axi;
   interface Get#(Tuple2#(Bit#(6),Bit#(6))) tagMismatch;
endinterface

function Bool bad_pointer(DmaPointer p);
   return (p > fromInteger(valueOf(MaxNumSGLists)) || p == 0);
endfunction

typedef enum {Idle, Translate, Address, Data, Done} InternalState deriving(Eq,Bits);

typedef struct {DmaRequest req;
		Bit#(6)    id;
		Bit#(addrWidth) pa;
		DmaChannelId chan; } IRec#(type addrWidth) deriving(Bits);
		 
module mkAxiDmaReadInternal#(Vector#(numReadClients, DmaReadClient#(dsz)) readClients, 
			     DmaIndication dmaIndication,
			     Server#(Tuple2#(SGListId,Bit#(DmaOffsetSize)),Bit#(addrWidth)) sgl) 
   (AxiDmaReadInternal#(addrWidth, dsz))

   provisos(Add#(1,a__,dsz), 
	    Add#(b__, addrWidth, 64), 
	    Add#(c__, 12, addrWidth), 
	    Add#(1, c__, d__));
   
   FIFO#(IRec#(addrWidth)) lreqFifo <- mkSizedFIFO(1);
   FIFO#(IRec#(addrWidth))  reqFifo <- mkSizedFIFO(1);
   FIFO#(IRec#(addrWidth)) dreqFifo <- mkSizedFIFO(32);

   Reg#(Bit#(8))           burstReg <- mkReg(0);
   Vector#(numReadClients, Reg#(Bit#(64))) beatCounts <- replicateM(mkReg(0));
   
   // the choice of 5 is based on PCIE limitations.   
   // uniqueness is enforced by the depth of dreqFIFO
   Reg#(Bit#(5))  id_gen   <- mkReg(0); 
   // report a tag mismatch for oo completions (in which 
   // case we will need to introduce completion buffers)
   FIFO#(Tuple2#(Bit#(6),Bit#(6))) tag_mismatch <- mkSizedFIFO(32);
   
   for (Integer selectReg = 0; selectReg < valueOf(numReadClients); selectReg = selectReg + 1)
       rule loadChannel;
	  DmaRequest req <- readClients[selectReg].readReq.get();
	  //$display("dmaread.loadChannel activeChan=%d handle=%h addr=%h burst=%h", selectReg, req.pointer, req.offset, req.burstLen);
	  if (bad_pointer(req.pointer))
	     dmaIndication.badPointer(req.pointer);
	  else begin
	     lreqFifo.enq(IRec{req:req, id:?, pa:?, chan:fromInteger(selectReg)});
	     sgl.request.put(tuple2(truncate(req.pointer),req.offset));
	  end
       endrule
   
   rule checkSglResp;
      let physAddr <- sgl.response.get;
      let req = lreqFifo.first.req;
      let chan = lreqFifo.first.chan;
      lreqFifo.deq();
      if (physAddr <= (1 << valueOf(SGListPageShift0))) begin
	 // squash request
	 $display("dmaRead: badAddr pointer=%d offset=%h physAddr=%h", req.pointer, req.offset, physAddr);
	 dmaIndication.badAddr(req.pointer, extend(req.offset), extend(physAddr));
      end
      else begin
	 if (False && physAddr[31:24] != 0)
	    $display("checkSglResp: funny physAddr req.pointer=%d req.offset=%h physAddr=%h", req.pointer, req.offset, physAddr);
	 //$display("mkAxiDmaReadInternal::checkSglResp tag=%d, id=%d, activeChan=%d", req.tag, id_gen, chan);
	 reqFifo.enq(IRec{req:req, id:{0,id_gen}, pa:physAddr, chan:chan});
	 id_gen <= id_gen+1;
      end
   endrule

   interface DmaDbg dbg;
      method ActionValue#(DmaDbgRec) dbg();
	 return DmaDbgRec{x:fromInteger(valueOf(numReadClients)), y:?, z:?, w:?};
      endmethod
      method ActionValue#(Bit#(64)) getMemoryTraffic(Bit#(32) client);
	 return (valueOf(numReadClients) > 0 && client < fromInteger(valueOf(numReadClients))) ? beatCounts[client] : 0;
      endmethod
   endinterface

   interface Axi3Master m_axi;
      interface Get req_ar;
	 method ActionValue#(Axi3ReadRequest#(addrWidth,6)) get();
	    let req = reqFifo.first.req;
	    let physAddr = reqFifo.first.pa;
	    let id = reqFifo.first.id;
	    reqFifo.deq;
	    //$display("mkAxiDmaReadInternal::req_ar tag=%d id=%d len=%d activeChan=%d", req.tag, id, req.burstLen, reqFifo.first.chan);
	    if (False && physAddr[31:24] != 0)
	       $display("req_ar: funny physAddr req.pointer=%d req.offset=%h physAddr=%h", req.pointer, req.offset, physAddr);

	    dreqFifo.enq(reqFifo.first);
	    return Axi3ReadRequest{address:physAddr, len:truncate(req.burstLen-1), id:id,
				   size: axiBusSize(valueOf(dsz)), burst: 1, prot: 0, cache: 3, lock:0, qos:0};
	 endmethod
      endinterface
      interface Put resp_read;
	 method Action put(Axi3ReadResponse#(dsz,6) response);
	    let activeChan = dreqFifo.first.chan;
	    let req = dreqFifo.first.req;
	    let id = dreqFifo.first.id;
	    if (valueOf(numReadClients) > 0)
	      readClients[activeChan].readData.put(DmaData { data: response.data, tag: req.tag});

	    let burstLen = burstReg;
	    if (burstLen == 0)
	       burstLen = req.burstLen;

	    if (burstLen == 1  && valueOf(numReadClients) > 0) begin
	       dreqFifo.deq();
	    end
   
	    if (response.id != id) begin
	       tag_mismatch.enq(tuple2(response.id,id));
	       $display("mkAxiDmaReadInternal::tag_mismatch %d %d", response.id, id);
	    end
	    //$display("mkAxiDmaReadInternal::resp_read id=%d burstLen=%d activeChan=%d", id, burstLen, activeChan);
	    burstReg <= burstLen-1;
	    if(valueOf(numReadClients) > 0)
	       beatCounts[activeChan] <= beatCounts[activeChan]+1;
	 endmethod
      endinterface
      interface Get req_aw = ?;
      interface Get resp_write = ?;
      interface Put resp_b = ?;
   endinterface
   interface Get tagMismatch = fifoToGet(tag_mismatch);
endmodule


module mkAxiDmaWriteInternal#(Vector#(numWriteClients, DmaWriteClient#(dsz)) writeClients,
			      DmaIndication dmaIndication, 
			      Server#(Tuple2#(SGListId,Bit#(DmaOffsetSize)),Bit#(addrWidth)) sgl)

   (AxiDmaWriteInternal#(addrWidth, dsz))
   
   provisos(Add#(1,a__,dsz), 
	    Add#(b__, addrWidth, 64), 
	    Add#(c__, 12, addrWidth), 
	    Add#(1, c__, d__));
   
   FIFO#(IRec#(addrWidth)) lreqFifo <- mkSizedFIFO(1);
   FIFO#(IRec#(addrWidth))  reqFifo <- mkSizedFIFO(1);
   FIFO#(IRec#(addrWidth)) dreqFifo <- mkSizedFIFO(32);
   FIFO#(IRec#(addrWidth)) respFifo <- mkSizedFIFO(32);

   Reg#(Bit#(8))         burstReg <- mkReg(0);   
   Vector#(numWriteClients, Reg#(Bit#(64))) beatCounts <- replicateM(mkReg(0));

   // the choice of 5 is based on PCIE limitations.   
   // uniqueness is enforced by the depth of dreqFIFO
   Reg#(Bit#(5))  id_gen   <- mkReg(0); 
   // report a tag mismatch for oo completions (in which 
   // case we will need to introduce completion buffers)
   FIFO#(Tuple2#(Bit#(6),Bit#(6))) tag_mismatch <- mkSizedFIFO(32);

   for (Integer selectReg = 0; selectReg < valueOf(numWriteClients); selectReg = selectReg + 1)
       rule loadChannel;
	  DmaRequest req <- writeClients[selectReg].writeReq.get();
	  //$display("dmawrite.loadChannel activeChan=%d handle=%h addr=%h burst=%h debugReq=%d", selectReg, req.pointer, req.offset, req.burstLen, debugReg);
	  if (bad_pointer(req.pointer))
	     dmaIndication.badPointer(req.pointer);
	  else begin
	     lreqFifo.enq(IRec{req:req, id:?, pa:?, chan:fromInteger(selectReg)});
	     sgl.request.put(tuple2(truncate(req.pointer),req.offset));
	  end
       endrule
   
   rule checkSglResp;
      let physAddr <- sgl.response.get;
      let req = lreqFifo.first.req;
      let chan = lreqFifo.first.chan;
      lreqFifo.deq();
      if (physAddr <= (1 << valueOf(SGListPageShift0))) begin
	 // squash request
	 $display("dmaWrite: badAddr handle=%d addr=%h physAddr=%h", req.pointer, req.offset, physAddr);
	 dmaIndication.badAddr(req.pointer, extend(req.offset), extend(physAddr));
      end
      else begin
	 reqFifo.enq(IRec{req:req, id:{0,id_gen}, pa:physAddr, chan:chan});
	 id_gen <= id_gen+1;
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

   interface Axi3Master m_axi;
   interface Get req_ar = ?;
   interface Put resp_read = ?;
   interface Get req_aw;
      method ActionValue#(Axi3WriteRequest#(addrWidth,6)) get();
	 let req = reqFifo.first.req;
	 let physAddr = reqFifo.first.pa;
	 let id = reqFifo.first.id;
	 reqFifo.deq;
	 //$display("dmaWrite addr physAddr=%h burstReg=%d", physAddr, req.burstLen);

	 dreqFifo.enq(reqFifo.first);
	 return Axi3WriteRequest{address:physAddr, len:truncate(req.burstLen-1), id:id,
				 size: axiBusSize(valueOf(dsz)), burst: 1, prot: 0, cache: 3, lock:0, qos:0};
      endmethod
   endinterface
   interface Get resp_write;
	 method ActionValue#(Axi3WriteData#(dsz,6)) get();
	    let activeChan = dreqFifo.first.chan;
	    let req = dreqFifo.first.req;
	    let id = dreqFifo.first.id;
	    DmaData#(dsz) tagdata = unpack(0);
	    if (valueOf(numWriteClients) > 0)
	       tagdata <- writeClients[activeChan].writeData.get();
	    let burstLen = burstReg;
	    if (burstLen == 0)
	       burstLen = req.burstLen;

	    if (burstLen == 1) begin
	       dreqFifo.deq();
	       respFifo.enq(dreqFifo.first);
	    end

	    //$display("dmaWrite data data=%h burstLen=%d", tagdata.data, burstLen);
	    burstReg <= burstLen-1;
	    if(valueOf(numWriteClients) > 0)
	       beatCounts[activeChan] <= beatCounts[activeChan]+1;
	    
	    Bit#(1) last = burstLen == 1 ? 1'b1 : 1'b0;
	    return Axi3WriteData { data: tagdata.data, byteEnable: maxBound, last: last, id: id };
	 endmethod
      endinterface
      interface Put resp_b;
	 method Action put(Axi3WriteResponse#(6) resp);
	    let activeChan = respFifo.first.chan;
	    let id = respFifo.first.id;
	    let tag = respFifo.first.req.tag;
	    if (resp.id != id)
	       tag_mismatch.enq(tuple2(resp.id,id));
	    respFifo.deq();
	    if (valueOf(numWriteClients) > 0) begin
	       writeClients[activeChan].writeDone.put(tag);
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
module mkAxiDmaServer#(DmaIndication dmaIndication,
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

   AxiDmaReadInternal#(addrWidth, dsz) reader <- mkAxiDmaReadInternal(readClients, dmaIndication, sgl.addr[0]);
   AxiDmaWriteInternal#(addrWidth, dsz) writer <- mkAxiDmaWriteInternal(writeClients, dmaIndication, sgl.addr[1]);
   
   rule tag_mismatch_read;
      let rv <- reader.tagMismatch.get;
      dmaIndication.tagMismatch(Read, extend(tpl_1(rv)), extend(tpl_2(rv)));
   endrule
   
   rule tag_mismatch_write;
      let rv <- writer.tagMismatch.get;
      dmaIndication.tagMismatch(Write, extend(tpl_1(rv)), extend(tpl_2(rv)));
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
      method Action getMemoryTraffic(ChannelType rc, Bit#(32) client);
	 if (rc == Read) begin
	    let rv <- reader.dbg.getMemoryTraffic(client);
	    dmaIndication.reportMemoryTraffic(rv);
	 end
	 else begin
	    let rv <- writer.dbg.getMemoryTraffic(client);
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

