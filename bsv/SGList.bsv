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
typedef 32 SGListMaxLen;
typedef Bit#(TLog#(TMul#(NumSGLists, SGListMaxLen))) SGListIdx;

typedef struct {
   Bit#(addrWidth) address;
   Bit#(32) length;
   } SGListEntry#(numeric type addrWidth) deriving (Bits);

typedef struct {
   SGListIdx entry;
   Bit#(32) offset;
   } SGListPointer deriving (Bits);

//
// @brief SGListStreamer manages virtual to physical translations via scatter-gather lists
// 
interface SGListStreamer#(numeric type addrWidth);
   // @brief Add a scatter-gather list entry for a memory object
   // @param segoff Offset into the object described by this segment
   // @param addr Physical address of this segment of the object
   // @param len  Length of this segment of the object
   method Action sglist(Bit#(32) segoff, Bit#(addrWidth) physaddr, Bit#(32) len);
   method Action loadCtx(SGListId id);
   method ActionValue#(Bit#(addrWidth)) nextAddr(Bit#(4) burstLen);
   method Action dropCtx();
endinterface

module mkSGListStreamer(SGListStreamer#(addrWidth)) provisos(Add#(a__, 32, addrWidth), Add#(b__, addrWidth, 64));

   function m#(Reg#(SGListPointer)) foo(Integer x)
      provisos (IsModule#(m,__a));
      let p = SGListPointer{entry:fromInteger(x*valueOf(SGListMaxLen)),offset:0};
      return mkReg(p);
   endfunction

   function m#(Reg#(SGListIdx)) bar(Integer x)
      provisos (IsModule#(m,__a));
      let p = fromInteger(x*valueOf(SGListMaxLen));
      return mkReg(p);
   endfunction
   
   BRAM1Port#(SGListIdx, Maybe#(SGListEntry#(addrWidth))) listMem <- mkBRAM1Server(defaultValue);
   Vector#(NumSGLists, Reg#(SGListPointer))  listPtrs <- genWithM(foo);
   Vector#(NumSGLists, Reg#(SGListIdx))      listEnds <- genWithM(bar);
   FIFOF#(SGListId)                          loadReqs <- mkFIFOF;
   Reg#(SGListIdx)                            initPtr <- mkReg(0);

   method Action sglist(Bit#(32) pref, Bit#(addrWidth) addr, Bit#(32) len);
      let off = listEnds[pref-1];
      listEnds[pref-1] <= off+1;
      let entry = tagged Valid SGListEntry{address:addr, length:len};
      listMem.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(off), datain:entry});
   endmethod
   
   method Action loadCtx(SGListId id);
      listMem.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:listPtrs[id-1].entry, datain:?});
      loadReqs.enq(id);
   endmethod
   
   method ActionValue#(Bit#(addrWidth)) nextAddr(Bit#(4) burstLen);
      loadReqs.deq;
      let mrv <- listMem.portA.response.get;
      let id = loadReqs.first;
      let lp = listPtrs[id-1];
      let new_offset = ((zeroExtend(burstLen)+1) << 3) + lp.offset;
      let rv = fromMaybe(?, mrv);
      if (!isValid(mrv))
	 $display("mkSGListStreamer::nextAddr has gone off the reservation");
      if(new_offset < rv.length)
	 listPtrs[id-1] <= SGListPointer{entry:lp.entry, offset:new_offset};
      else if (new_offset == rv.length)
	 listPtrs[id-1] <= SGListPointer{entry:lp.entry+1, offset:0};
      else if(new_offset > rv.length)
	 $display("burst crosses SG list boundry");
      else if(rv.length == 0)
	 $display("going off the end of SG list");
      return rv.address + extend(lp.offset);
   endmethod
   
   method Action dropCtx();
      let rv <- listMem.portA.response.get;
      loadReqs.deq;
   endmethod
endmodule



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
