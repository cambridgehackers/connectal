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
import PortalMemory::*;

typedef 32 MaxNumSGLists;
typedef Bit#(TLog#(MaxNumSGLists)) SGListId;
typedef 12 SGListPageShift0;
typedef 16 SGListPageShift4;
typedef 20 SGListPageShift8;
typedef Bit#(TLog#(MaxNumSGLists)) RegionsIdx;
typedef Tuple2#(SGListId,Bit#(DmaOffsetSize)) ReqTup;

interface SGListMMU#(numeric type addrWidth);
   method Action sglist(Bit#(32) pointer, Bit#(40) paddr, Bit#(32) len);
   method Action region(Bit#(32) pointer, Bit#(40) off8, Bit#(40) off4, Bit#(40) off0);
   interface Vector#(2,Server#(ReqTup,Bit#(addrWidth))) addr;
endinterface

typedef union tagged{
   Bit#(SGListPageShift0) OOrd0;
   Bit#(SGListPageShift4) OOrd4;
   Bit#(SGListPageShift8) OOrd8;
} Offset deriving (Eq,Bits);

typedef union tagged{
   Bit#(TSub#(DmaOffsetSize,SGListPageShift0)) POrd0;
   Bit#(TSub#(DmaOffsetSize,SGListPageShift4)) POrd4;
   Bit#(TSub#(DmaOffsetSize,SGListPageShift8)) POrd8;
} Page deriving (Eq,Bits);

module mkSGListMMU#(DmaIndication dmaIndication)(SGListMMU#(addrWidth))
   
   provisos(Log#(MaxNumSGLists, listIdxSize),
	    Add#(listIdxSize,8, entryIdxSize),
	    Add#(c__, addrWidth, DmaOffsetSize));

   BRAM2Port#(Bit#(entryIdxSize), Page)       pages <- mkBRAM2Server(defaultValue);
   BRAM2Port#(RegionsIdx, Bit#(DmaOffsetSize)) reg8 <- mkBRAM2Server(defaultValue);
   BRAM2Port#(RegionsIdx, Bit#(DmaOffsetSize)) reg4 <- mkBRAM2Server(defaultValue);
   BRAM2Port#(RegionsIdx, Bit#(DmaOffsetSize)) reg0 <- mkBRAM2Server(defaultValue);

   Vector#(2,FIFOF#(Offset))                   offs <- replicateM(mkFIFOF);
   Vector#(2,FIFOF#(ReqTup))                   reqs <- replicateM(mkFIFOF);
   Reg#(Bit#(8))                             idxReg <- mkReg(0);
   
   let page_shift0 = fromInteger(valueOf(SGListPageShift0));
   let page_shift4 = fromInteger(valueOf(SGListPageShift4));
   let page_shift8 = fromInteger(valueOf(SGListPageShift8));
   
   let ord0 = 40'd1 << page_shift0;
   let ord4 = 40'd1 << page_shift4;
   let ord8 = 40'd1 << page_shift8;

   function BRAMServer#(a,b) portsel(BRAM2Port#(a,b) x, int i);
      if(i==0)
	 return x.portA;
      else
	 return x.portB;
   endfunction

   
   for(int i = 0; i < 2; i=i+1)
      rule req;
	 reqs[i].deq;
	 let ptr = tpl_1(reqs[i].first);
	 let off = tpl_2(reqs[i].first);
	 Offset o = tagged OOrd0 0;
	 Bit#(8) p = 0;
	 Bit#(40) barrier8 <- portsel(reg8,i).response.get;
	 Bit#(40) barrier4 <- portsel(reg4,i).response.get;
	 Bit#(40) barrier0 <- portsel(reg0,i).response.get;
	 if (off < barrier8) begin
	    //$display("request: ptr=%h off=%h barrier8=%h", ptr, off, barrier8);
	    o = tagged OOrd8 truncate(off);
	    p = truncate(off>>page_shift8);
	 end 
	 else if (off < barrier4) begin
	    //$display("request: ptr=%h off=%h barrier4=%h", ptr, off, barrier4);
	    o = tagged OOrd4 truncate(off);
	    p = truncate(off>>page_shift4);
	 end
	 else if (off < barrier0) begin
	    //$display("request: ptr=%h off=%h barrier0=%h", ptr, off, barrier0);
	    o = tagged OOrd0 truncate(off);
	    p = truncate(off>>page_shift0);
	 end 
	 else begin
	    $display("mkSGListMMU.addr[%d].request.put: ERROR   ptr=%h off=%h\n", i, ptr, off);
	    dmaIndication.badAddrTrans(extend(ptr), truncate(off));
	 end
	 offs[i].enq(o);
	 portsel(pages, i).request.put(BRAMRequest{write:False, responseOnWrite:False, address:{ptr-1,p}, datain:?});
      endrule

   Vector#(2,Server#(ReqTup,Bit#(addrWidth))) addrServers;
   for(int i = 0; i < 2; i=i+1)
      addrServers[i] = 
      (interface Server#(ReqTup,Bit#(addrWidth));
	  interface Put request;
	     method Action put(ReqTup req);
		let ptr = tpl_1(req);
		let off = tpl_2(req);
		portsel(reg8, i).request.put(BRAMRequest{write:False, responseOnWrite:False, address:truncate(ptr-1), datain:?});
		portsel(reg4, i).request.put(BRAMRequest{write:False, responseOnWrite:False, address:truncate(ptr-1), datain:?});
		portsel(reg0, i).request.put(BRAMRequest{write:False, responseOnWrite:False, address:truncate(ptr-1), datain:?});
		reqs[i].enq(req);
	     endmethod
	  endinterface
	  interface Get response;
	     method ActionValue#(Bit#(addrWidth)) get();
		Bit#(DmaOffsetSize) rv = 0;
		let page <- portsel(pages, i).response.get;
		let offset = offs[i].first;
		case (offset) matches
		   tagged OOrd0 .o:
		      rv = {page.POrd0,o};
		   tagged OOrd4 .o:
		      rv = {page.POrd4,o};
		   tagged OOrd8 .o:
		      rv = {page.POrd8,o};
		endcase
		offs[i].deq;
		return truncate(rv);
	     endmethod
	  endinterface
       endinterface);


   method Action region(Bit#(32) ptr, Bit#(40) off8, Bit#(40) off4, Bit#(40) off0);
      portsel(reg8, 0).request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(ptr-1), datain:off8});
      portsel(reg4, 0).request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(ptr-1), datain:off4});
      portsel(reg0, 0).request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(ptr-1), datain:off0});
      dmaIndication.configResp(ptr);
   endmethod
	       
   
   method Action sglist(Bit#(32) ptr, Bit#(40) paddr, Bit#(32) len);
      $display("sglist(ptr=%d, paddr=%h, len=%h", ptr, paddr,len);
      if (idxReg+1 == 0) begin
	 $display("sglist: exceeded maximun length of sglist");
	 dmaIndication.badPageSize(ptr,len);
      end
      else begin
	 Page page = tagged POrd0 0;
	 if(len == 0) begin
	    idxReg <= 0;
	 end 
	 else begin
	    idxReg <= idxReg+1;
	    if (extend(len) == ord0) begin
	       page = tagged POrd0 truncate(paddr>>page_shift0);
	    end
	    else if (extend(len) == ord4) begin
	       page = tagged POrd4 truncate(paddr>>page_shift4);
	    end
	    else if (extend(len) == ord8) begin
	       page = tagged POrd8 truncate(paddr>>page_shift8);
	    end
	    else begin
	       $display("mkSGListMMU::sglist unsupported length %h", len);
	       dmaIndication.badPageSize(ptr, len);
	    end
	 end
	 portsel(pages, 0).request.put(BRAMRequest{write:True, responseOnWrite:False, address:{truncate(ptr-1),idxReg}, datain:page});
	 dmaIndication.configResp(ptr);
      end
   endmethod   
   
   interface addr = addrServers;

endmodule
