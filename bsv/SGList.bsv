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
import RegFile::*;
import FIFOF::*;
import Vector::*;
import GetPut::*;
import BRAMFIFO::*;
import BRAM::*;
import Dma::*;
import StmtFSM::*;
import ClientServer::*;

// In the future, NumDmaChannels will be defined somehwere in the xbsv compiler output
typedef 16 NumSGLists;
typedef Bit#(TLog#(NumSGLists)) SGListId;
typedef 12 SGListPageShift;
typedef TSub#(DmaAddrSize,SGListPageShift) PageIdxSize;
typedef Bit#(PageIdxSize) PageIdx;
// these numbers have only been tested on the Zynq platform

interface SGListMMU#(numeric type addrWidth);
   method Action page(SGListId id, Bit#(PageIdxSize) vPageNum, Bit#(TSub#(addrWidth,SGListPageShift)) pPageNum);
   method Action configuring(Bool c);
   interface Vector#(2,Server#(Tuple2#(SGListId,Bit#(DmaAddrSize)),Bit#(addrWidth))) addr;
   interface Server#(Tuple2#(SGListId,Bit#(DmaAddrSize)), Tuple2#(Bit#(PageIdxSize), Bit#(addrWidth))) addrDbg;
endinterface

// if this structure becomes too expensive, we can switch to a multi-level structure
module mkSGListMMU(SGListMMU#(addrWidth))
   provisos (Log#(NumSGLists, listIdxSize),
	     Add#(listIdxSize,PageIdxSize,entryIdxSize),
	     Add#(pPageNumSize, SGListPageShift, addrWidth),
	     Bits#(Maybe#(Bit#(pPageNumSize)), mpPageNumSize),
	     Add#(1, pPageNumSize, mpPageNumSize));

   BRAM_Configure cfg = defaultValue;
   BRAM2Port#(Bit#(entryIdxSize), Maybe#(Bit#(pPageNumSize))) pageTable <- mkBRAM2Server(cfg);
   Vector#(2,FIFOF#(Bit#(SGListPageShift))) offs <- replicateM(mkFIFOF);
   Vector#(2,FIFOF#(Bit#(addrWidth))) respFifos <- replicateM(mkFIFOF);
   FIFOF#(Bit#(PageIdxSize)) pageIdx <- mkFIFOF;
   Reg#(Bool)  isConfiguring <- mkReg(False);
   
   let page_shift = fromInteger(valueOf(SGListPageShift));
   function BRAMServer#(Bit#(entryIdxSize), Maybe#(Bit#(pPageNumSize))) portsel(int i);
      if(i==0)
	 return pageTable.portA;
      else
	 return pageTable.portB;
   endfunction

   Vector#(2,Server#(Tuple2#(SGListId,Bit#(DmaAddrSize)),Bit#(addrWidth))) addrServers;
   for(int i = 0; i < 2; i=i+1)
      addrServers[i] = 
      (interface Server#(Tuple2#(SGListId,Bit#(DmaAddrSize)),Bit#(addrWidth));
	  interface Put request;
	     method Action put(Tuple2#(SGListId,Bit#(DmaAddrSize)) req) if (!isConfiguring);
		let id = tpl_1(req);
		let off = tpl_2(req);
		offs[i].enq(truncate(off));
		Bit#(PageIdxSize) pageNum = off[valueOf(DmaAddrSize)-1:page_shift];
		//$display("addrReq id=%d pageNum=%h", id, pageNum);
		portsel(i).request.put(BRAMRequest{write:False, responseOnWrite:False, address:{id,pageNum}, datain:?});
	     endmethod
	  endinterface
	  interface Get response;
	     method ActionValue#(Bit#(addrWidth)) get if (!isConfiguring);
		respFifos[i].deq();
		//$display("addrResp phys_addr=%h", respFifo.first());
		return respFifos[i].first();
	     endmethod
	  endinterface
       endinterface);
   
   for(int i = 0; i < 2; i=i+1) begin
      (* aggressive_implicit_conditions *)
      rule respond;
	 offs[i].deq;
	 let mrv <- portsel(i).response.get;
	 let rv = fromMaybe(fromInteger('hababa),mrv);
	 if (!isValid(mrv))
      	    $display("mkSGListMMU::addrResp (%d) has gone off the reservation", i);
	 respFifos[i].enq({rv,offs[i].first});
      endrule
   end
   
   method Action configuring(Bool c);
      isConfiguring <= c;
   endmethod
   
   method Action page(SGListId id, Bit#(PageIdxSize) pageNum, Bit#(pPageNumSize) pPageNum);
      $display("page id=%d pageNum=%h physaddr=%h", id, pageNum, pPageNum);
      pageTable.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:{id,pageNum}, datain:tagged Valid pPageNum});
   endmethod
   
   interface Server addrDbg;
      interface Put request;
      	 method Action put(Tuple2#(SGListId,Bit#(DmaAddrSize)) req) if (!isConfiguring);
	    let id = tpl_1(req);
	    let off = tpl_2(req);
      	    offs[1].enq(truncate(off));
      	    let pIdx = off[valueOf(DmaAddrSize)-1:page_shift];
      	    pageIdx.enq(pIdx);
      	    pageTable.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:{id,pIdx}, datain:?});
      	 endmethod
      endinterface
      interface Get response;
      	 method ActionValue#(Tuple2#(Bit#(PageIdxSize), Bit#(addrWidth))) get if (!isConfiguring);
      	    respFifos[1].deq();
      	    let pIdx = pageIdx.first();
      	    pageIdx.deq();
      	    return tuple2(pIdx, respFifos[1].first());
      	 endmethod
      endinterface
   endinterface
   
   interface addr = addrServers;

endmodule
