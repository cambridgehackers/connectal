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
import PortalMemory::*;
import PortalRMemory::*;
import StmtFSM::*;

// In the future, NumDmaChannels will be defined somehwere in the xbsv compiler output
typedef 16 NumSGLists;
typedef Bit#(TLog#(NumSGLists)) SGListId;
typedef 12 SGListPageShift;
typedef TSub#(DmaAddrSize,SGListPageShift) PageIdxSize;
typedef Bit#(PageIdxSize) PageIdx;
// these numbers have only been tested on the Zynq platform

interface SGListMMU#(numeric type addrWidth);
   method Action page(SGListId id, Bit#(PageIdxSize) vPageNum, Bit#(TSub#(addrWidth,SGListPageShift)) pPageNum);
   method Action addrReq(SGListId id, Bit#(DmaAddrSize) off);
   method ActionValue#(Bit#(addrWidth)) addrResp();
   method Action dbgAddrReq(SGListId id, Bit#(DmaAddrSize) off);
   method ActionValue#(Tuple2#(Bit#(PageIdxSize), Bit#(addrWidth))) dbgAddrResp();
endinterface

// if this structure becomes too expensive, we can switch to a multi-level structure
module mkSGListMMU(SGListMMU#(addrWidth))
   provisos (Log#(NumSGLists, listIdxSize),
	     Add#(listIdxSize,PageIdxSize,entryIdxSize),
	     Add#(pPageNumSize, SGListPageShift, addrWidth),
	     Bits#(Maybe#(Bit#(pPageNumSize)), mpPageNumSize),
	     Add#(1, pPageNumSize, mpPageNumSize)
	     );

   BRAM_Configure cfg = defaultValue;
   BRAM1Port#(Bit#(entryIdxSize), Maybe#(Bit#(pPageNumSize))) pageTable <- mkBRAM1Server(cfg);
   FIFOF#(Bit#(SGListPageShift)) offs <- mkFIFOF;
   FIFOF#(Bit#(addrWidth)) respFifo <- mkFIFOF;
   FIFOF#(Bit#(PageIdxSize)) pageIdxs <- mkFIFOF;

   let page_shift = fromInteger(valueOf(SGListPageShift));

   (* aggressive_implicit_conditions *)
   rule respond;
      offs.deq;
      let mrv <- pageTable.portA.response.get;
      let rv = fromMaybe(fromInteger('hababa),mrv);
      if (!isValid(mrv))
      	 $display("mkSGListMMU::addrResp has gone off the reservation");
      respFifo.enq({rv,offs.first});
   endrule
   method Action page(SGListId id, Bit#(PageIdxSize) pageNum, Bit#(pPageNumSize) pPageNum);
      $display("page id=%d pageNum=%h physaddr=%h", id, pageNum, pPageNum);
      pageTable.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:{id,pageNum}, datain:tagged Valid pPageNum});
   endmethod

   method Action addrReq(SGListId id, Bit#(DmaAddrSize) off);
      offs.enq(truncate(off));
      Bit#(PageIdxSize) pageNum = off[valueOf(DmaAddrSize)-1:page_shift];
      //$display("addrReq id=%d pageNum=%h", id, pageNum);
      pageTable.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:{id,pageNum}, datain:?});
   endmethod
   
   method ActionValue#(Bit#(addrWidth)) addrResp() if (!pageIdxs.notEmpty());
      respFifo.deq();
      //$display("addrResp phys_addr=%h", respFifo.first());
      return respFifo.first();
   endmethod

   method Action dbgAddrReq(SGListId id, Bit#(DmaAddrSize) off);
      offs.enq(truncate(off));
      let pageIdx = off[valueOf(DmaAddrSize)-1:page_shift];
      pageIdxs.enq(pageIdx);
      pageTable.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:{id,pageIdx}, datain:?});
   endmethod
   
   method ActionValue#(Tuple2#(Bit#(PageIdxSize), Bit#(addrWidth))) dbgAddrResp();
      respFifo.deq();
      let pageIdx = pageIdxs.first();
      pageIdxs.deq();
      return tuple2(pageIdx, respFifo.first());
   endmethod
   
endmodule
