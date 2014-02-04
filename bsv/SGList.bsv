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

typedef 16 MaxNumSGLists;
typedef Bit#(TLog#(MaxNumSGLists)) SGListId;
typedef 12 SGListPageShift0;
typedef 16 SGListPageShift4;
typedef 20 SGListPageShift8;

interface SGListMMU#(numeric type addrWidth);
   method Action sglist(Bit#(32) pointer, Bit#(DmaOffsetSize) offset, Bit#(32) len);
   interface Vector#(2,Server#(Tuple2#(SGListId,Bit#(DmaOffsetSize)),Bit#(addrWidth))) addr;
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

module mkSGListMMU(SGListMMU#(addrWidth))
   
   provisos(Log#(MaxNumSGLists, listIdxSize),
	    Add#(listIdxSize,8, entryIdxSize),
	    Add#(c__, addrWidth, DmaOffsetSize));

   BRAM2Port#(Bit#(entryIdxSize), Page) pageTable <- mkBRAM2Server(defaultValue);
   Vector#(MaxNumSGLists, Reg#(Tuple3#(Bit#(40),Bit#(40),Bit#(40)))) regions <- replicateM(mkReg(unpack(0)));
   
   Vector#(2,FIFOF#(Offset))  offs <- replicateM(mkFIFOF);
   Reg#(Bit#(8))               idxReg  <- mkReg(0);
   
   let page_shift0 = fromInteger(valueOf(SGListPageShift0));
   let page_shift4 = fromInteger(valueOf(SGListPageShift4));
   let page_shift8 = fromInteger(valueOf(SGListPageShift8));
   
   let ord0 = 40'd1 << page_shift0;
   let ord4 = 40'd1 << page_shift4;
   let ord8 = 40'd1 << page_shift8;

   function BRAMServer#(Bit#(entryIdxSize), Page) portsel(int i);
      if(i==0)
	 return pageTable.portA;
      else
	 return pageTable.portB;
   endfunction

   Vector#(2,Server#(Tuple2#(SGListId,Bit#(DmaOffsetSize)),Bit#(addrWidth))) addrServers;
   for(int i = 0; i < 2; i=i+1)
      addrServers[i] = 
      (interface Server#(Tuple2#(SGListId,Bit#(DmaOffsetSize)),Bit#(addrWidth));
	  interface Put request;
	     method Action put(Tuple2#(SGListId,Bit#(DmaOffsetSize)) req);
		let ptr = tpl_1(req);
		let off = tpl_2(req);
		Offset o = ?;
		Bit#(8) p = ?;
		Bit#(40) barrier8 = tpl_3(regions[ptr-1]);
		Bit#(40) barrier4 = tpl_2(regions[ptr-1]);
		Bit#(40) barrier0 = tpl_1(regions[ptr-1]);
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
		   $display("mkSGListMMU.addr[%d].request.put: ERROR\n", i);
		end
		offs[i].enq(o);
		portsel(i).request.put(BRAMRequest{write:False, responseOnWrite:False, address:{ptr-1,p}, datain:?});
	     endmethod
	  endinterface
	  interface Get response;
	     method ActionValue#(Bit#(addrWidth)) get();
		Bit#(DmaOffsetSize) rv = 0;
		let page <- portsel(i).response.get;
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
   
   method Action sglist(Bit#(32) pointer, Bit#(DmaOffsetSize) offset, Bit#(32) len);
      $display("sglist(pointer=%d, offset=%h, len=%h", pointer, offset,len);
      if(len == 0) begin
	 idxReg <= 0;
      end
      else begin
	 if (idxReg+1 == 0) begin
	    $display("sglist: exceeded maximun length of sglist");
	 end 
	 else begin
	    idxReg <= idxReg+1;
	 end
	 Tuple3#(Bit#(40),Bit#(40),Bit#(40)) tt = regions[pointer-1];
	 Page page = ?;
	 // if we were willing to have a "reset" method, we could get rid of the multiplies
	 if (extend(len) == ord0) begin
	    regions[pointer-1] <= tuple3(extend(idxReg+1)*ord0, tpl_2(tt), tpl_3(tt));
	    page = tagged POrd0 truncate(offset>>page_shift0);
	 end
	 else if (extend(len) == ord4) begin
	    regions[pointer-1] <= tuple3(tpl_1(tt), extend(idxReg+1)*ord4,tpl_3(tt));
	    page = tagged POrd4 truncate(offset>>page_shift4);
	 end
	 else if (extend(len) == ord8) begin
	    regions[pointer-1] <= tuple3(tpl_1(tt), tpl_2(tt),extend(idxReg+1)*ord8);
	    page = tagged POrd8 truncate(offset>>page_shift8);
	 end
	 else begin
	    $display("mkSGListMMU::sglist unsupported length %h", len);
	 end
	 portsel(0).request.put(BRAMRequest{write:True, responseOnWrite:False, address:{truncate(pointer-1),idxReg}, datain:page});
      end
   endmethod   
   
   interface addr = addrServers;

endmodule
