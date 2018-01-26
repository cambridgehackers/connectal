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
import FIFO::*;
import FIFOF::*;
import Vector::*;
import GetPut::*;
import BRAMFIFO::*;
import BRAM::*;
import ConnectalMemTypes::*;
import StmtFSM::*;
import ClientServer::*;
import ConnectalMemory::*;

typedef 32 MaxNumSGLists;
typedef Bit#(TLog#(MaxNumSGLists)) SGListId;
typedef 12 SGListPageShift0;
typedef 16 SGListPageShift4;
typedef 20 SGListPageShift8;
typedef Bit#(TLog#(MaxNumSGLists)) RegionsIdx;
typedef Tuple2#(SGListId,Bit#(MemOffsetSize)) ReqTup;

interface MMU#(numeric type addrWidth);
   method Action sglist(Bit#(32) pointer, Bit#(40) paddr, Bit#(32) len);
   method Action region(Bit#(32) ptr, Bit#(40) barr8, Bit#(8) off8, Bit#(40) barr4, Bit#(8) off4, Bit#(40) barr0, Bit#(8) off0);
   interface Vector#(2,Server#(ReqTup,Bit#(addrWidth))) addr;
endinterface

typedef union tagged{
   Bit#(SGListPageShift0) OOrd0;
   Bit#(SGListPageShift4) OOrd4;
   Bit#(SGListPageShift8) OOrd8;
} Offset deriving (Eq,Bits,FShow);

typedef union tagged{
   Bit#(TSub#(MemOffsetSize,SGListPageShift0)) POrd0;
   Bit#(TSub#(MemOffsetSize,SGListPageShift4)) POrd4;
   Bit#(TSub#(MemOffsetSize,SGListPageShift8)) POrd8;
} Page deriving (Eq,Bits,FShow);

typedef struct {
   Bit#(MemOffsetSize) barrier;
   Bit#(8) idxOffset;
   } Region deriving (Eq,Bits,FShow);

module mkMMU#(DmaIndication dmaIndication)(MMU#(addrWidth))
   
   provisos(Log#(MaxNumSGLists, listIdxSize),
	    Add#(listIdxSize,8, entryIdxSize),
	    Add#(c__, addrWidth, MemOffsetSize));

   BRAM_Configure bramConfig = defaultValue;
   bramConfig.latency        = 1;
   BRAM2Port#(Bit#(entryIdxSize),Page) pages <- mkBRAM2Server(bramConfig);
   BRAM2Port#(RegionsIdx, Region)       reg8 <- mkBRAM2Server(bramConfig);
   BRAM2Port#(RegionsIdx, Region)       reg4 <- mkBRAM2Server(bramConfig);
   BRAM2Port#(RegionsIdx, Region)       reg0 <- mkBRAM2Server(bramConfig);

   Vector#(2,FIFOF#(Bit#(entryIdxSize)))  rp <- replicateM(mkFIFOF);
   Vector#(2,FIFOF#(Offset))            offs <- replicateM(mkFIFOF);
   Vector#(2,FIFOF#(ReqTup))            reqs <- replicateM(mkFIFOF);
   Reg#(Bit#(8))                      idxReg <- mkReg(0);
   
   let page_shift0 = fromInteger(valueOf(SGListPageShift0));
   let page_shift4 = fromInteger(valueOf(SGListPageShift4));
   let page_shift8 = fromInteger(valueOf(SGListPageShift8));
   
   let ord0 = 40'd1 << page_shift0;
   let ord4 = 40'd1 << page_shift4;
   let ord8 = 40'd1 << page_shift8;

   function BRAMServer#(a,b) portsel(BRAM2Port#(a,b) x, Integer i);
      if(i==0)
	 return x.portA;
      else
	 return x.portB;
   endfunction

   FIFO#(Tuple4#(RegionsIdx,Region,Region,Region)) regionFifo <- mkFIFO();

   for(Integer i = 0; i < 2; i=i+1) begin
      rule req;
	 Region region8 <- portsel(reg8,i).response.get;
	 Region region4 <- portsel(reg4,i).response.get;
	 Region region0 <- portsel(reg0,i).response.get;

	 reqs[i].deq;
	 let ptr = tpl_1(reqs[i].first);
	 let off = tpl_2(reqs[i].first);
	 Offset o = tagged OOrd0 0;
	 Bit#(8) pbase = 0;
	 Bit#(8) idxOffset = 0;

	 Bit#(40) barrier8 = region8.barrier;
	 Bit#(40) barrier4 = region4.barrier;
	 Bit#(40) barrier0 = region0.barrier;

	 Bit#(3) pageSize = 0;
	 if (off < barrier8) begin
	    //$display("request: ptr=%h off=%h barrier8=%h", ptr, off, barrier8);
	    o = tagged OOrd8 truncate(off);
	    pbase = truncate(off>>page_shift8);
	    pageSize = 3;
	    idxOffset = region8.idxOffset;
	 end
	 else if (off < barrier4) begin
	    //$display("request: ptr=%h off=%h barrier4=%h", ptr, off, barrier4);
	    o = tagged OOrd4 truncate(off);
	    pbase = truncate(off>>page_shift4);
	    pageSize = 2;
	    idxOffset = region4.idxOffset;
	 end
	 else if (off < barrier0) begin
	    //$display("request: ptr=%h off=%h barrier0=%h", ptr, off, barrier0);
	    o = tagged OOrd0 truncate(off);
	    pbase = truncate(off>>page_shift0);
	    pageSize = 1;
	    idxOffset = region0.idxOffset;
	 end
	 else begin
	    pageSize = 0;
	    //dmaIndication.badAddrTrans(extend(ptr), extend(off), barrier0);
	 end
	 offs[i].enq(o);
	 Bit#(8) p = pbase + idxOffset;
	 if (pageSize == 3) begin
	    //$display("request: ptr=%h off=%h barrier8=%h", ptr, off, barrier8);
	 end
	 else if (pageSize == 2) begin
	 end
	 else if (pageSize == 1) begin
	 end
	 else if (pageSize == 0) begin
	    //FIXME offset
	    //$display("mkMMU.addr[%d].request.put: ERROR   ptr=%h off=%h\n", i, ptr, off);
	    dmaIndication.badAddrTrans(extend(ptr), -1, 0);
	 end
	 let address = {ptr-1,p};
	 //$display("pages[%d].read %h", i, rp[i].first());
	 portsel(pages, i).request.put(BRAMRequest{write:False, responseOnWrite:False, address:address, datain:?});
      endrule
   end

   Vector#(2,Server#(ReqTup,Bit#(addrWidth))) addrServers;
   for(Integer i = 0; i < 2; i=i+1)
      addrServers[i] =
      (interface Server#(ReqTup,Bit#(addrWidth));
	  interface Put request;
	     method Action put(ReqTup req);
	     	 match { .ptr, .off } = req;
	 	 portsel(reg8, i).request.put(BRAMRequest{write:False, responseOnWrite:False, address:truncate(ptr-1), datain:?});
	 	 portsel(reg4, i).request.put(BRAMRequest{write:False, responseOnWrite:False, address:truncate(ptr-1), datain:?});
	 	 portsel(reg0, i).request.put(BRAMRequest{write:False, responseOnWrite:False, address:truncate(ptr-1), datain:?});
	 	 reqs[i].enq(req);
	     endmethod
	  endinterface
	  interface Get response;
	     method ActionValue#(Bit#(addrWidth)) get();
	     	    let page <- portsel(pages, i).response.get;
    	      	    let offset <- toGet(offs[i]).get();
	  	    //$display("pages[%d].response page=%h offset=%h", i, page, offset);
	 	    Bit#(MemOffsetSize) rv = 0;
	            case (offset) matches
	            tagged OOrd0 .o:
        	       begin
        		  case (page) matches
        		     tagged POrd4 .p:
        			$display("OOrd0 vs POrd4");
        		     tagged POrd8 .p:
        			$display("OOrd0 vs POrd8");
        		  endcase
        		  rv = {page.POrd0,o};
        	       end
        	    tagged OOrd4 .o:
        	       begin
        		  case (page) matches
        		     tagged POrd0 .p:
        			$display("OOrd4 vs POrd0");
        		     tagged POrd8 .p:
        			$display("OOrd4 vs POrd8");
        		  endcase
        		  rv = {page.POrd4,o};
        	       end
        	    tagged OOrd8 .o:
        	       begin
        		  case (page) matches
        		     tagged POrd0 .p:
        			$display("OOrd8 vs POrd0");
        		     tagged POrd4 .p:
        			$display("OOrd8 vs POrd4");
        		  endcase
        		  rv = {page.POrd8,o};
        	       end
        	endcase
		return truncate(rv);
	     endmethod
	  endinterface
       endinterface);

   FIFO#(Tuple2#(SGListId,Bit#(40))) configRespFifo <- mkFIFO;
   rule sendConfigResp;
      match { .ptr, .barr0 } <- toGet(configRespFifo).get();
      dmaIndication.configResp(extend(ptr), barr0);
   endrule

   FIFO#(Tuple3#(SGListId,Bit#(40),Bit#(32))) sglistFifo <- mkFIFO();
   rule sglistRule;
      match { .ptr, .paddr, .len } <- toGet(sglistFifo).get();

      // $display("sglist(ptr=%d, paddr=%h, len=%h", ptr, paddr,len);
      if (idxReg+1 == 0) begin
	 $display("sglist: exceeded maximun length of sglist");
	 dmaIndication.badNumberEntries(extend(ptr),len, extend(idxReg));
      end
      else begin
	 Page page = tagged POrd0 0;
	 if (len == 0) begin
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
	    if (extend(len) > ord8) begin
	       $display("mkMMU::sglist unsupported length %h", len);
	       dmaIndication.badPageSize(extend(ptr), len);
	    end
	 end
	 configRespFifo.enq(tuple2(truncate(ptr), 40'haaaaaaaa));
	 portsel(pages, 0).request.put(BRAMRequest{write:True, responseOnWrite:False, address:{truncate(ptr-1),idxReg}, datain:page});
      end
   endrule

   rule regionRule;
      match { .ptr, .region8, .region4, .region0 } <- toGet(regionFifo).get();
      let idx = ptr-1;
      portsel(reg8, 0).request.put(BRAMRequest{write:True, responseOnWrite:False, address: idx, datain: region8});
      portsel(reg4, 0).request.put(BRAMRequest{write:True, responseOnWrite:False, address: idx, datain: region4});
      portsel(reg0, 0).request.put(BRAMRequest{write:True, responseOnWrite:False, address: idx, datain: region0});
      //$display("region ptr=%d off8=%h off4=%h off0=%h", ptr, off8, off4, off0);
      configRespFifo.enq(tuple2(ptr, region0.barrier));
   endrule

   // FIXME: split this into three methods?
   method Action region(Bit#(32) ptr, Bit#(40) barr8, Bit#(8) off8, Bit#(40) barr4, Bit#(8) off4, Bit#(40) barr0, Bit#(8) off0);
      Region region8 = Region { barrier: barr8, idxOffset: off8 };
      Region region4 = Region { barrier: barr4, idxOffset: off4 };
      Region region0 = Region { barrier: barr0, idxOffset: off0 };
      regionFifo.enq(tuple4(truncate(ptr),region8,region4,region0));
   endmethod

   method Action sglist(Bit#(32) ptr, Bit#(40) paddr, Bit#(32) len);
      sglistFifo.enq(tuple3(truncate(ptr), paddr, len));
   endmethod

   interface addr = addrServers;

endmodule

interface SglAddrServer#(numeric type addrWidth, numeric type numServers);
   interface Vector#(numServers,Server#(ReqTup,Bit#(addrWidth))) servers;
endinterface

module mkSglAddrServer#(Server#(ReqTup,Bit#(addrWidth)) server) (SglAddrServer#(addrWidth,numServers));
   
   FIFOF#(Bit#(TAdd#(1,TLog#(numServers)))) tokFifo <- mkSizedFIFOF(3);
   Vector#(numServers, Server#(ReqTup,Bit#(addrWidth))) addrServers;
   Reg#(Bit#(TLog#(numServers))) arb <- mkReg(0);

   // this is a very crude arbiter.  something more sophisticated may be required (mdk)
   rule inc_arb;
      arb <= arb+1;
   endrule
   
   for(Integer i = 0; i < valueOf(numServers); i=i+1)
      addrServers[i] = 
      (interface Server#(ReqTup,Bit#(addrWidth));
	  interface Put request;
	     method Action put(ReqTup req) if (arb == fromInteger(i));
		tokFifo.enq(fromInteger(i));
		server.request.put(req);
	     endmethod
	  endinterface
	  interface Get response;
	     method ActionValue#(Bit#(addrWidth)) get() if (tokFifo.first == fromInteger(i));
		tokFifo.deq;
		let rv <- server.response.get;
		return rv;
	     endmethod
	  endinterface
       endinterface);

   interface servers = addrServers;

endmodule
