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
import FIFOF::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import BRAMFIFO::*;
import BRAM::*;
import PortalMemory::*;

// In the future, NumDmaChannels will be defined somehwere in the xbsv compiler output
typedef 4 NumSGLists;
typedef Bit#(TLog#(NumSGLists)) SGListId;
typedef 32 SGListMaxLen;
typedef Bit#(TLog#(TMul#(NumSGLists, SGListMaxLen))) SGListIdx;

typedef struct {
   Bit#(32) address;
   Bit#(32) length;
   } SGListEntry deriving (Bits);

typedef struct {
   SGListIdx entry;
   Bit#(32) offset;
   } SGListPointer deriving (Bits);

interface SGListManager;
   method Action sglist(Bit#(32) off, Bit#(32) addr, Bit#(32) len);
   method Action loadCtx(SGListId id);
   method ActionValue#(Bit#(32)) nextAddr(Bit#(4) burstLen);
endinterface

module mkSGListManager(SGListManager);

   function m#(Reg#(SGListPointer)) foo(Integer x)
      provisos (IsModule#(m,__a));
      return mkReg(unpack(fromInteger(x)));
   endfunction

   BRAM1Port#(SGListIdx, SGListEntry)         listMem <- mkBRAM1Server(defaultValue);
   Vector#(NumSGLists, Reg#(SGListPointer))  listPtrs <- genWithM(foo);
   FIFOF#(SGListId)                          loadReqs <- mkFIFOF;
   
   method Action sglist(Bit#(32) off, Bit#(32) addr, Bit#(32) len);
      let entry = SGListEntry{address:addr, length:len};
      listMem.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(off), datain:entry});
   endmethod
   
   method Action loadCtx(SGListId id);
      listMem.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:listPtrs[id].entry, datain:?});
      loadReqs.enq(id);
   endmethod
  
   method ActionValue#(Bit#(32)) nextAddr(Bit#(4) burstLen);
      loadReqs.deq;
      let rv <- listMem.portA.response.get;
      let id = loadReqs.first;
      let lp = listPtrs[id];
      let new_offset = ((zeroExtend(burstLen)+1) << 3) + lp.offset;
      if(new_offset < rv.length)
	 listPtrs[id] <= SGListPointer{entry:lp.entry, offset:new_offset};
      else if (new_offset == rv.length)
	 listPtrs[id] <= SGListPointer{entry:lp.entry+1, offset:0};
      else if(new_offset > rv.length)
	 $display("burst crosses SG list boundry");
      else if(rv.length == 0)
	 $display("going off the end of SG list");
      return rv.address + lp.offset;
   endmethod
 
endmodule
