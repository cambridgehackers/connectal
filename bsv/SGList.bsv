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
import ClientServer::*;
import BRAMFIFO::*;
import BRAM::*;
import PortalMemory::*;
import StmtFSM::*;

// In the future, NumDmaChannels will be defined somehwere in the xbsv compiler output
typedef 4 NumSGLists;
typedef Bit#(TLog#(NumSGLists)) SGListId;
typedef 32 SGListMaxLen;
typedef Bit#(TLog#(TMul#(NumSGLists, SGListMaxLen))) SGListIdx;

typedef struct {
   Bit#(40) address;
   Bit#(32) length;
   } SGListEntry deriving (Bits);

typedef struct {
   SGListIdx entry;
   Bit#(32) offset;
   } SGListPointer deriving (Bits);

//
// @brief SGListStreamer manages virtual to physical translations via scatter-gather lists
// 
interface SGListStreamer;
   // @brief Add a scatter-gather list entry for a memory object
   // @param segoff Offset into the object described by this segment
   // @param addr Physical address of this segment of the object
   // @param len  Length of this segment of the object
   method Action sglist(Bit#(32) segoff, Bit#(40) physaddr, Bit#(32) len);
   method Action loadCtx(SGListId id);
   method ActionValue#(Bit#(40)) nextAddr(Bit#(4) burstLen);
   method Action dropCtx();
endinterface

module mkSGListStreamer(SGListStreamer);

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
   
   BRAM1Port#(SGListIdx, Maybe#(SGListEntry)) listMem <- mkBRAM1Server(defaultValue);
   Vector#(NumSGLists, Reg#(SGListPointer))  listPtrs <- genWithM(foo);
   Vector#(NumSGLists, Reg#(SGListIdx))      listEnds <- genWithM(bar);
   FIFOF#(SGListId)                          loadReqs <- mkFIFOF;
   Reg#(SGListIdx)                            initPtr <- mkReg(0);

   method Action sglist(Bit#(32) pref, Bit#(40) addr, Bit#(32) len);
      let off = listEnds[pref-1];
      listEnds[pref-1] <= off+1;
      let entry = tagged Valid SGListEntry{address:addr, length:len};
      listMem.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(off), datain:entry});
   endmethod
   
   method Action loadCtx(SGListId id);
      listMem.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:listPtrs[id-1].entry, datain:?});
      loadReqs.enq(id);
   endmethod
   
   method ActionValue#(Bit#(40)) nextAddr(Bit#(4) burstLen);
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

interface SGListMMU;
   method Action page(SGListId id, Bit#(32) off, Bit#(40) addr);
   method Action addrReq(SGListId id, Bit#(40) off);
   method ActionValue#(Bit#(40)) addrResp();
endinterface

// is 1 K pages enough (probably not) 
typedef 1024 SGListMaxPages;
typedef Bit#(TLog#(SGListMaxPages)) PageIdx;
// these numbers have only been tested on the Zynq platform
typedef 12 SGListPageShift;

// if this structure becomes too expensive, we can switch to a multi-level structure
module mkSGListMMU(SGListMMU);

   BRAM_Configure cfg = defaultValue;
   cfg.latency = 2;
   Vector#(NumSGLists, BRAM1Port#(PageIdx, Maybe#(Bit#(TSub#(40,SGListPageShift))))) pageTables <- replicateM(mkBRAM1Server(cfg));
   FIFOF#(Bit#(SGListPageShift)) offs <- mkFIFOF;
   FIFOF#(SGListId) ids  <- mkFIFOF;
   FIFOF#(Bit#(40)) respFifo <- mkFIFOF;
   
   let page_shift = fromInteger(valueOf(SGListPageShift));

   (* aggressive_implicit_conditions *)
   rule respond;
      ids.deq;
      offs.deq;
      let mrv <- pageTables[ids.first].portA.response.get;
      let rv = fromMaybe(?,mrv);
      if (!isValid(mrv))
      	 $display("mkSGListMMU::addrResp has gone off the reservation");
      respFifo.enq({rv,offs.first});
   endrule
   method Action page(SGListId id, Bit#(32) off, Bit#(40) addr);
      $display("page id=%d off=%h addr=%h", id, off, addr);
      pageTables[id].portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(off), datain:tagged Valid truncate(addr)});
   endmethod

   method Action addrReq(SGListId id, Bit#(40) off);
      ids.enq(id);
      offs.enq(truncate(off));
      pageTables[id].portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:truncate(off >> page_shift), datain:?});
   endmethod
   
   method ActionValue#(Bit#(40)) addrResp();
      respFifo.deq();
      return respFifo.first();
   endmethod
   
endmodule
